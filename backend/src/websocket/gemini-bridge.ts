import { z } from 'zod';
import { getVertexClient } from '../services/gemini.service';
import * as firebaseService from '../services/firebase.service';
import * as fcmService from '../services/fcm.service';
import { logger } from '../utils/logger';

type BridgeSession = {
  sendMedia: (chunk: any) => Promise<void>;
  close: () => void;
  mode: 'GENAI_LIVE' | 'VERTEX_CHAT' | 'GEMINI_API';
};

type GeminiSessionMode = BridgeSession['mode'];

const geminiSessions = new Map<string, BridgeSession>();
const aiFailureRecorded = new Set<string>();

// Buffer for accumulating streaming JSON chunks per incident
const geminiTextBuffers = new Map<string, string>();
const MAX_BUFFER_SIZE = 4000;

const analysisSchema = z.object({
  hazards: z.array(
    z.object({
      type: z.enum(['FIRE', 'SMOKE', 'MEDICAL', 'SECURITY_THREAT', 'STRUCTURAL_DAMAGE', 'FLOOD', 'UNKNOWN']),
      confidence: z.number().min(0).max(1),
      description: z.string(),
    }),
  ),
  severity: z.enum(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']),
  aiSummary: z.string(),
  translatedTranscript: z.string(),
  originalTranscript: z.string(),
  detectedLanguage: z.string(),
  guestCalm: z.string(),
});

const productionPrompt = `
You are ResQLink AI Dispatcher — an autonomous, real-time emergency analysis agent
embedded in a hotel safety system.

INPUTS: You receive live video frames and audio from a distressed hotel guest's smartphone.

YOUR TASKS:
1. HAZARD DETECTION: Examine each video frame for: fire, smoke, weapons, 
   structural collapse, flooding, injured persons, or other threats.
2. SEVERITY ASSESSMENT: Rate the overall situation as LOW / MEDIUM / HIGH / CRITICAL.
3. TRANSCRIPTION: Listen to the audio and transcribe exactly what the guest is saying.
4. TRANSLATION: Translate the guest speech to English if it is in another language.
   The guest's declared language is provided in the session context.
5. CALM MESSAGE: Generate a short, calming, empathetic message in the guest's language.
   Keep it under 20 words. Examples: "मदद रास्ते में है, शांत रहें" (Hindi) or
   "Help is on the way. Stay calm and move low if there is smoke."
6. RESPONDER SUMMARY: Write one crisp sentence in English for the security dashboard,
   suitable for a responder to act on immediately.

OUTPUT FORMAT: Always respond with ONLY valid JSON, no markdown fences:
{
  "hazards": [
    {
      "type": "FIRE|SMOKE|MEDICAL|SECURITY_THREAT|STRUCTURAL_DAMAGE|FLOOD|UNKNOWN",
      "confidence": <float 0.0-1.0>,
      "description": "<specific observation>"
    }
  ],
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "aiSummary": "<one sentence for responders in English>",
  "translatedTranscript": "<English translation of guest speech>",
  "originalTranscript": "<guest speech verbatim>",
  "detectedLanguage": "<ISO 639-1>",
  "guestCalm": "<calming message in guest's language, max 20 words>"
}

CRITICAL RULES:
- Output JSON every time you have processed a new set of frames/audio.
- Never output partial JSON.
- If no hazard is visible, still output the structure with hazards: [] and severity: LOW.
- Never engage in conversation — only output the JSON structure.
- Prioritize life-safety assessment over everything else.
`.trim();

let guestSender: ((incidentId: string, message: unknown) => void) | null = null;

export function registerGuestSender(sender: (incidentId: string, message: unknown) => void) {
  guestSender = sender;
}

export function buildSystemPrompt(lang: string): string {
  return `${productionPrompt}\n\nSESSION CONTEXT:\n- Guest declared language (ISO 639-1): ${lang}`;
}

export function resolveGeminiSessionMode(
  env: Record<string, string | undefined> = process.env,
): GeminiSessionMode | null {
  const model = (env.GEMINI_MODEL || '').trim();
  const apiKey = (env.GEMINI_API_KEY || '').trim();
  const project = (env.GOOGLE_CLOUD_PROJECT || '').trim();
  const location = (env.GOOGLE_CLOUD_LOCATION || env.VERTEX_AI_LOCATION || '').trim();

  if (apiKey.length > 0 && model.length > 0) {
    return 'GEMINI_API';
  }

  if (project.length > 0 && location.length > 0 && model.length > 0) {
    return 'VERTEX_CHAT';
  }

  return null;
}

function buildAiUnavailableSummary(error: unknown): string {
  const message = String(error ?? '');
  if (message.includes('BILLING_DISABLED')) {
    return 'AI analysis unavailable: Vertex AI billing is disabled for this project.';
  }
  if (message.includes('PERMISSION_DENIED')) {
    return 'AI analysis unavailable: backend AI access is not permitted.';
  }
  return 'AI analysis unavailable: backend Gemini service is currently failing.';
}

async function recordAiUnavailable(incidentId: string, error: unknown) {
  if (aiFailureRecorded.has(incidentId)) {
    return;
  }

  aiFailureRecorded.add(incidentId);
  const summary = buildAiUnavailableSummary(error);

  try {
    await firebaseService.updateIncidentAiState(
      incidentId,
      'UNAVAILABLE',
      summary,
      summary,
    );
  } catch (updateError) {
    logger.warn('Failed to persist AI unavailable status', {
      incidentId,
      error: String(updateError),
    });
  }
}

function serializeError(error: unknown) {
  if (error instanceof Error) {
    const anyErr = error as any;
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
      code: anyErr?.code,
      status: anyErr?.status,
      statusCode: anyErr?.statusCode,
      details: anyErr?.details,
      cause: anyErr?.cause instanceof Error ? anyErr.cause.message : anyErr?.cause,
    };
  }

  if (typeof error === 'object' && error !== null) {
    try {
      return JSON.parse(JSON.stringify(error));
    } catch (_) {
      return { message: String(error) };
    }
  }

  return { message: String(error) };
}

