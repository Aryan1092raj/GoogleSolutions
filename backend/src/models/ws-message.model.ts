import { z } from 'zod'; 
 
const devicePlatformValues = ['android', 'ios'] as const; 
const mimeTypeVideoValues = ['video/webm', 'video/mp4', 'image/jpeg'] as const; 
const mimeTypeAudioValues = ['audio/pcm', 'audio/wav'] as const; 
const sosEndReasonValues = ['RESOLVED_BY_GUEST', 'FALSE_ALARM'] as const; 
 
export type DevicePlatform = (typeof devicePlatformValues)[number]; 
export type MimeTypeVideo = (typeof mimeTypeVideoValues)[number]; 
export type MimeTypeAudio = (typeof mimeTypeAudioValues)[number]; 
export type SosEndReason = (typeof sosEndReasonValues)[number]; 
 
export interface SOS_INIT { 
  type: 'SOS_INIT'; 
  payload: { 
    incidentId: string; 
    guestId: string; 
    guestName: string; 
    guestLanguage: string; 
    hotelId: string; 
    roomNumber: string; 
    floor: number; 
    wing: string; 
    lat?: number; 
    lng?: number; 
    deviceInfo: { 
      platform: DevicePlatform; 
      osVersion: string; 
    }; 
  }; 
} 
 
export interface MEDIA_CHUNK { 
  type: 'MEDIA_CHUNK'; 
  payload: { 
    incidentId: string; 
    chunkIndex: number; 
    timestampMs: number; 
    video?: string; 
    audio?: string; 
    mimeTypeVideo: MimeTypeVideo; 
    mimeTypeAudio: MimeTypeAudio; 
  }; 
}
 
export interface LOCATION_UPDATE { 
  type: 'LOCATION_UPDATE'; 
  payload: { 
    incidentId: string; 
    lat: number; 
    lng: number; 
    accuracyMeters: number; 
    floor?: number; 
  }; 
} 
 
export interface SOS_END { 
  type: 'SOS_END'; 
  payload: { 
    incidentId: string; 
    reason: SosEndReason; 
  }; 
} 
 
export interface WS_PING { 
  type: 'WS_PING'; 
  payload: { 
    ts: number; 
  }; 
} 
 
export interface AI_STATUS { 
  type: 'AI_STATUS'; 
  payload: { 
    incidentId: string; 
    message: string; 
    severity: string; 
    helpOnWay: boolean; 
    estimatedArrivalMin?: number; 
  }; 
} 
 
export interface SOS_ACCEPTED { 
  type: 'SOS_ACCEPTED'; 
  payload: { 
    incidentId: string; 
    message: string; 
  }; 
} 
 
export interface INCIDENT_RESOLVED { 
  type: 'INCIDENT_RESOLVED'; 
  payload: { 
    incidentId: string; 
    resolvedBy: string; 
    message: string; 
  }; 
} 
 
export interface WS_PONG { 
  type: 'WS_PONG'; 
  payload: { 
    ts: number; 
  }; 
} 
 
export interface WS_ERROR { 
  type: 'WS_ERROR'; 
  payload: { 
    code: string; 
    message: string; 
    retryable: boolean; 
  }; 
} 
 
export const devicePlatformSchema = z.enum(devicePlatformValues); 
export const mimeTypeVideoSchema = z.enum(mimeTypeVideoValues); 
export const mimeTypeAudioSchema = z.enum(mimeTypeAudioValues); 
export const sosEndReasonSchema = z.enum(sosEndReasonValues);
 
export const sosInitMessageSchema = z.object({ 
  type: z.literal('SOS_INIT'), 
  payload: z.object({ 
    incidentId: z.string(), 
    guestId: z.string(), 
    guestName: z.string(), 
    guestLanguage: z.string(), 
    hotelId: z.string(), 
    roomNumber: z.string(), 
    floor: z.number(), 
    wing: z.string(), 
    lat: z.number().optional(), 
    lng: z.number().optional(), 
    deviceInfo: z.object({ 
      platform: devicePlatformSchema, 
      osVersion: z.string(), 
    }), 
  }), 
}); 
 
export const mediaChunkMessageSchema = z.object({ 
  type: z.literal('MEDIA_CHUNK'), 
  payload: z.object({ 
    incidentId: z.string(), 
    chunkIndex: z.number().int().min(0), 
    timestampMs: z.number().int(), 
    video: z.string().optional(), 
    audio: z.string().optional(), 
    mimeTypeVideo: mimeTypeVideoSchema, 
    mimeTypeAudio: mimeTypeAudioSchema, 
  }), 
}); 
 
export const locationUpdateMessageSchema = z.object({ 
  type: z.literal('LOCATION_UPDATE'), 
  payload: z.object({ 
    incidentId: z.string(), 
    lat: z.number(), 
    lng: z.number(), 
    accuracyMeters: z.number(), 
    floor: z.number().optional(), 
  }), 
}); 
 
export const sosEndMessageSchema = z.object({ 
  type: z.literal('SOS_END'), 
  payload: z.object({ 
    incidentId: z.string(), 
    reason: sosEndReasonSchema, 
  }), 
}); 
 
export const wsPingMessageSchema = z.object({ 
  type: z.literal('WS_PING'), 
  payload: z.object({ 
    ts: z.number(), 
  }), 
});
 
export const aiStatusMessageSchema = z.object({ 
  type: z.literal('AI_STATUS'), 
  payload: z.object({ 
    incidentId: z.string(), 
    message: z.string(), 
    severity: z.string(), 
    helpOnWay: z.boolean(), 
    estimatedArrivalMin: z.number().optional(), 
  }), 
}); 
 
export const sosAcceptedMessageSchema = z.object({ 
  type: z.literal('SOS_ACCEPTED'), 
  payload: z.object({ 
    incidentId: z.string(), 
    message: z.string(), 
  }), 
}); 
 
export const incidentResolvedMessageSchema = z.object({ 
  type: z.literal('INCIDENT_RESOLVED'), 
  payload: z.object({ 
    incidentId: z.string(), 
    resolvedBy: z.string(), 
    message: z.string(), 
  }), 
}); 
 
export const wsPongMessageSchema = z.object({ 
  type: z.literal('WS_PONG'), 
  payload: z.object({ 
    ts: z.number(), 
  }), 
}); 
 
export const wsErrorMessageSchema = z.object({ 
  type: z.literal('WS_ERROR'), 
  payload: z.object({ 
    code: z.string(), 
    message: z.string(), 
    retryable: z.boolean(), 
  }), 
}); 
 
export const guestToBackendMessageSchema = z.discriminatedUnion('type', [ 
  sosInitMessageSchema, 
  mediaChunkMessageSchema, 
  locationUpdateMessageSchema, 
  sosEndMessageSchema, 
  wsPingMessageSchema, 
]); 
 
export const backendToGuestMessageSchema = z.discriminatedUnion('type', [ 
  aiStatusMessageSchema, 
  sosAcceptedMessageSchema, 
  incidentResolvedMessageSchema, 
  wsPongMessageSchema, 
  wsErrorMessageSchema, 
]);
