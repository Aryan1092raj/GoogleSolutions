import { z } from 'zod';
import { getVertexClient } from '../services/gemini.service';
import * as firebaseService from '../services/firebase.service';
import * as fcmService from '../services/fcm.service';
import { logger } from '../utils/logger';

type BridgeSession = {
  sendMedia: (chunk: any) => Promise<void>;
  close: () => void;
  mode: 'GENAI_LIVE' | 'VERTEX_CHAT';
};

const geminiSessions = new Map<string, BridgeSession>();

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

  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.slice(start, end + 1);
  }

  return trimmed;
}

async function createGenAiLiveSession(incidentId: string, guestLanguage: string): Promise<BridgeSession> {
  let genAiModule: any;
  try {
    genAiModule = await import('@google/genai');
  } catch (error) {
    throw new Error(`@google/genai not available: ${String(error)}`);
  }

  const GoogleGenAI = genAiModule.GoogleGenAI;
  if (!GoogleGenAI) {
    throw new Error('GoogleGenAI export missing');
  }

  const ai = new GoogleGenAI({
    vertexai: true,
    project: process.env.GOOGLE_CLOUD_PROJECT,
    location: process.env.VERTEX_AI_LOCATION,
  });

  const liveSession = await ai.live.connect({
    model: process.env.GEMINI_MODEL || 'gemini-2.0-flash-live-001',
    config: {
      responseModalities: ['TEXT'],
      systemInstruction: buildSystemPrompt(guestLanguage),
    },
    callbacks: {
      onmessage: (message: any) => {
        void parseGeminiResponse(message, incidentId);
      },
      onerror: (error: any) => {
        logger.error('Gemini Live callback error', { incidentId, error });
      },
      onclose: (event: any) => {
        logger.info('Gemini Live session closed', {
          incidentId,
          code: event?.code,
          reason: event?.reason,
        });
      },
    },
  });

  return {
    mode: 'GENAI_LIVE',
    close: () => {
      liveSession.close();
    },
    sendMedia: async (chunk: any) => {
      if (chunk.video) {
        const videoBlob = new Blob([Buffer.from(chunk.video, 'base64')], {
          type: chunk.mimeTypeVideo,
        });
        liveSession.sendRealtimeInput({ media: videoBlob });
      }

      if (chunk.audio) {
        const audioBlob = new Blob([Buffer.from(chunk.audio, 'base64')], {
          type: chunk.mimeTypeAudio,
        });
        liveSession.sendRealtimeInput({ media: audioBlob });
      }
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
    const session = await createGenAiLiveSession(incidentId, guestLanguage);
    geminiSessions.set(incidentId, session);
    logger.info('Gemini session opened', { incidentId, mode: session.mode });
    return session;
  } catch (liveError) {
    logger.warn('Gemini Live session unavailable, using fallback', {
      incidentId,
      error: String(liveError),
    });
  }

  const fallback = await createVertexChatFallbackSession(incidentId, guestLanguage);
  geminiSessions.set(incidentId, fallback);
  logger.info('Gemini session opened', { incidentId, mode: fallback.mode });
  return fallback;
}

export function closeGeminiSession(incidentId: string) {
  const session = geminiSessions.get(incidentId);
  if (!session) {
    return;
  }
  try {
    session.close();
  } catch (error) {
    logger.warn('Gemini session close failed', { incidentId, error });
  } finally {
    geminiSessions.delete(incidentId);
  }
}

export async function sendMediaToGemini(incidentId: string, chunk: any) {
  const session = geminiSessions.get(incidentId);
  if (!session) {
    return;
  }
  await session.sendMedia(chunk);
}

export async function parseGeminiResponse(response: any, incidentId: string) {
  try {
    const rawText = extractTextFromResponse(response);
    if (!rawText) {
      return;
    }

    const analysis = analysisSchema.parse(JSON.parse(coerceJsonText(rawText)));

    await firebaseService.updateIncidentAnalysis(incidentId, analysis);
    await firebaseService.updateLiveCard(incidentId, analysis);

    if (guestSender) {
      guestSender(incidentId, {
        type: 'AI_STATUS',
        payload: {
          incidentId,
          message: analysis.guestCalm,
          severity: analysis.severity,
          helpOnWay: true,
        },
      });
    }

    if (analysis.severity === 'CRITICAL') {
      await fcmService.sendCriticalAlert(incidentId, analysis.aiSummary);
    }
  } catch (error) {
    logger.error('Gemini parse error', { incidentId, error });
  }
}

export function hasGeminiSession(incidentId: string) {
  return geminiSessions.has(incidentId);
}
