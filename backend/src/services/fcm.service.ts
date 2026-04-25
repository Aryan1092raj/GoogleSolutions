import { getMessaging, getRtdb } from '../config/firebase-admin';
import * as firebaseService from './firebase.service';
import { logger } from '../utils/logger';

function collectOnDutyTokens(staffMap: any): string[] {
  const tokens: string[] = [];
  if (!staffMap) {
    return tokens;
  }

  const values: any[] = Object.values(staffMap as any);
  for (const member of values) {
    if (!member) {
      continue;
    }
    if (!member.isOnDuty) {
      continue;
    }
    if (!member.fcmToken) {
      continue;
    }
    tokens.push(String(member.fcmToken));
  }

  return Array.from(new Set(tokens));
}

async function getHotelStaffTokens(hotelId: string): Promise<string[]> {
  const rtdb = getRtdb();
  const snapshot = await rtdb.ref('hotels/' + hotelId + '/staff_online').once('value');
  return collectOnDutyTokens(snapshot.val());
}

export async function alertAllStaff(hotelId: string, incident: any) {
  const tokens = await getHotelStaffTokens(hotelId);
  if (tokens.length === 0) {
    return;
  }

  await getMessaging().sendMulticast({
    tokens: tokens,
    notification: {
      title: 'SOS ALERT - ResQLink',
      body: 'Room ' + incident.roomNumber + ' - ' + incident.location.wing + ' - ' + incident.severity,
    },
    data: {
      incidentId: String(incident.incidentId),
      type: 'SOS_ALERT',
      floor: String(incident.location.floor),
    },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'alarm.caf', badge: 1 } } },
  });
}

export async function sendCriticalAlert(incidentId: string, aiSummary: string) {
  const incident = await firebaseService.getIncidentById(incidentId);
  if (!incident) {
    logger.warn('sendCriticalAlert skipped: incident not found', { incidentId });
    return;
  }

  const tokens = await getHotelStaffTokens(String(incident.hotelId));
  if (tokens.length === 0) {
    logger.warn('sendCriticalAlert skipped: no staff tokens', { incidentId, hotelId: incident.hotelId });
    return;
  }

  await getMessaging().sendMulticast({
    tokens,
    notification: {
      title: 'CRITICAL ALERT - ResQLink',
      body: aiSummary,
    },
    data: {
      incidentId: String(incidentId),
      type: 'CRITICAL_ALERT',
      severity: 'CRITICAL',
    },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'alarm.caf', badge: 1 } } },
  });
}
