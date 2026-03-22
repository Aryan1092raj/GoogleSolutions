import 'dotenv/config'; 
import express from 'express'; 
import http from 'http'; 
import { authRouter } from './routes/auth.routes'; 
import { incidentRouter } from './routes/incident.routes'; 
import { healthRouter } from './routes/health.routes'; 
import { getFirebaseApp } from './config/firebase-admin'; 
import { createWsServer } from './websocket/ws-server'; 
import { logger } from './utils/logger'; 
 
const app = express(); 
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
app.use('/api/incidents', incidentRouter); 
 
const server = http.createServer(app); 
createWsServer(server); 
 
const port = Number(process.env.PORT ? process.env.PORT : '8080'); 
server.listen(port, function () { 
  logger.info('ResQLink backend listening', { port: port }); 
});
