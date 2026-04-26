import admin from 'firebase-admin'; 
import { getFirestore, getRtdb } from '../config/firebase-admin'; 
import { logger } from '../utils/logger'; 
 
const INCIDENTS_COLLECTION = 'incidents'; 
const LIVE_INCIDENTS_ROOT = 'live_incidents'; 
const ACTIVE_LIVE_STATUSES = new Set(['ACTIVE', 'ACKNOWLEDGED']);
const DEFAULT_GUEST_STATUS_MESSAGE =
  'SOS received. Stay calm and keep this emergency session open.';
 
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
const card: any = {
incidentId: incident.incidentId,
status: incident.status,
severity: incident.severity,
roomNumber: incident.roomNumber,
floor: incident.location.floor,
wing: incident.location.wing,
guestName: incident.guestName,
primaryHazard: getPrimaryHazard(incident.hazards),
aiStatus: incident.aiStatus ? incident.aiStatus : 'PENDING',
aiSummary: summary,
lastUpdatedMs: Date.now(),
isStreamLive: Boolean(incident.isStreamLive),
};
if (incident.acknowledgedBy) {
    card.acknowledgedBy = incident.acknowledgedBy;
  }
  return card;
}
 
export async function updateLiveCardByIncident(incident) { 
  const rtdb = getRtdb(); 
  const path = LIVE_INCIDENTS_ROOT + '/' + incident.hotelId + '/' + incident.incidentId; 
  if (!ACTIVE_LIVE_STATUSES.has(incident.status)) {
    await rtdb.ref(path).remove();
    return;
  }
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
    aiStatus: 'PENDING',
    aiSummary: '', 
    guestStatusMessage: DEFAULT_GUEST_STATUS_MESSAGE,
    translatedTranscript: '', 
    originalTranscript: '', 
    detectedLanguage: language, 
    streamSessionId: sessionId, 
    isStreamLive: true, 
    helpOnWay: false,
    recordingGcsPath: input.recordingGcsPath, 
    acknowledgedBy: null, 
    responderLog: [], 
    actionHistory: [
      {
        timestamp: new Date().toISOString(),
        actorId: input.guestId,
        actorLabel: input.guestName ? input.guestName : 'Guest',
        type: 'SYSTEM',
        title: 'SOS started',
        detail: 'Guest opened a live SOS session.',
      },
    ],
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

  const updates: any = {
    hazards: Array.isArray(analysis.hazards) ? analysis.hazards : [], 
    severity: analysis.severity ? analysis.severity : 'LOW', 
    aiStatus: analysis.aiStatus ? analysis.aiStatus : 'AVAILABLE',
    aiSummary: analysis.aiSummary ? analysis.aiSummary : '', 
    translatedTranscript: analysis.translatedTranscript ? analysis.translatedTranscript : '', 
    originalTranscript: analysis.originalTranscript ? analysis.originalTranscript : '', 
    detectedLanguage: analysis.detectedLanguage ? analysis.detectedLanguage : 'en', 
    updatedAt: nowTs(), 
  };
  if (typeof analysis.guestStatusMessage === 'string') {
    updates.guestStatusMessage = analysis.guestStatusMessage;
  } else if (typeof analysis.guestCalm === 'string') {
    updates.guestStatusMessage = analysis.guestCalm;
  }

  await ref.update(updates); 
 
  const merged = Object.assign({}, snapshot.data(), { 
    hazards: Array.isArray(analysis.hazards) ? analysis.hazards : [], 
    severity: analysis.severity ? analysis.severity : 'LOW', 
    aiStatus: analysis.aiStatus ? analysis.aiStatus : 'AVAILABLE',
    aiSummary: analysis.aiSummary ? analysis.aiSummary : '', 
    translatedTranscript: analysis.translatedTranscript ? analysis.translatedTranscript : '', 
    originalTranscript: analysis.originalTranscript ? analysis.originalTranscript : '', 
    detectedLanguage: analysis.detectedLanguage ? analysis.detectedLanguage : 'en', 
  }); 
  if (typeof analysis.guestStatusMessage === 'string') {
    merged.guestStatusMessage = analysis.guestStatusMessage;
  } else if (typeof analysis.guestCalm === 'string') {
    merged.guestStatusMessage = analysis.guestCalm;
  }
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
    aiStatus: analysis.aiStatus ? analysis.aiStatus : incident.aiStatus,
    aiSummary: analysis.aiSummary ? analysis.aiSummary : incident.aiSummary, 
  }); 
  await updateLiveCardByIncident(merged); 
}
 
