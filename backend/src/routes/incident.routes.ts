import { Router } from 'express';
import { z } from 'zod';
import * as firebaseService from '../services/firebase.service';
import { sendToGuest } from '../websocket/ws-server';
import { cancelEscalationTimer } from '../services/escalation.service';
 
const createIncidentSchema = z.object({ 
  incidentId: z.string(), 
  hotelId: z.string(), 
  roomNumber: z.string(), 
  floor: z.number(), 
  wing: z.string(), 
  guestId: z.string(), 
  guestName: z.string(), 
  guestLanguage: z.string(), 
  lat: z.number().optional(), 
  lng: z.number().optional(), 
}); 
 
const patchStatusSchema = z.object({
  status: z.enum(['ACKNOWLEDGED', 'RESOLVED', 'FALSE_ALARM']),
  note: z.string().optional(),
  etaMinutes: z.number().min(1).max(60).optional(),
});
 
const logSchema = z.object({ 
  action: z.string(), 
  type: z.enum(['NOTE', 'ACTION']), 
}); 
 
function getRequester(req) { 
  if ((req as any).user) { 
    return (req as any).user; 
  } 
  return null; 
} 
 
export const incidentRouter = Router();
 
incidentRouter.post('/', async function (req, res) { 
  const parsed = createIncidentSchema.safeParse(req.body); 
  if (!parsed.success) { 
    res.status(400).json({ error: 'Validation failed' }); 
    return; 
  } 
 
  const body = parsed.data; 
  const result = await firebaseService.createIncident(body); 
  if (result.exists) { 
    res.status(409).json({ error: 'Incident with this ID already exists' }); 
    return; 
  } 
 
  const authHeader = typeof req.headers.authorization === 'string'
    ? req.headers.authorization
    : '';
  const wsToken = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : '';
 
  res.status(201).json({ 
    incidentId: body.incidentId, 
    status: 'ACTIVE', 
    wsToken: wsToken, 
    message: 'SOS received. Help is being dispatched.', 
  }); 
}); 
 
incidentRouter.get('/', async function (req, res) { 
  let hotelId = ''; 
  if (req.query.hotelId) { 
    hotelId = String(req.query.hotelId); 
  } 
  let status = null; 
  if (req.query.status) { 
    status = String(req.query.status); 
  } 
  if (!hotelId) { 
    res.status(400).json({ error: 'Validation failed' }); 
    return; 
  } 
  const incidents = await firebaseService.listIncidentsByHotel(hotelId, status); 
  res.status(200).json({ incidents: incidents, total: incidents.length }); 
}); 
 
incidentRouter.get('/:incidentId', async function (req, res) { 
  const requester = getRequester(req); 
  const incident = await firebaseService.getIncidentById(req.params.incidentId); 
  if (!incident) { 
    res.status(404).json({ error: 'Not found' }); 
    return; 
  } 
  if (requester) { 
    if (requester.hotelId) { 
      if (requester.hotelId !== incident.hotelId) { 
        res.status(403).json({ error: 'Requester not in same hotelId' }); 
        return; 
      } 
    } 
  } 
  res.status(200).json(incident); 
}); 
 
incidentRouter.patch('/:incidentId/status', async function (req, res) {
  const parsed = patchStatusSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation failed' });
    return;
  }

  const requester = getRequester(req);
  let staffId = null;
  let staffName = 'Staff';
  if (requester) {
    if (requester.uid) {
      staffId = requester.uid;
    }
    if (requester.email) {
      staffName = String(requester.email);
    } else if (requester.name) {
      staffName = String(requester.name);
    }
  }
  
  // Get incident before update to access severity
  const incidentBefore = await firebaseService.getIncidentById(req.params.incidentId);
  const updated = await firebaseService.updateIncidentStatus(req.params.incidentId, parsed.data.status, staffId, parsed.data.note, staffName);
  if (!updated) {
    res.status(404).json({ error: 'Not found' });
    return;
  }

  // Handle ETA for ACKNOWLEDGED status
  if (parsed.data.status === 'ACKNOWLEDGED') {
    const etaMinutes = parsed.data.etaMinutes;
    const guestMessage = etaMinutes 
      ? `Security has acknowledged your SOS. Estimated arrival: ${etaMinutes} minutes.`
      : 'Security has acknowledged your SOS. Stay calm and keep this feed active.';
    
    // Cancel escalation timer since staff has acknowledged
    cancelEscalationTimer(req.params.incidentId);
    
    // Store ETA in Firestore if provided
    if (etaMinutes !== undefined && etaMinutes !== null) {
      await firebaseService.updateIncidentEta(req.params.incidentId, etaMinutes);
    }
    await firebaseService.updateIncidentGuestState(req.params.incidentId, {
      guestStatusMessage: guestMessage,
      helpOnWay: true,
    });
    
    // Send WS message to guest
    sendToGuest(req.params.incidentId, {
      type: 'AI_STATUS',
      payload: {
        incidentId: req.params.incidentId,
        message: guestMessage,
        severity: updated.severity || incidentBefore?.severity || 'LOW',
        helpOnWay: true,
        estimatedArrivalMin: etaMinutes,
      },
    });
  }

  if (parsed.data.status === 'RESOLVED' || parsed.data.status === 'FALSE_ALARM') {
    const guestMessage = parsed.data.status === 'FALSE_ALARM'
      ? 'Security closed this incident as a false alarm.'
      : 'Security marked this incident as resolved.';
    await firebaseService.updateIncidentGuestState(req.params.incidentId, {
      guestStatusMessage: guestMessage,
      helpOnWay: false,
    });
    sendToGuest(req.params.incidentId, {
      type: 'INCIDENT_RESOLVED',
      payload: {
        incidentId: req.params.incidentId,
        resolvedBy: 'staff',
        message: guestMessage,
      },
    });
  }
 
  res.status(200).json({ 
    incidentId: req.params.incidentId, 
    status: parsed.data.status, 
    updatedAt: new Date().toISOString(), 
  }); 
});
 
incidentRouter.post('/:incidentId/log', async function (req, res) { 
  const parsed = logSchema.safeParse(req.body); 
  if (!parsed.success) { 
    res.status(400).json({ error: 'Validation failed' }); 
    return; 
  } 
 
  const requester = getRequester(req); 
  let staffId = 'system'; 
  let staffName = 'Staff';
  if (requester) { 
    if (requester.uid) { 
      staffId = requester.uid; 
    } 
    if (requester.email) {
      staffName = String(requester.email);
    } else if (requester.name) {
      staffName = String(requester.name);
    }
  } 
  const entry = await firebaseService.addResponderLog(req.params.incidentId, { 
    staffId: staffId, 
    staffName: staffName, 
    action: parsed.data.action, 
    type: parsed.data.type, 
  }); 
 
  res.status(201).json({ 
    logEntryId: Buffer.from(Date.now().toString()).toString('hex'), 
    timestamp: new Date().toISOString(), 
    entry: entry, 
  }); 
});
