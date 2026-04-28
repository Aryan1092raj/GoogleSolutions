import { WebSocketServer } from 'ws'; 
import { URL } from 'url'; 
import { logger } from '../utils/logger'; 
import { handleSosMessage } from './sos-handler'; 
import { registerGuestSender } from './gemini-bridge'; 
import { getFirebaseApp } from '../config/firebase-admin'; 
import * as firebaseService from '../services/firebase.service';
 
const wsSessions = new Map(); 
const dashboardSessions = new Map(); 
let wsServerInstance = null; 
let dashboardWsServer = null; 
 
const heartbeatIntervalMs = Number(process.env.WS_HEARTBEAT_INTERVAL_MS ? process.env.WS_HEARTBEAT_INTERVAL_MS : '30000'); 
 
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
    socket.write('HTTP/1.1 400 Bad Request\r\n\r\nMissing token or incidentId');
    socket.destroy();
    return;
  }

  getFirebaseApp().auth().verifyIdToken(token).then(async (claims) => {
    const incident = await firebaseService.getIncidentById(incidentId);
    if (!incident) {
      socket.write('HTTP/1.1 404 Not Found\r\n\r\nIncident not found');
      socket.destroy();
      return;
    }

    const guestId = typeof claims.uid === 'string' ? claims.uid : '';
    const hotelId = typeof claims.hotelId === 'string' ? claims.hotelId : '';
    if (guestId !== incident.guestId || (hotelId && hotelId !== incident.hotelId)) {
      socket.write('HTTP/1.1 403 Forbidden\r\n\r\nGuest token does not match incident');
      socket.destroy();
      return;
    }

    wss.handleUpgrade(request, socket, head, function (ws) {
      (ws as any).incidentId = incidentId;
      (ws as any).guestId = guestId;
      (ws as any).isAlive = true;
      wsSessions.set(incidentId, ws);
      wss.emit('connection', ws, request);
    });
  }).catch((error) => {
    logger.warn('guest ws auth failed', {
      incidentId,
      error: error?.message,
    });
    socket.write('HTTP/1.1 401 Unauthorized\r\n\r\nInvalid Firebase token');
    socket.destroy();
  });
}

function _handleDashboardUpgrade(wss, request, socket, head) {
  const url = new URL(request.url, 'http://' + request.headers.host);
  const token = url.searchParams.get('token');
  const incidentId = url.searchParams.get('incidentId');
  if (!token || !incidentId) {
    socket.write('HTTP/1.1 400 Bad Request\r\n\r\nMissing token or incidentId');
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
    logger.warn('dashboard ws auth failed', {
      incidentId,
      error: error?.message,
    });
    socket.write('HTTP/1.1 401 Unauthorized\r\n\r\nInvalid Firebase token');
    socket.destroy();
  });
}
 
export function getWsServer() { 
  return wsServerInstance; 
}
