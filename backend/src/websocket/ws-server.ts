import { WebSocketServer } from 'ws'; 
import jwt from 'jsonwebtoken'; 
import { generateKeyPairSync } from 'crypto'; 
import { URL } from 'url'; 
import { logger } from '../utils/logger'; 
import { handleSosMessage } from './sos-handler'; 
import { registerGuestSender } from './gemini-bridge'; 
import { getFirebaseApp } from '../config/firebase-admin'; 
 
const keyPair = generateKeyPairSync('rsa', { modulusLength: 2048 }); 
const wsSessions = new Map(); 
const dashboardSessions = new Map(); 
let wsServerInstance = null; 
let dashboardWsServer = null; 
 
const heartbeatIntervalMs = Number(process.env.WS_HEARTBEAT_INTERVAL_MS ? process.env.WS_HEARTBEAT_INTERVAL_MS : '30000'); 
 
export function issueWsToken(claims) { 
  return jwt.sign(claims, keyPair.privateKey, { algorithm: 'RS256', expiresIn: '5m' }); 
} 
 
export function verifyWsToken(token) { 
  return jwt.verify(token, keyPair.publicKey, { algorithms: ['RS256'] }); 
} 
 
export function sendToGuest(incidentId, message) { 
  const ws = wsSessions.get(incidentId); 
  if (!ws) { 
    return false; 
  } 
  if (ws.readyState !== 1) { 
    return false; 
  } 
  ws.send(JSON.stringify(message)); 
  return true; 
} 

export function broadcastToDashboards(incidentId, message) { 
  const clients = dashboardSessions.get(incidentId); 
  if (!clients) { 
    return; 
  } 
  const msgStr = JSON.stringify(message); 
  clients.forEach((ws) => { 
    if (ws.readyState === 1) { 
      ws.send(msgStr); 
    } 
  }); 
} 
 
function closeConnection(ws, reason) { 
  try { 
    ws.close(1000, reason); 
  } catch (error) { 
    logger.warn('ws close failed', { error: error }); 
  } 
} 
 
export function createWsServer(httpServer) { 
  const wss = new WebSocketServer({ noServer: true }); 
  wsServerInstance = wss; 
  registerGuestSender(sendToGuest);

  const dashWss = new WebSocketServer({ noServer: true }); 
  dashboardWsServer = dashWss; 
  
  httpServer.on('upgrade', function (request, socket, head) { 
    const host = request.headers.host ? request.headers.host : 'localhost'; 
    const url = new URL(request.url, 'http://' + host); 
    const pathname = url.pathname; 
  
    if (pathname === '/ws') {
      _handleGuestUpgrade(wss, request, socket, head);
    } else if (pathname === '/ws/dashboard') {
      _handleDashboardUpgrade(dashWss, request, socket, head);
    } else {
      socket.destroy();
    }
  }); 
  
  wss.on('connection', function (ws) { 
    ws.on('pong', function () { 
      (ws as any).isAlive = true; 
    }); 
  
    ws.on('message', async function (rawMessage) { 
      const incidentId = (ws as any).incidentId; 
      await handleSosMessage(ws, rawMessage.toString(), incidentId); 
    }); 
  
    ws.on('close', function () { 
      const incidentId = (ws as any).incidentId; 
      if (incidentId) { 
        wsSessions.delete(incidentId); 
      } 
    }); 
  });
  
  const interval = setInterval(function () { 
    wss.clients.forEach(function (ws) { 
      if (!(ws as any).isAlive) { 
        closeConnection(ws, 'heartbeat timeout'); 
        return; 
      } 
      (ws as any).isAlive = false; 
      ws.ping(); 
    }); 
  }, heartbeatIntervalMs); 
  
  wss.on('close', function () { 
    clearInterval(interval); 
  }); 

  dashWss.on('connection', function (ws) { 
    ws.on('close', function () { 
      const incidentId = (ws as any).incidentId; 
      if (incidentId && dashboardSessions.has(incidentId)) { 
        dashboardSessions.get(incidentId)!.delete(ws); 
      } 
    }); 
  }); 

  return wss; 
}

function _handleGuestUpgrade(wss, request, socket, head) {
  const url = new URL(request.url, 'http://' + request.headers.host);
  const token = url.searchParams.get('token'); 
  const incidentId = url.searchParams.get('incidentId'); 
  if (!token || !incidentId) { 
    socket.destroy(); 
    return; 
  } 
  
  let claims = null; 
  try { 
    claims = verifyWsToken(token); 
  } catch (error) { 
    socket.destroy(); 
    return; 
  } 
  
  if (!claims || claims.incidentId !== incidentId) { 
    socket.destroy(); 
    return; 
  } 
  
  wss.handleUpgrade(request, socket, head, function (ws) { 
    (ws as any).incidentId = incidentId; 
    (ws as any).isAlive = true; 
    wsSessions.set(incidentId, ws); 
    wss.emit('connection', ws, request); 
  }); 
}

function _handleDashboardUpgrade(wss, request, socket, head) {
  const url = new URL(request.url, 'http://' + request.headers.host);
  const token = url.searchParams.get('token'); 
  const incidentId = url.searchParams.get('incidentId'); 
  if (!token || !incidentId) { 
    socket.destroy(); 
    return; 
  } 
  
  getFirebaseApp().auth().verifyIdToken(token).then((claims) => { 
    wss.handleUpgrade(request, socket, head, function (ws) { 
      (ws as any).incidentId = incidentId; 
      (ws as any).staffId = claims.uid; 
      
      if (!dashboardSessions.has(incidentId)) { 
        dashboardSessions.set(incidentId, new Set()); 
      } 
      dashboardSessions.get(incidentId)!.add(ws); 
      
      wss.emit('connection', ws, request); 
    }); 
  }).catch((error) => { 
    logger.warn('dashboard ws auth failed', { error: error?.message });
    socket.destroy(); 
  }); 
}
 
export function getWsServer() { 
  return wsServerInstance; 
}
