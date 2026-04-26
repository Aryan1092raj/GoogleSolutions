import { guestToBackendMessageSchema } from '../models/ws-message.model';
import * as firebaseService from '../services/firebase.service';
import * as fcmService from '../services/fcm.service';
import * as storageService from '../services/storage.service';
import { getRtdb } from '../config/firebase-admin';
import { logger } from '../utils/logger';
import { closeGeminiSession, openGeminiSession, sendMediaToGemini } from './gemini-bridge';
import { sendToGuest } from './ws-server';
import { startEscalationTimer, cancelEscalationTimer } from '../services/escalation.service';
 
const maxChunkBytes = Number(process.env.MAX_MEDIA_CHUNK_BYTES ? process.env.MAX_MEDIA_CHUNK_BYTES : '524288'); 
 
function sendWsError(incidentId, code, message, retryable) { 
  sendToGuest(incidentId, { 
    type: 'WS_ERROR', 
    payload: { code: code, message: message, retryable: retryable }, 
  }); 
} 
 
function isChunkTooLarge(base64Data) { 
  if (!base64Data) { 
    return false; 
  } 
  const bytes = Buffer.byteLength(base64Data, 'base64'); 
  if (bytes > maxChunkBytes) { 
    return true; 
  } 
  return false; 
} 

async function relayFrameToRtdb(incidentId: string, videoBase64: string) {
  try {
    const rtdb = getRtdb();
    await rtdb.ref('live_frames/' + incidentId).set({
      frame: videoBase64,
      updatedMs: Date.now(),
    });
  } catch (error) {
    logger.warn('Failed to relay live frame to RTDB', {
      incidentId,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
 
export async function handleSosMessage(ws, rawMessage, incidentIdFromConnection) { 
  let parsed; 
  try { 
    parsed = JSON.parse(rawMessage); 
  } catch (error) { 
    sendWsError(incidentIdFromConnection, 'BAD_JSON', 'Malformed JSON payload', false); 
    return; 
  } 
 
  let msg; 
  try { 
    msg = guestToBackendMessageSchema.parse(parsed); 
  } catch (error) { 
    sendWsError(incidentIdFromConnection, 'BAD_MESSAGE', 'Message schema validation failed', false); 
    return; 
  }
 
  const messageIncidentId = msg.payload.incidentId; 
  if (messageIncidentId !== incidentIdFromConnection) { 
    sendWsError(incidentIdFromConnection, 'INCIDENT_MISMATCH', 'incidentId does not match session', false); 
    return; 
  } 
 
  if (msg.type === 'SOS_INIT') {
    const created = await firebaseService.createIncident({
      incidentId: msg.payload.incidentId,
      hotelId: msg.payload.hotelId,
      roomNumber: msg.payload.roomNumber,
      floor: msg.payload.floor,
      wing: msg.payload.wing,
      guestId: msg.payload.guestId,
      guestName: msg.payload.guestName,
      guestLanguage: msg.payload.guestLanguage,
      lat: msg.payload.lat,
      lng: msg.payload.lng,
      streamSessionId: msg.payload.incidentId,
    });

    const incident = created.incident;
    try {
      await openGeminiSession(msg.payload.incidentId, msg.payload.guestLanguage);
    } catch (error) {
      sendWsError(msg.payload.incidentId, 'GEMINI_UNAVAILABLE', 'Gemini session open failed', true);
    }

    await fcmService.alertAllStaff(msg.payload.hotelId, incident);
    
    // Start escalation timer if not acknowledged within 3 minutes
    startEscalationTimer(msg.payload.incidentId, msg.payload.hotelId);
    
    sendToGuest(msg.payload.incidentId, {
      type: 'SOS_ACCEPTED',
      payload: {
        incidentId: msg.payload.incidentId,
        message: 'SOS received. Help is being dispatched.',
      },
    });
    return;
  }
 
  if (msg.type === 'MEDIA_CHUNK') { 
    if (isChunkTooLarge(msg.payload.video)) { 
      sendWsError(msg.payload.incidentId, 'CHUNK_TOO_LARGE', 'Video chunk exceeds limit', true); 
      return; 
    } 
    if (isChunkTooLarge(msg.payload.audio)) { 
      sendWsError(msg.payload.incidentId, 'CHUNK_TOO_LARGE', 'Audio chunk exceeds limit', true); 
      return; 
    } 
 
    await sendMediaToGemini(msg.payload.incidentId, msg.payload);
    await storageService.appendMediaChunk(msg.payload.incidentId, msg.payload.chunkIndex, msg.payload.video, msg.payload.audio);

    // Relay latest frame to RTDB so dashboard can display it (every 2 chunks = ~3fps at 6fps capture)
    if (msg.payload.video && msg.payload.chunkIndex % 2 === 0) {
      await relayFrameToRtdb(msg.payload.incidentId, msg.payload.video);
    }
    return;
  }
 
  if (msg.type === 'LOCATION_UPDATE') { 
    await firebaseService.updateIncidentLocation(msg.payload.incidentId, msg.payload); 
    return; 
  } 
 
  if (msg.type === 'SOS_END') {
    closeGeminiSession(msg.payload.incidentId);
    
    // Cancel escalation timers
    cancelEscalationTimer(msg.payload.incidentId);

    let finalStatus = 'RESOLVED';
    if (msg.payload.reason === 'FALSE_ALARM') {
      finalStatus = 'FALSE_ALARM';
    }

    await firebaseService.updateIncidentStatus(
      msg.payload.incidentId,
      finalStatus,
      null,
      'Guest ended SOS',
      'Guest',
    );
    const gcsPath = await storageService.finalizeRecording(msg.payload.incidentId);

    if (gcsPath) {
      await firebaseService.updateIncidentAnalysis(msg.payload.incidentId, {
        hazards: [],
        severity: 'LOW',
        aiSummary: 'Incident recording finalized',
        translatedTranscript: '',
        originalTranscript: '',
        detectedLanguage: 'en',
      });
    }

    sendToGuest(msg.payload.incidentId, {
      type: 'INCIDENT_RESOLVED',
      payload: {
        incidentId: msg.payload.incidentId,
        resolvedBy: 'guest',
        message: 'Incident marked as resolved.',
      },
    });
    return;
  }
 
  if (msg.type === 'WS_PING') { 
    sendToGuest(msg.payload.incidentId, { 
      type: 'WS_PONG', 
      payload: { ts: msg.payload.ts }, 
    }); 
    return; 
  } 
 
  logger.warn('Unhandled WS message type', { type: msg.type }); 
}
