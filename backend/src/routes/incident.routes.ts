import { Router } from 'express'; 
import { z } from 'zod'; 
import * as firebaseService from '../services/firebase.service'; 
import { issueWsToken } from '../websocket/ws-server'; 
import { isGeminiConfigured } from '../services/gemini.service'; 
 
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
 
  if (!isGeminiConfigured()) { 
    res.status(503).json({ error: 'Gemini service unavailable' }); 
    return; 
  } 
 
  const body = parsed.data; 
  const result = await firebaseService.createIncident(body); 
  if (result.exists) { 
    res.status(409).json({ error: 'Incident with this ID already exists' }); 
    return; 
  } 
 
  const wsToken = issueWsToken({ 
    incidentId: body.incidentId, 
    guestId: body.guestId, 
    hotelId: body.hotelId, 
  }); 
 
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
  if (requester) { 
    if (requester.uid) { 
      staffId = requester.uid; 
    } 
  } 
  const updated = await firebaseService.updateIncidentStatus(req.params.incidentId, parsed.data.status, staffId, parsed.data.note); 
  if (!updated) { 
    res.status(404).json({ error: 'Not found' }); 
    return; 
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
  if (requester) { 
    if (requester.uid) { 
      staffId = requester.uid; 
    } 
  } 
  const entry = await firebaseService.addResponderLog(req.params.incidentId, { 
    staffId: staffId, 
    staffName: 'Staff', 
    action: parsed.data.action, 
    type: parsed.data.type, 
  }); 
 
  res.status(201).json({ 
    logEntryId: Buffer.from(Date.now().toString()).toString('hex'), 
    timestamp: new Date().toISOString(), 
    entry: entry, 
  }); 
});
