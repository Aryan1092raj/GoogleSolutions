import { Router } from 'express'; 
import { z } from 'zod'; 
import { randomUUID } from 'crypto'; 
import { getFirebaseApp } from '../config/firebase-admin'; 
import { logger } from '../utils/logger'; 
 
const guestTokenSchema = z.object({ 
  hotelId: z.string(), 
  roomNumber: z.string(), 
  guestName: z.string(), 
  language: z.string(), 
}); 
 
const staffLoginSchema = z.object({ 
  email: z.string().email(), 
  password: z.string().min(1), 
}); 
 
async function hotelExists(hotelId) { 
  const snapshot = await getFirebaseApp().database().ref('hotels/' + hotelId).once('value'); 
  return snapshot.exists(); 
} 
 
export const authRouter = Router();
 
authRouter.post('/guest-token', async function (req, res) { 
  const parsed = guestTokenSchema.safeParse(req.body); 
  if (!parsed.success) { 
    res.status(400).json({ error: 'Missing required field' }); 
    return; 
  } 
 
  const body = parsed.data; 
  const exists = await hotelExists(body.hotelId); 
  if (!exists) { 
    res.status(404).json({ error: 'Hotel not found' }); 
    return; 
  } 
 
  const uid = 'guest_' + randomUUID(); 
  const claims = { 
    hotelId: body.hotelId, 
    role: 'GUEST', 
    roomNumber: body.roomNumber, 
    guestName: body.guestName, 
    language: body.language, 
  }; 
 
  const customToken = await getFirebaseApp().auth().createCustomToken(uid, claims); 
  res.status(200).json({ customToken: customToken, guestId: uid, expiresIn: 3600 }); 
}); 
 
authRouter.post('/staff-login', async function (req, res) { 
  const parsed = staffLoginSchema.safeParse(req.body); 
  if (!parsed.success) { 
    res.status(400).json({ error: 'Missing required field' }); 
    return; 
  } 
 
  const apiKey = process.env.FIREBASE_WEB_API_KEY; 
  if (!apiKey) { 
    logger.error('FIREBASE_WEB_API_KEY is not configured'); 
    res.status(503).json({ error: 'Firebase Auth unavailable' }); 
    return; 
  } 
 
  const signInUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + apiKey; 
 
  try { 
    const authResponse = await fetch(signInUrl, { 
      method: 'POST', 
      headers: { 'Content-Type': 'application/json' }, 
      body: JSON.stringify({ 
        email: parsed.data.email, 
        password: parsed.data.password, 
        returnSecureToken: true, 
      }), 
    }); 
 
    const authData = await authResponse.json(); 
    if (!authResponse.ok) { 
      res.status(401).json({ error: 'Invalid email or password' }); 
      return; 
    } 
    if (!authData.idToken) { 
      res.status(401).json({ error: 'Invalid email or password' }); 
      return; 
    } 
 
    const decoded = await getFirebaseApp().auth().verifyIdToken(authData.idToken); 
    const staffId = decoded.uid; 
    let hotelId = ''; 
    let role = 'SECURITY'; 
    if (typeof decoded.hotelId === 'string') { 
      hotelId = decoded.hotelId; 
    } 
    if (typeof decoded.role === 'string') { 
      role = decoded.role; 
    } 
 
    res.status(200).json({ 
      idToken: authData.idToken, 
      staffId: staffId, 
      hotelId: hotelId, 
      role: role, 
    }); 
  } catch (error) { 
    logger.error('staff-login failed', { error: error }); 
    res.status(503).json({ error: 'Firebase Auth unavailable' }); 
  } 
});
