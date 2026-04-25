import { getRtdb, getMessaging } from '../config/firebase-admin';
import * as firebaseService from './firebase.service';
import { logger } from '../utils/logger';

const escalationTimers = new Map<string, NodeJS.Timeout>();

/**
 * Start escalation timer for an unacknowledged SOS incident.
 * Escalation path: SECURITY → MANAGER (3 min) → FIRST_RESPONDER (6 min total)
 */
export function startEscalationTimer(incidentId: string, hotelId: string) {
  // Cancel any existing timer for this incident
  cancelEscalationTimer(incidentId);
  
  logger.info('Starting escalation timer', { incidentId, hotelId });
  
  // If no SECURITY staff acknowledges within 3 minutes, alert MANAGER
  const timer = setTimeout(async () => {
    const incident = await firebaseService.getIncidentById(incidentId);
    if (!incident) {
      logger.warn('Escalation cancelled: incident not found', { incidentId });
      return;
    }
    
    // Stop escalation if incident has been acknowledged or resolved
    if (incident.status === 'ACKNOWLEDGED' || incident.status === 'RESOLVED' || incident.status === 'FALSE_ALARM') {
      logger.info('Escalation cancelled: incident already handled', { incidentId, status: incident.status });
      return;
    }
    
    logger.info('Escalating to MANAGER', { incidentId, roomNumber: incident.roomNumber });
    
    // Escalate: notify MANAGER role
    await escalateToRole(hotelId, incidentId, 'MANAGER', incident);
    
    // If MANAGER doesn't acknowledge in 3 more minutes, alert FIRST_RESPONDER
    const timer2 = setTimeout(async () => {
      const incident2 = await firebaseService.getIncidentById(incidentId);
      if (!incident2) {
        logger.warn('Escalation lvl2 cancelled: incident not found', { incidentId });
        return;
      }
      
      if (incident2.status === 'ACKNOWLEDGED' || incident2.status === 'RESOLVED' || incident2.status === 'FALSE_ALARM') {
        logger.info('Escalation lvl2 cancelled: incident already handled', { incidentId, status: incident2.status });
        return;
      }
      
      logger.info('Escalating to FIRST_RESPONDER', { incidentId, roomNumber: incident2.roomNumber });
      await escalateToRole(hotelId, incidentId, 'FIRST_RESPONDER', incident2);
      
    }, 3 * 60 * 1000); // 3 more minutes
    
    escalationTimers.set(incidentId + '_lvl2', timer2);
    
  }, 3 * 60 * 1000); // 3 minutes
  
  escalationTimers.set(incidentId, timer);
}

/**
 * Cancel all escalation timers for an incident.
 */
export function cancelEscalationTimer(incidentId: string) {
  const t1 = escalationTimers.get(incidentId);
  const t2 = escalationTimers.get(incidentId + '_lvl2');
  
  if (t1) {
    clearTimeout(t1);
    escalationTimers.delete(incidentId);
    logger.debug('Cancelled escalation timer', { incidentId, level: 1 });
  }
  
  if (t2) {
    clearTimeout(t2);
    escalationTimers.delete(incidentId + '_lvl2');
    logger.debug('Cancelled escalation timer', { incidentId, level: 2 });
  }
}

/**
 * Send FCM notification to staff with a specific role.
 */
async function escalateToRole(hotelId: string, incidentId: string, role: string, incident: any) {
  const rtdb = getRtdb();
  const snap = await rtdb.ref('hotels/' + hotelId + '/staff_online').once('value');
  const staffMap = snap.val();
  
  if (!staffMap) {
    logger.warn('No staff online for escalation', { hotelId, role });
    return;
  }
  
  const tokens: string[] = [];
  for (const member of Object.values(staffMap) as any[]) {
    if (member?.isOnDuty && member?.role === role && member?.fcmToken) {
      tokens.push(member.fcmToken);
    }
  }
  
  if (tokens.length === 0) {
    logger.warn('No on-duty staff with role for escalation', { hotelId, role });
    return;
  }
  
  const messaging = getMessaging();
  await messaging.sendMulticast({
    tokens,
    notification: {
      title: `ESCALATED SOS — ResQLink`,
      body: `Unacknowledged emergency: Room ${incident.roomNumber} — ${incident.severity}`,
    },
    data: {
      incidentId,
      type: 'ESCALATED_SOS',
      escalatedTo: role,
      roomNumber: incident.roomNumber,
      severity: incident.severity,
    },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'alarm.caf', badge: 1 } } },
  });
  
  logger.info('Escalation notification sent', { incidentId, role, tokenCount: tokens.length });
  
  // Log escalation in Firestore
  await firebaseService.addResponderLog(incidentId, {
    staffId: 'system',
    staffName: 'System',
    action: `Escalated to ${role} — no response from SECURITY in 3 minutes`,
    type: 'SYSTEM',
  });
}
