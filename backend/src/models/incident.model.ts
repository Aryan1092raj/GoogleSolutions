import { z } from 'zod'; 
import { hazardSchema, hazardTypeSchema, type Hazard } from './hazard.model'; 
 
const incidentStatusValues = ['ACTIVE', 'ACKNOWLEDGED', 'RESOLVED', 'FALSE_ALARM'] as const; 
const incidentSeverityValues = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const; 
const responderLogTypeValues = ['NOTE', 'ACTION', 'SYSTEM'] as const; 
const aiStatusValues = ['PENDING', 'AVAILABLE', 'UNAVAILABLE', 'DEGRADED'] as const;
const actionHistoryTypeValues = ['STATUS', 'NOTE', 'AI', 'SYSTEM'] as const;
 
export type IncidentStatus = (typeof incidentStatusValues)[number]; 
export type IncidentSeverity = (typeof incidentSeverityValues)[number]; 
export type ResponderLogType = (typeof responderLogTypeValues)[number]; 
export type AiStatus = (typeof aiStatusValues)[number];
export type ActionHistoryType = (typeof actionHistoryTypeValues)[number];
 
export interface IncidentLocation { 
  floor: number; 
  wing: string; 
  roomNumber: string; 
  lat?: number; 
  lng?: number; 
  accuracyMeters?: number; 
} 
 
export interface ResponderLogEntry { 
  timestamp: unknown; 
  staffId: string; 
  staffName: string; 
  action: string; 
  type: ResponderLogType; 
} 

export interface ActionHistoryEntry {
  timestamp: unknown;
  actorId: string;
  actorLabel: string;
  type: ActionHistoryType;
  title: string;
  detail: string;
}
 
export interface Incident {
  incidentId: string;
  status: IncidentStatus;
  createdAt: unknown;
  updatedAt: unknown;
  resolvedAt?: unknown;
  guestId: string;
  guestName: string;
  guestPhone?: string;
  guestLanguage: string;
  roomNumber: string;
  hotelId: string;
  location: IncidentLocation;
  hazards: Hazard[];
  severity: IncidentSeverity;
  aiStatus: AiStatus;
  aiSummary: string;
  translatedTranscript: string;
  originalTranscript: string;
  detectedLanguage: string;
  streamSessionId: string;
  isStreamLive: boolean;
  recordingGcsPath?: string;
  acknowledgedBy?: string;
  etaMinutes?: number;
  etaSetAt?: string;
  responderLog: ResponderLogEntry[];
  actionHistory: ActionHistoryEntry[];
}

export interface LiveIncidentCard {
  incidentId: string;
  status: string;
  severity: string;
  roomNumber: string;
  floor: number;
  wing: string;
  guestName: string;
  primaryHazard: string;
  aiStatus: AiStatus;
  aiSummary: string;
  lastUpdatedMs: number;
  isStreamLive: boolean;
  acknowledgedBy?: string;
  etaMinutes?: number;
}

export interface StaffOnlineMember {
  name: string; 
  fcmToken: string; 
  lastSeenMs: number; 
  isOnDuty: boolean; 
} 
 
export interface StaffOnlineEntry { 
  [staffUid: string]: StaffOnlineMember; 
} 
 
export const incidentStatusSchema = z.enum(incidentStatusValues); 
export const incidentSeveritySchema = z.enum(incidentSeverityValues); 
export const responderLogTypeSchema = z.enum(responderLogTypeValues); 
export const aiStatusSchema = z.enum(aiStatusValues);
export const actionHistoryTypeSchema = z.enum(actionHistoryTypeValues);
 
export const incidentLocationSchema = z.object({ 
  floor: z.number(), 
  wing: z.string(), 
  roomNumber: z.string(), 
  lat: z.number().optional(), 
  lng: z.number().optional(), 
  accuracyMeters: z.number().optional(), 
}); 
 
export const responderLogEntrySchema = z.object({ 
  timestamp: z.unknown(), 
  staffId: z.string(), 
  staffName: z.string(), 
  action: z.string(), 
  type: responderLogTypeSchema, 
});

export const actionHistoryEntrySchema = z.object({
  timestamp: z.unknown(),
  actorId: z.string(),
  actorLabel: z.string(),
  type: actionHistoryTypeSchema,
  title: z.string(),
  detail: z.string(),
});
 
export const incidentSchema = z.object({ 
  incidentId: z.string(), 
  status: incidentStatusSchema, 
  createdAt: z.unknown(), 
  updatedAt: z.unknown(), 
  resolvedAt: z.unknown().optional(), 
  guestId: z.string(), 
  guestName: z.string(), 
  guestPhone: z.string().optional(), 
  guestLanguage: z.string(), 
  roomNumber: z.string(), 
  hotelId: z.string(), 
  location: incidentLocationSchema, 
  hazards: z.array(hazardSchema), 
  severity: incidentSeveritySchema, 
  aiStatus: aiStatusSchema,
  aiSummary: z.string(), 
  translatedTranscript: z.string(), 
  originalTranscript: z.string(), 
  detectedLanguage: z.string(), 
  streamSessionId: z.string(), 
  isStreamLive: z.boolean(), 
  recordingGcsPath: z.string().optional(), 
  acknowledgedBy: z.string().optional(), 
  responderLog: z.array(responderLogEntrySchema), 
  actionHistory: z.array(actionHistoryEntrySchema),
}); 
 
export const liveIncidentCardSchema = z.object({ 
  incidentId: z.string(), 
  status: z.string(), 
  severity: z.string(), 
  roomNumber: z.string(), 
  floor: z.number(), 
  wing: z.string(), 
  guestName: z.string(), 
  primaryHazard: hazardTypeSchema, 
  aiStatus: aiStatusSchema,
  aiSummary: z.string(), 
  lastUpdatedMs: z.number(), 
  isStreamLive: z.boolean(), 
  acknowledgedBy: z.string().optional(), 
}); 
 
export const staffOnlineMemberSchema = z.object({ 
  name: z.string(), 
  fcmToken: z.string(), 
  lastSeenMs: z.number(), 
  isOnDuty: z.boolean(), 
}); 
 
export const staffOnlineEntrySchema = z.record(staffOnlineMemberSchema);
