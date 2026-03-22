import admin from 'firebase-admin'; 
import { getFirestore, getRtdb } from '../config/firebase-admin'; 
import { logger } from '../utils/logger'; 
 
const INCIDENTS_COLLECTION = 'incidents'; 
const LIVE_INCIDENTS_ROOT = 'live_incidents'; 
 
function nowTs() { 
  return admin.firestore.FieldValue.serverTimestamp(); 
} 
 
function getPrimaryHazard(hazards) { 
  if (!Array.isArray(hazards)) { 
    return 'UNKNOWN'; 
  } 
  if (hazards.length === 0) { 
    return 'UNKNOWN'; 
  } 
  if (!hazards[0]) { 
    return 'UNKNOWN'; 
  } 
  if (!hazards[0].type) { 
    return 'UNKNOWN'; 
  } 
  return hazards[0].type; 
} 
 
function buildLiveCard(incident) { 
  const summary = incident.aiSummary ? incident.aiSummary : ''; 
  return { 
    incidentId: incident.incidentId, 
    status: incident.status, 
    severity: incident.severity, 
    roomNumber: incident.roomNumber, 
    floor: incident.location.floor, 
    wing: incident.location.wing, 
    guestName: incident.guestName, 
    primaryHazard: getPrimaryHazard(incident.hazards), 
    aiSummary: summary, 
    lastUpdatedMs: Date.now(), 
    isStreamLive: Boolean(incident.isStreamLive), 
    acknowledgedBy: incident.acknowledgedBy ? incident.acknowledgedBy : undefined, 
  }; 
} 
 
export async function updateLiveCardByIncident(incident) { 
  const rtdb = getRtdb(); 
  const path = LIVE_INCIDENTS_ROOT + '/' + incident.hotelId + '/' + incident.incidentId; 
  await rtdb.ref(path).set(buildLiveCard(incident)); 
} 
 
export async function createIncident(input) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(input.incidentId); 
  const existing = await ref.get(); 
  if (existing.exists) { 
    return { exists: true, incident: existing.data() }; 
  } 
 
  const language = input.guestLanguage ? input.guestLanguage : 'en'; 
  const sessionId = input.streamSessionId ? input.streamSessionId : ''; 
  const incident = { 
    incidentId: input.incidentId, 
    status: 'ACTIVE', 
    createdAt: nowTs(), 
    updatedAt: nowTs(), 
    guestId: input.guestId, 
    guestName: input.guestName, 
    guestPhone: input.guestPhone, 
    guestLanguage: language, 
    roomNumber: input.roomNumber, 
    hotelId: input.hotelId, 
    location: { 
      floor: input.floor, 
      wing: input.wing, 
      roomNumber: input.roomNumber, 
      lat: input.lat, 
      lng: input.lng, 
      accuracyMeters: input.accuracyMeters, 
    }, 
    hazards: [], 
    severity: 'LOW', 
    aiSummary: '', 
    translatedTranscript: '', 
    originalTranscript: '', 
    detectedLanguage: language, 
    streamSessionId: sessionId, 
    isStreamLive: true, 
    recordingGcsPath: input.recordingGcsPath, 
    acknowledgedBy: null, 
    responderLog: [], 
  }; 
 
  await ref.set(incident); 
  await updateLiveCardByIncident(incident); 
  return { exists: false, incident }; 
}
 
export async function getIncidentById(incidentId) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  const snapshot = await ref.get(); 
  if (!snapshot.exists) { 
    return null; 
  } 
  return snapshot.data(); 
} 
 
export async function listIncidentsByHotel(hotelId, status) { 
  const firestore = getFirestore(); 
  let query = firestore.collection(INCIDENTS_COLLECTION).where('hotelId', '==', hotelId); 
  if (status) { 
    query = query.where('status', '==', status); 
  } 
  const snap = await query.get(); 
  const incidents = []; 
  snap.forEach(function (doc) { 
    incidents.push(doc.data()); 
  }); 
  return incidents; 
} 
 
