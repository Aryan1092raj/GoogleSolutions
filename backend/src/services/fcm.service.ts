import { getMessaging, getRtdb } from '../config/firebase-admin'; 
import { logger } from '../utils/logger'; 
 
function collectOnDutyTokens(staffMap: any) { 
  const tokens: string[] = []; 
  if (!staffMap) { 
    return tokens; 
  } 
  const values: any[] = Object.values(staffMap as any); 
  for (const member of values) { 
    if (!member) { continue; } 
    if (!member.isOnDuty) { continue; } 
    if (!member.fcmToken) { continue; } 
    tokens.push(String(member.fcmToken)); 
  } 
  return tokens; 
}
 
export async function alertAllStaff(hotelId: string, incident: any) { 
  const rtdb = getRtdb(); 
  const snapshot = await rtdb.ref('hotels/' + hotelId + '/staff_online').once('value'); 
  const staff = snapshot.val(); 
  const tokens = collectOnDutyTokens(staff); 
  if (tokens.length === 0) { 
    return; 
  } 
 
  await getMessaging().sendEachForMulticast({ 
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
  logger.warn('CRITICAL incident escalation', { incidentId: incidentId, aiSummary: aiSummary }); 
}