function shutdownGeminiSession(incidentId: string) {
  const session = geminiSessions.get(incidentId);
  if (!session) {
    return;
  }
  try {
    session.close();
  } catch (error) {
    logger.warn('Gemini session close failed after send error', {
      incidentId,
      error: serializeError(error),
    });
  } finally {
    geminiSessions.delete(incidentId);
  }
}

function extractTextFromResponse(response: any): string {
  if (!response) {
    return '';
  }

  if (typeof response.text === 'string' && response.text.trim().length > 0) {
    return response.text;
  }

  if (typeof response.text === 'function') {
    const textFromFn = response.text();
    if (typeof textFromFn === 'string' && textFromFn.trim().length > 0) {
      return textFromFn;
    }
  }

  const fromLive = response?.serverContent?.modelTurn?.parts;
  if (Array.isArray(fromLive)) {
    const joined = fromLive
      .map((part: any) => (typeof part?.text === 'string' ? part.text : ''))
      .join('\n')
      .trim();
    if (joined.length > 0) {
      return joined;
    }
  }

  const fromVertex = response?.candidates?.[0]?.content?.parts;
  if (Array.isArray(fromVertex)) {
    const joined = fromVertex
      .map((part: any) => (typeof part?.text === 'string' ? part.text : ''))
      .join('\n')
      .trim();
    if (joined.length > 0) {
      return joined;
    }
  }

  return '';
}

function coerceJsonText(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed;
  }

  // Strip markdown code fences
  const withoutFences = trimmed
    .replace(/```json\s*/g, '')
    .replace(/```\s*/g, '')
    .trim();

  if (withoutFences.startsWith('{') && withoutFences.endsWith('}')) {
    return withoutFences;
  }

  const start = withoutFences.indexOf('{');
  const end = withoutFences.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return withoutFences.slice(start, end + 1);
  }

  return withoutFences;
}

/**
 * Try to parse JSON from potentially incomplete streaming text.
 * Returns parsed JSON if successful, null if the JSON is incomplete.
 * Throws if the JSON is malformed and cannot be recovered.
 */
function tryParseStreamingJson(text: string): { parsed: any } | { error: string } | null {
  const cleaned = coerceJsonText(text);
  if (!cleaned || cleaned.length === 0) {
    return null;
  }

  // Must start with { to be valid JSON object
  if (!cleaned.startsWith('{')) {
    return null;
  }

  try {
    const parsed = JSON.parse(cleaned);
    return { parsed };
  } catch (e) {
    // If it's a syntax error, the JSON might be incomplete
    // Check if we're missing closing braces/brackets
    const openBraces = (cleaned.match(/{/g) || []).length;
    const closeBraces = (cleaned.match(/}/g) || []).length;
    const openBrackets = (cleaned.match(/\[/g) || []).length;
    const closeBrackets = (cleaned.match(/]/g) || []).length;

    const missingBraces = openBraces - closeBraces;
    const missingBrackets = openBrackets - closeBrackets;

    // If we're missing closers, it's likely incomplete - don't error yet
    if (missingBraces > 0 || missingBrackets > 0) {
      return null; // Incomplete, keep accumulating
    }

    // Balanced but invalid JSON = actual error
    return { error: `JSON parse error: ${String(e)}` };
  }
}