export async function updateIncidentLocation(incidentId, payload) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  const snapshot = await ref.get(); 
  if (!snapshot.exists) { 
    return null; 
  } 
  const incident = snapshot.data(); 
  const nextLocation = { 
    floor: payload.floor !== undefined ? payload.floor : incident.location.floor, 
    wing: incident.location.wing, 
    roomNumber: incident.location.roomNumber, 
    lat: payload.lat, 
    lng: payload.lng, 
    accuracyMeters: payload.accuracyMeters, 
  }; 
  await ref.update({ location: nextLocation, updatedAt: nowTs() }); 
  const nextIncident = Object.assign({}, incident, { location: nextLocation }); 
  await updateLiveCardByIncident(nextIncident); 
  return nextIncident; 
}
 
export async function updateIncidentAnalysis(incidentId, analysis) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  const snapshot = await ref.get(); 
  if (!snapshot.exists) { 
    logger.warn('Incident not found for analysis update', { incidentId }); 
    return null; 
  } 
 
  await ref.update({ 
    hazards: Array.isArray(analysis.hazards) ? analysis.hazards : [], 
    severity: analysis.severity ? analysis.severity : 'LOW', 
    aiSummary: analysis.aiSummary ? analysis.aiSummary : '', 
    translatedTranscript: analysis.translatedTranscript ? analysis.translatedTranscript : '', 
    originalTranscript: analysis.originalTranscript ? analysis.originalTranscript : '', 
    detectedLanguage: analysis.detectedLanguage ? analysis.detectedLanguage : 'en', 
    updatedAt: nowTs(), 
  }); 
 
  const merged = Object.assign({}, snapshot.data(), { 
    hazards: Array.isArray(analysis.hazards) ? analysis.hazards : [], 
    severity: analysis.severity ? analysis.severity : 'LOW', 
    aiSummary: analysis.aiSummary ? analysis.aiSummary : '', 
    translatedTranscript: analysis.translatedTranscript ? analysis.translatedTranscript : '', 
    originalTranscript: analysis.originalTranscript ? analysis.originalTranscript : '', 
    detectedLanguage: analysis.detectedLanguage ? analysis.detectedLanguage : 'en', 
  }); 
  await updateLiveCardByIncident(merged); 
  return merged; 
} 
 
export async function updateLiveCard(incidentId, analysis) { 
  const incident = await getIncidentById(incidentId); 
  if (!incident) { 
    return; 
  } 
  const merged = Object.assign({}, incident, { 
    hazards: Array.isArray(analysis.hazards) ? analysis.hazards : incident.hazards, 
    severity: analysis.severity ? analysis.severity : incident.severity, 
    aiSummary: analysis.aiSummary ? analysis.aiSummary : incident.aiSummary, 
  }); 
  await updateLiveCardByIncident(merged); 
}
 
export async function updateIncidentStatus(incidentId, status, staffId, note) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  const snapshot = await ref.get(); 
  if (!snapshot.exists) { 
    return null; 
  } 
 
  const incident = snapshot.data(); 
  const updates: any = { status: status, updatedAt: nowTs() }; 
  if (status === 'RESOLVED') { 
    updates.resolvedAt = nowTs(); 
    updates.isStreamLive = false; 
  } 
  if (status === 'FALSE_ALARM') { 
    updates.resolvedAt = nowTs(); 
    updates.isStreamLive = false; 
  } 
  if (status === 'ACKNOWLEDGED') { 
    if (staffId) { 
      updates.acknowledgedBy = staffId; 
    } 
  } 
 
  await ref.update(updates); 
  const nextIncident = Object.assign({}, incident, updates); 
  await updateLiveCardByIncident(nextIncident); 
 
  if (note) { 
    await addResponderLog(incidentId, { 
      staffId: staffId ? staffId : 'system', 
      staffName: 'System', 
      action: note, 
      type: 'ACTION', 
    }); 
  } 
 
  return nextIncident; 
} 
 
export async function addResponderLog(incidentId, payload) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  const entry = { 
    timestamp: nowTs(), 
    staffId: payload.staffId, 
    staffName: payload.staffName, 
    action: payload.action, 
    type: payload.type, 
  }; 
  await ref.update({ responderLog: admin.firestore.FieldValue.arrayUnion(entry), updatedAt: nowTs() }); 
  return entry; 
}
