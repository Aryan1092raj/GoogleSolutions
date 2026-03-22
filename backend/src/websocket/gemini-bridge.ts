import { z } from 'zod'; 
import { getVertexClient } from '../services/gemini.service'; 
import * as firebaseService from '../services/firebase.service'; 
import * as fcmService from '../services/fcm.service'; 
import { logger } from '../utils/logger'; 
 
const geminiSessions = new Map(); 
 
const analysisSchema = z.object({ 
  hazards: z.array(z.object({ 
    type: z.enum(['FIRE', 'SMOKE', 'MEDICAL', 'SECURITY_THREAT', 'STRUCTURAL_DAMAGE', 'FLOOD', 'UNKNOWN']), 
    confidence: z.number().min(0).max(1), 
    description: z.string(), 
  })), 
  severity: z.enum(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']), 
  aiSummary: z.string(), 
  translatedTranscript: z.string(), 
  originalTranscript: z.string(), 
  detectedLanguage: z.string(), 
  guestCalm: z.string(), 
}); 
 
let guestSender = null; 
 
export function registerGuestSender(sender) { 
  guestSender = sender; 
} 
 
export function buildSystemPrompt(lang) { 
  return [ 
    'You are ResQLink AI Dispatcher - an autonomous, real-time emergency analysis agent', 
    'embedded in a hotel safety system.', 
    '', 
    'INPUTS: You receive live video frames and audio from a distressed hotel guest smartphone.', 
    '', 
    'YOUR TASKS:', 
    '1. HAZARD DETECTION: Examine each video frame for: fire, smoke, weapons, structural collapse, flooding, injured persons, or other threats.', 
    '2. SEVERITY ASSESSMENT: Rate the overall situation as LOW / MEDIUM / HIGH / CRITICAL.', 
    '3. TRANSCRIPTION: Listen to the audio and transcribe exactly what the guest is saying.', 
    '4. TRANSLATION: Translate the guest speech to English if it is in another language.', 
    '5. CALM MESSAGE: Generate a short, calming, empathetic message in the guest language. Keep it under 20 words.', 
    '6. RESPONDER SUMMARY: Write one crisp sentence in English for the security dashboard.', 
  ].join('\n') + '\nGuest primary language is: ' + lang; 
}
 
export async function openGeminiSession(incidentId, guestLanguage) { 
  const client = getVertexClient(); 
  const model = client.getGenerativeModel({ 
    model: process.env.GEMINI_MODEL, 
    systemInstruction: buildSystemPrompt(guestLanguage), 
  }); 
 
  const session = await model.startChat({ stream: true }); 
  geminiSessions.set(incidentId, session); 
 
  if (session.onMessage) { 
    session.onMessage(function (response) { 
      parseGeminiResponse(response, incidentId); 
    }); 
  } 
 
  return session; 
} 
 
export function closeGeminiSession(incidentId) { 
  const session = geminiSessions.get(incidentId); 
  if (session) { 
    if (session.close) { 
      session.close(); 
    } 
  } 
  geminiSessions.delete(incidentId); 
} 
 
export async function sendMediaToGemini(incidentId, chunk) { 
  const session = geminiSessions.get(incidentId); 
  if (!session) { 
    return; 
  } 
 
  const parts = []; 
  if (chunk.video) { 
    parts.push({ inlineData: { data: chunk.video, mimeType: chunk.mimeTypeVideo } }); 
  } 
  if (chunk.audio) { 
    parts.push({ inlineData: { data: chunk.audio, mimeType: chunk.mimeTypeAudio } }); 
  } 
 
  if (parts.length === 0) { 
    return; 
  } 
 
  await session.sendMessage({ role: 'user', parts: parts }); 
}
 
export async function parseGeminiResponse(response, incidentId) { 
  try { 
    if (!response) { 
      return; 
    } 
 
    let text = ''; 
    if (response.candidates) { 
      if (response.candidates[0]) { 
        if (response.candidates[0].content) { 
          if (response.candidates[0].content.parts) { 
            if (response.candidates[0].content.parts[0]) { 
              if (response.candidates[0].content.parts[0].text) { 
                text = response.candidates[0].content.parts[0].text; 
              } 
            } 
          } 
        } 
      } 
    } 
 
    if (!text) { 
      return; 
    } 
 
    const parsed = JSON.parse(text); 
    const analysis = analysisSchema.parse(parsed); 
 
    await firebaseService.updateIncidentAnalysis(incidentId, analysis); 
    await firebaseService.updateLiveCard(incidentId, analysis); 
 
    if (guestSender) { 
      guestSender(incidentId, { 
        type: 'AI_STATUS', 
        payload: { 
          incidentId: incidentId, 
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
    logger.error('Gemini parse error', { incidentId: incidentId, error: error }); 
  } 
} 
 
export function hasGeminiSession(incidentId) { 
  return geminiSessions.has(incidentId); 
}
