import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import http from 'http';
import { authRouter } from './routes/auth.routes'; 
import { incidentRouter } from './routes/incident.routes'; 
import { healthRouter } from './routes/health.routes'; 
import { getFirebaseApp } from './config/firebase-admin'; 
import { createWsServer } from './websocket/ws-server'; 
import { logger } from './utils/logger'; 
 
const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '2mb' }));
 
function isPublicRoute(req) { 
  if (req.path === '/health') { 
    return true; 
  } 
  if (req.path.indexOf('/api/auth/') === 0) { 
    return true; 
  } 
  return false; 
} 
 
app.use(async function (req, res, next) { 
  if (isPublicRoute(req)) { 
    next(); 
    return; 
  } 
 
  const authHeader = req.headers.authorization; 
  if (!authHeader) { 
    res.status(401).json({ error: 'Missing Authorization header' }); 
    return; 
  } 
  if (authHeader.indexOf('Bearer ') !== 0) { 
    res.status(401).json({ error: 'Invalid Authorization header' }); 
    return; 
  } 
 
  const token = authHeader.slice(7); 
  try { 
    const decoded = await getFirebaseApp().auth().verifyIdToken(token); 
    (req as any).user = decoded; 
    next(); 
  } catch (error) { 
    res.status(401).json({ error: 'Invalid token' }); 
  } 
});
 
app.use('/health', healthRouter); 
app.use('/api/auth', authRouter);

// App Check verification for incident creation.
// APP_CHECK_ENFORCE=true (default): hard-reject invalid/missing tokens.
// APP_CHECK_ENFORCE=false: monitoring-only mode — log warning, allow through.
// Use monitoring mode for Firebase App Distribution builds (no Play Store).
const appCheckEnforce = (process.env.APP_CHECK_ENFORCE ?? 'true').trim().toLowerCase() !== 'false';

app.use('/api/incidents', async function (req, res, next) {
  if (req.method !== 'POST') { next(); return; }
  const appCheckToken = req.headers['x-firebase-appcheck'];

  // No token at all — always reject in enforce mode, warn in monitoring mode
  if (!appCheckToken || typeof appCheckToken !== 'string' || appCheckToken.trim() === '') {
    if (appCheckEnforce) {
      res.status(401).json({ error: 'App Check token missing' });
      return;
    }
    logger.warn('App Check token missing — monitoring mode, allowing through', {
      path: req.path,
      method: req.method,
    });
    next();
    return;
  }

  try {
    await getFirebaseApp().appCheck().verifyToken(appCheckToken.trim());
    next();
  } catch (error) {
    if (appCheckEnforce) {
      logger.warn('App Check verification failed — enforce mode, blocking', { error });
      res.status(401).json({ error: 'App Check verification failed' });
      return;
    }
    logger.warn('App Check verification failed — monitoring mode, allowing through', { error });
    next();
  }
});
app.use('/api/incidents', incidentRouter);
 
const server = http.createServer(app); 
createWsServer(server); 
 
const port = Number(process.env.PORT ? process.env.PORT : '8080'); 
server.listen(port, function () { 
  logger.info('ResQLink backend listening', { port: port }); 
});