async function createGenAiLiveSession(incidentId: string, guestLanguage: string): Promise<BridgeSession> {
  const apiKey = (process.env.GEMINI_API_KEY || '').trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  logger.info('Initializing Gemini with API Key', {
    incidentId,
    model: process.env.GEMINI_MODEL,
    hasApiKey: true,
  });

  // Use @google/genai with API key (simpler than Vertex AI)
  const { GoogleGenAI } = await import('@google/genai');
  
  const ai = new GoogleGenAI({
    apiKey,
  });

  // Start a chat session
  let chatSession: any = null;
  const systemPrompt = buildSystemPrompt(guestLanguage);

  return {
    mode: 'GEMINI_API',
    close: () => {
      chatSession = null;
    },
    sendMedia: async (chunk: any) => {
      if (!chatSession) {
        // Initialize chat on first message
        chatSession = await ai.chats.create({
          model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
        });
        // Send system instruction as first message
        await chatSession.sendMessage([
          { text: systemPrompt },
          { text: 'Acknowledged. I will analyze all media and respond with JSON only.' }
        ]);
      }

      const parts: any[] = [];
      if (chunk.video) {
        parts.push({
          inlineData: { data: chunk.video, mimeType: chunk.mimeTypeVideo },
        });
      }
      if (chunk.audio) {
        parts.push({
          inlineData: { data: chunk.audio, mimeType: chunk.mimeTypeAudio },
        });
      }
      if (parts.length === 0) {
        return;
      }

      logger.debug('Sending media to Gemini', {
        incidentId,
        hasVideo: !!chunk.video,
        hasAudio: !!chunk.audio,
      });

      const response = await chatSession.sendMessage(parts);
      await parseGeminiResponse(response, incidentId);
    },
  };
}

async function createVertexChatFallbackSession(incidentId: string, guestLanguage: string): Promise<BridgeSession> {
  const client = getVertexClient();
  const model = client.getGenerativeModel({
    model: process.env.GEMINI_MODEL,
    systemInstruction: buildSystemPrompt(guestLanguage),
  });

  const session = await model.startChat({ stream: true });
  if (typeof session.onMessage === 'function') {
    session.onMessage((response: any) => {
      void parseGeminiResponse(response, incidentId);
    });
  }

  return {
    mode: 'VERTEX_CHAT',
    close: () => {
      if (typeof session.close === 'function') {
        session.close();
      }
    },
    sendMedia: async (chunk: any) => {
      const parts = [];
      if (chunk.video) {
        parts.push({
          inlineData: { data: chunk.video, mimeType: chunk.mimeTypeVideo },
        });
      }
      if (chunk.audio) {
        parts.push({
          inlineData: { data: chunk.audio, mimeType: chunk.mimeTypeAudio },
        });
      }
      if (parts.length === 0) {
        return;
      }

      const response = await session.sendMessage({ role: 'user', parts });
      await parseGeminiResponse(response, incidentId);
    },
  };
}

export async function openGeminiSession(incidentId: string, guestLanguage: string) {
  closeGeminiSession(incidentId);

  try {
    const mode = resolveGeminiSessionMode();
    let session: BridgeSession;

    if (mode === 'GEMINI_API') {
      session = await createGenAiLiveSession(incidentId, guestLanguage);
    } else if (mode === 'VERTEX_CHAT') {
      session = await createVertexChatFallbackSession(incidentId, guestLanguage);
    } else {
      throw new Error(
        'Gemini is not configured. Set GEMINI_API_KEY + GEMINI_MODEL, or GOOGLE_CLOUD_PROJECT + GOOGLE_CLOUD_LOCATION/VERTEX_AI_LOCATION + GEMINI_MODEL.',
      );
    }

    geminiSessions.set(incidentId, session);
    logger.info('Gemini session opened', { incidentId, mode: session.mode });
    return session;
  } catch (error) {
    logger.error('Gemini session failed', {
      incidentId,
      error: String(error),
    });
    await recordAiUnavailable(incidentId, error);
    throw error;
  }
}

export function closeGeminiSession(incidentId: string) {
  const session = geminiSessions.get(incidentId);
  if (!session) {
    aiFailureRecorded.delete(incidentId);
    return;
  }
  try {
    session.close();
  } catch (error) {
    logger.warn('Gemini session close failed', { incidentId, error });
  } finally {
    geminiSessions.delete(incidentId);
    aiFailureRecorded.delete(incidentId);
  }
}