export async function updateIncidentAiState(incidentId, aiStatus, aiSummary, detail) {
  const firestore = getFirestore();
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    return null;
  }

  const incident = snapshot.data();
  const updates: any = {
    aiStatus,
    updatedAt: nowTs(),
  };
  if (typeof aiSummary === 'string') {
    updates.aiSummary = aiSummary;
  }

  await ref.update(updates);
  const nextIncident = Object.assign({}, incident, updates);
  await updateLiveCardByIncident(nextIncident);
  await addActionHistory(incidentId, {
    actorId: 'system',
    actorLabel: 'System',
    type: 'AI',
    title: 'AI status changed',
    detail: detail ? detail : `AI status is now ${aiStatus}.`,
  });
  return nextIncident;
}

export async function updateIncidentGuestState(
  incidentId,
  payload: {
    guestStatusMessage?: string;
    helpOnWay?: boolean;
  },
) {
  const firestore = getFirestore();
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    return null;
  }

  const incident = snapshot.data();
  const updates: any = {
    updatedAt: nowTs(),
  };
  if (typeof payload.guestStatusMessage === 'string') {
    updates.guestStatusMessage = payload.guestStatusMessage;
  }
  if (typeof payload.helpOnWay === 'boolean') {
    updates.helpOnWay = payload.helpOnWay;
  }

  await ref.update(updates);
  const nextIncident = Object.assign({}, incident, updates);
  await updateLiveCardByIncident(nextIncident);
  return nextIncident;
}

export async function updateIncidentStatus(incidentId, status, staffId, note, staffName) {
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
    updates.helpOnWay = false;
  }
  if (status === 'FALSE_ALARM') {
    updates.resolvedAt = nowTs();
    updates.isStreamLive = false;
    updates.helpOnWay = false;
  }
  if (status === 'ACKNOWLEDGED') {
    if (staffId) {
      updates.acknowledgedBy = staffId;
    }
    updates.helpOnWay = true;
  }

  await ref.update(updates);
  const nextIncident = Object.assign({}, incident, updates);
  await updateLiveCardByIncident(nextIncident);
  await addActionHistory(incidentId, {
    actorId: staffId ? staffId : 'system',
    actorLabel: staffName ? staffName : 'System',
    type: 'STATUS',
    title: 'Status updated',
    detail: `Incident status changed to ${status}.`,
  });

  if (note) {
    await addResponderLog(incidentId, {
      staffId: staffId ? staffId : 'system',
      staffName: staffName ? staffName : 'System',
      action: note,
      type: 'ACTION',
    });
  }

  return nextIncident;
}

export async function updateIncidentEta(incidentId: string, etaMinutes: number) {
  const firestore = getFirestore();
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    return null;
  }

  const incident = snapshot.data();
  const updates: any = {
    etaMinutes: etaMinutes,
    etaSetAt: new Date().toISOString(),
    updatedAt: nowTs(),
  };

  await ref.update(updates);
  const nextIncident = Object.assign({}, incident, updates);
  await updateLiveCardByIncident(nextIncident);
  await addActionHistory(incidentId, {
    actorId: 'system',
    actorLabel: 'System',
    type: 'STATUS',
    title: 'ETA set',
    detail: `Help ETA set to ${etaMinutes} minutes.`,
  });
  return nextIncident;
}
 
export async function addResponderLog(incidentId, payload) { 
  const firestore = getFirestore(); 
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId); 
  // Use regular Date string - can't use serverTimestamp() inside arrayUnion
  const entry = { 
    timestamp: new Date().toISOString(), 
    staffId: payload.staffId, 
    staffName: payload.staffName, 
    action: payload.action, 
    type: payload.type, 
  }; 
  await ref.update({ responderLog: admin.firestore.FieldValue.arrayUnion(entry), updatedAt: nowTs() }); 
  await addActionHistory(incidentId, {
    actorId: payload.staffId,
    actorLabel: payload.staffName,
    type: payload.type === 'SYSTEM' ? 'SYSTEM' : 'NOTE',
    title: payload.type === 'SYSTEM' ? 'System note' : 'Responder note',
    detail: payload.action,
  });
  return entry; 
}

export async function addActionHistory(incidentId, payload) {
  const firestore = getFirestore();
  const ref = firestore.collection(INCIDENTS_COLLECTION).doc(incidentId);
  const entry = {
    timestamp: new Date().toISOString(),
    actorId: payload.actorId,
    actorLabel: payload.actorLabel,
    type: payload.type,
    title: payload.title,
    detail: payload.detail,
  };
  await ref.update({
    actionHistory: admin.firestore.FieldValue.arrayUnion(entry),
    updatedAt: nowTs(),
  });
  return entry;
}