export async function sendMediaToGemini(incidentId: string, chunk: any) {
  if (aiFailureRecorded.has(incidentId)) {
    return;
  }
  const session = geminiSessions.get(incidentId);
  if (!session) {
    logger.warn('Gemini media send skipped - no session', { incidentId, hasSession: false });
    return;
  }
  try {
    logger.debug('Sending media to Gemini', {
      incidentId,
      hasVideo: !!chunk.video,
      hasAudio: !!chunk.audio,
      chunkIndex: chunk.chunkIndex,
    });
    await session.sendMedia(chunk);
    logger.debug('Media sent to Gemini successfully', { incidentId, chunkIndex: chunk.chunkIndex });
  } catch (error) {
    const err = serializeError(error);
    logger.error('Gemini media send failed', {
      incidentId,
      chunkIndex: chunk?.chunkIndex,
      hasVideo: !!chunk?.video,
      hasAudio: !!chunk?.audio,
      error: err,
    });
    await recordAiUnavailable(incidentId, err.message || String(error));
    shutdownGeminiSession(incidentId);
  }
}

export async function parseGeminiResponse(response: any, incidentId: string) {
  try {
    const rawText = extractTextFromResponse(response);
    logger.info('Gemini response received', {
      incidentId,
      hasText: !!rawText,
      textLength: rawText?.length ?? 0,
      rawTextPreview: rawText?.substring(0, 200),
    });
    
    if (!rawText) {
      logger.warn('Gemini response has no text content', { incidentId, responseKeys: Object.keys(response || {}) });
      return;
    }

    // Get or create buffer for this incident
    const existingBuffer = geminiTextBuffers.get(incidentId) || '';
    const newBuffer = existingBuffer + rawText;

    // Check buffer size limit
    if (newBuffer.length > MAX_BUFFER_SIZE) {
      logger.warn('Gemini buffer exceeded max size, clearing', {
        incidentId,
        bufferSize: newBuffer.length,
      });
      geminiTextBuffers.delete(incidentId);
      return;
    }

    // Store updated buffer
    geminiTextBuffers.set(incidentId, newBuffer);
    logger.info('Gemini buffer updated', { incidentId, bufferSize: newBuffer.length });

    // Try to parse accumulated JSON
    const parseResult = tryParseStreamingJson(newBuffer);

    if (!parseResult) {
      // JSON is incomplete, keep accumulating
      logger.debug('Gemini JSON incomplete, accumulating', {
        incidentId,
        bufferSize: newBuffer.length,
      });
      return;
    }

    if ('error' in parseResult) {
      logger.error('Gemini JSON parse error', {
        incidentId,
        error: parseResult.error,
        bufferPreview: newBuffer.substring(0, 500),
      });
      geminiTextBuffers.delete(incidentId);
      return;
    }

    // Successfully parsed raw JSON - log it for debugging
    logger.info('Gemini raw JSON parsed', {
      incidentId,
      jsonPreview: JSON.stringify(parseResult.parsed, null, 2).substring(0, 800),
    });

    // Validate against schema
    let analysis;
    try {
      analysis = analysisSchema.parse(parseResult.parsed);
    } catch (schemaError) {
      logger.error('Gemini schema validation failed', {
        incidentId,
        parsedData: parseResult.parsed,
        schemaErrors: schemaError instanceof Error ? schemaError.message : String(schemaError),
      });
      geminiTextBuffers.delete(incidentId);
      return;
    }

    aiFailureRecorded.delete(incidentId);

    // Clear buffer on successful parse
    geminiTextBuffers.delete(incidentId);

    logger.info('Gemini parse success', {
      incidentId,
      severity: analysis.severity,
      hazards: analysis.hazards.length,
    });

    await firebaseService.updateIncidentAnalysis(incidentId, {
      ...analysis,
      aiStatus: 'AVAILABLE',
      guestStatusMessage: analysis.guestCalm,
    });
    await firebaseService.updateLiveCard(incidentId, analysis);

    if (guestSender) {
      guestSender(incidentId, {
        type: 'AI_STATUS',
        payload: {
          incidentId,
          message: analysis.guestCalm,
          severity: analysis.severity,
          helpOnWay: true,
          hazards: analysis.hazards,
          aiSummary: analysis.aiSummary,
        },
      });
    }

    if (analysis.severity === 'CRITICAL') {
      await fcmService.sendCriticalAlert(incidentId, analysis.aiSummary);
    }
  } catch (error) {
    logger.error('Gemini parse error', { incidentId, error });
    await recordAiUnavailable(incidentId, error);
  }
}

export function hasGeminiSession(incidentId: string) {
  return geminiSessions.has(incidentId);
}
