# ARCHITECTURE.md — ResQLink: Agentic Hotel Emergency Response System
> GDG Solution Challenge 2026 | Build with AI
> Stack: Flutter · Gemini 2.0 Flash (Multimodal Live API) · Vertex AI · Firebase · Google Cloud Run

---

## 0. Document Purpose

This document is the **single source of truth** for an AI agent (Codex / Cursor / Claude) to build
the ResQLink system from scratch. Every service, endpoint, schema, data model, screen, state
variable, and environment variable is defined here. No ambiguity is intentional.

---

## 1. High-Level System Overview

```
┌───────────────────────────────────────────────────────────────────────────┐
│                          ResQLink System                                   │
│                                                                            │
│   [Guest Mobile App]          [Backend Orchestrator]    [Dashboard Web]   │
│   Flutter (Android/iOS)  ──►  Cloud Run (Node.js)  ──►  Flutter Web       │
│        │                           │    │                    │             │
│   Camera + Mic Stream              │    │            Firebase Realtime     │
│        │                           │    │                    │             │
│        └──── WebSocket ────────────┘    │            (live sync to all     │
│                                         │             security terminals)  │
│                               Vertex AI │                                  │
│                           Gemini 2.0    │                                  │
│                           Flash Live ───┘                                  │
│                           API                                              │
│                                                                            │
│                    Firebase Auth · Firestore · Realtime DB · FCM           │
└───────────────────────────────────────────────────────────────────────────┘
```

### System Components

| Component | Technology | Role |
|---|---|---|
| Guest Mobile App | Flutter (Android + iOS) | SOS trigger, AV stream, location share |
| Security Dashboard | Flutter Web | Live incident view, multi-feed, command log |
| Backend Orchestrator | Node.js 20 on Google Cloud Run | WebSocket hub, Gemini proxy, Firebase writes |
| AI Engine | Gemini 2.0 Flash via Vertex AI | Live video/audio analysis, hazard detection, translation |
| Realtime Sync | Firebase Realtime Database | Push hazard cards to all dashboards in <200ms |
| Incident Store | Cloud Firestore | Persistent incident records, audit trail |
| Auth | Firebase Authentication | Hotel staff (email), guests (anonymous + profile) |
| Push Alerts | Firebase Cloud Messaging (FCM) | Alert nearby staff devices |
| Storage | Google Cloud Storage | Save SOS video recordings for post-incident review |

---

## 2. Repository Structure

```
resqlink/
├── mobile/                          # Flutter mobile app (guest)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── constants.dart       # API URLs, Firebase config keys
│   │   │   ├── router.dart          # GoRouter setup
│   │   │   └── theme.dart
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── screens/         # guest_checkin_screen.dart
│   │   │   │   └── providers/       # auth_provider.dart
│   │   │   ├── sos/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── sos_home_screen.dart
│   │   │   │   │   ├── sos_active_screen.dart
│   │   │   │   │   └── sos_resolved_screen.dart
│   │   │   │   ├── providers/
│   │   │   │   │   ├── sos_provider.dart
│   │   │   │   │   └── stream_provider.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── sos_trigger_button.dart
│   │   │   │       ├── camera_preview_widget.dart
│   │   │   │       └── status_indicator.dart
│   │   │   └── profile/
│   │   │       └── screens/guest_profile_screen.dart
│   │   └── services/
│   │       ├── websocket_service.dart
│   │       ├── camera_service.dart
│   │       ├── location_service.dart
│   │       └── firebase_service.dart
│   └── pubspec.yaml
│
├── dashboard/                       # Flutter Web dashboard (security staff)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   └── screens/staff_login_screen.dart
│   │   │   ├── command/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── command_center_screen.dart
│   │   │   │   │   └── incident_detail_screen.dart
│   │   │   │   ├── providers/
│   │   │   │   │   └── incident_provider.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── incident_card.dart
│   │   │   │       ├── hazard_tag.dart
│   │   │   │       ├── live_feed_tile.dart
│   │   │   │       └── responder_log.dart
│   │   └── services/
│   │       └── firebase_service.dart
│   └── pubspec.yaml
│
├── backend/                         # Node.js Cloud Run service
│   ├── src/
│   │   ├── index.ts                 # Express app entry
│   │   ├── config/
│   │   │   └── firebase-admin.ts
│   │   ├── routes/
│   │   │   ├── auth.routes.ts       # POST /api/auth/guest-token
│   │   │   ├── incident.routes.ts   # POST /api/incidents, GET /api/incidents/:id
│   │   │   └── health.routes.ts     # GET /health
│   │   ├── websocket/
│   │   │   ├── ws-server.ts         # ws WebSocket server setup
│   │   │   ├── sos-handler.ts       # Handles SOS_INIT, MEDIA_CHUNK, SOS_END events
│   │   │   └── gemini-bridge.ts     # Opens Vertex AI Live API session, pipes media
│   │   ├── services/
│   │   │   ├── gemini.service.ts    # Vertex AI client, streaming session manager
│   │   │   ├── firebase.service.ts  # Firestore + Realtime DB writes
│   │   │   ├── fcm.service.ts       # FCM push notifications
│   │   │   └── storage.service.ts   # GCS video chunk upload
│   │   ├── models/
│   │   │   ├── incident.model.ts
│   │   │   ├── hazard.model.ts
│   │   │   └── ws-message.model.ts
│   │   └── utils/
│   │       ├── logger.ts
│   │       └── retry.ts
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
│
├── infra/                           # Infrastructure as Code
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── firebase/
│       └── firestore.rules
│
└── docs/
    ├── ARCHITECTURE.md              # THIS FILE
    └── API.md
```

---

## 3. Environment Variables

### 3.1 Backend (`backend/.env`)
```env
# Google Cloud
GOOGLE_CLOUD_PROJECT=resqlink-prod
GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcp-sa-key.json
VERTEX_AI_LOCATION=us-central1

# Gemini
GEMINI_MODEL=gemini-2.0-flash-live-001
GEMINI_SYSTEM_PROMPT="You are ResQLink AI Dispatcher, an emergency analysis agent..."

# Firebase Admin
FIREBASE_DATABASE_URL=https://resqlink-prod-default-rtdb.firebaseio.com

# Server
PORT=8080
WS_HEARTBEAT_INTERVAL_MS=30000
MAX_MEDIA_CHUNK_BYTES=65536

# GCS
GCS_BUCKET=resqlink-sos-recordings
VIDEO_SEGMENT_DURATION_SEC=10
```

### 3.2 Mobile App (`mobile/lib/core/constants.dart`)
```dart
class AppConstants {
  // Backend
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://resqlink-backend-xxxx-uc.a.run.app',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://resqlink-backend-xxxx-uc.a.run.app/ws',
  );

  // Firebase (loaded from google-services.json / GoogleService-Info.plist)
  // No hard-coded keys here.

  // SOS
  static const int videoWidthPx = 640;
  static const int videoHeightPx = 480;
  static const int videoFps = 15;
  static const int audioSampleRate = 16000;
  static const int mediaChunkIntervalMs = 500;
}
```

### 3.3 Dashboard (`dashboard/lib/core/constants.dart`)
```dart
class DashboardConstants {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://resqlink-backend-xxxx-uc.a.run.app',
  );
  static const String firebaseRtdbUrl =
      'https://resqlink-prod-default-rtdb.firebaseio.com';
}
```

---

## 4. Data Models

### 4.1 Firestore: `incidents` Collection

**Path:** `/incidents/{incidentId}`

```typescript
interface Incident {
  incidentId: string;               // Auto-generated Firestore doc ID
  status: 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED' | 'FALSE_ALARM';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  resolvedAt?: Timestamp;

  // Guest info
  guestId: string;                  // Firebase Auth UID (anonymous)
  guestName: string;                // Provided at check-in
  guestPhone?: string;
  guestLanguage: string;            // ISO 639-1, e.g. 'hi', 'en', 'pa'
  roomNumber: string;               // e.g. "412"
  hotelId: string;                  // e.g. "hotel_grand_mandi_01"

  // Location
  location: {
    floor: number;
    wing: string;                   // e.g. "East Wing"
    roomNumber: string;
    lat?: number;
    lng?: number;
    accuracyMeters?: number;
  };

  // AI Analysis (updated in real-time by backend)
  hazards: Hazard[];
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  aiSummary: string;                // English summary from Gemini
  translatedTranscript: string;     // Guest speech translated to English
  originalTranscript: string;       // Guest speech in original language
  detectedLanguage: string;

  // Stream
  streamSessionId: string;          // WebSocket session ID
  isStreamLive: boolean;
  recordingGcsPath?: string;        // gs://resqlink-sos-recordings/{incidentId}/

  // Responder
  acknowledgedBy?: string;          // Staff Firebase UID
  responderLog: ResponderLogEntry[];
}

interface Hazard {
  type: 'FIRE' | 'SMOKE' | 'MEDICAL' | 'SECURITY_THREAT' |
        'STRUCTURAL_DAMAGE' | 'FLOOD' | 'UNKNOWN';
  confidence: number;               // 0.0 – 1.0
  description: string;              // e.g. "Smoke visible near left wall"
  detectedAt: Timestamp;
}

interface ResponderLogEntry {
  timestamp: Timestamp;
  staffId: string;
  staffName: string;
  action: string;                   // e.g. "Dispatched fire team to Floor 4"
  type: 'NOTE' | 'ACTION' | 'SYSTEM';
}
```

### 4.2 Firebase Realtime Database: Live Hazard Cards

**Path:** `/live_incidents/{hotelId}/{incidentId}`

> This is the **hot path** — written by the backend on every Gemini analysis event.
> Dashboard clients subscribe here for <200ms latency updates.

```typescript
interface LiveIncidentCard {
  incidentId: string;
  status: string;
  severity: string;
  roomNumber: string;
  floor: number;
  wing: string;
  guestName: string;
  primaryHazard: string;            // e.g. "FIRE"
  aiSummary: string;                // last Gemini summary
  lastUpdatedMs: number;            // epoch ms
  isStreamLive: boolean;
  acknowledgedBy?: string;
}
```

**Path:** `/hotels/{hotelId}/staff_online`

```typescript
interface StaffOnlineEntry {
  [staffUid: string]: {
    name: string;
    fcmToken: string;
    lastSeenMs: number;
    isOnDuty: boolean;
  }
}
```

### 4.3 WebSocket Message Protocol

All WebSocket messages are JSON with a `type` discriminator.

#### Guest → Backend Messages

```typescript
// 1. Initiate SOS session
interface SOS_INIT {
  type: 'SOS_INIT';
  payload: {
    incidentId: string;             // Pre-generated UUID by app
    guestId: string;
    guestName: string;
    guestLanguage: string;          // ISO 639-1
    hotelId: string;
    roomNumber: string;
    floor: number;
    wing: string;
    lat?: number;
    lng?: number;
    deviceInfo: {
      platform: 'android' | 'ios';
      osVersion: string;
    };
  };
}

// 2. Media chunk (raw bytes encoded as base64)
interface MEDIA_CHUNK {
  type: 'MEDIA_CHUNK';
  payload: {
    incidentId: string;
    chunkIndex: number;
    timestampMs: number;
    video?: string;                 // base64-encoded H.264 keyframe or I-frame
    audio?: string;                 // base64-encoded PCM 16kHz mono
    mimeTypeVideo: 'video/webm' | 'video/mp4';
    mimeTypeAudio: 'audio/pcm';
  };
}

// 3. Location update (sent every 10s)
interface LOCATION_UPDATE {
  type: 'LOCATION_UPDATE';
  payload: {
    incidentId: string;
    lat: number;
    lng: number;
    accuracyMeters: number;
    floor?: number;
  };
}

// 4. Guest-initiated end (panic resolved or false alarm)
interface SOS_END {
  type: 'SOS_END';
  payload: {
    incidentId: string;
    reason: 'RESOLVED_BY_GUEST' | 'FALSE_ALARM';
  };
}

// 5. Ping (keep-alive)
interface WS_PING {
  type: 'WS_PING';
  payload: { ts: number; };
}
```

#### Backend → Guest Messages

```typescript
// AI status acknowledgement
interface AI_STATUS {
  type: 'AI_STATUS';
  payload: {
    incidentId: string;
    message: string;                // Calming message to guest in their language
    severity: string;
    helpOnWay: boolean;
    estimatedArrivalMin?: number;
  };
}

// SOS accepted confirmation
interface SOS_ACCEPTED {
  type: 'SOS_ACCEPTED';
  payload: {
    incidentId: string;
    message: string;
  };
}

// Incident resolved from dashboard
interface INCIDENT_RESOLVED {
  type: 'INCIDENT_RESOLVED';
  payload: {
    incidentId: string;
    resolvedBy: string;
    message: string;
  };
}

interface WS_PONG {
  type: 'WS_PONG';
  payload: { ts: number; };
}

interface WS_ERROR {
  type: 'WS_ERROR';
  payload: {
    code: string;                   // e.g. 'SESSION_EXPIRED', 'GEMINI_UNAVAILABLE'
    message: string;
    retryable: boolean;
  };
}
```

---

## 5. Backend API Endpoints

Base URL: `https://resqlink-backend-xxxx-uc.a.run.app`

All REST endpoints require `Authorization: Bearer <firebase_id_token>` header
unless marked `[public]`.

### 5.1 Health Check

```
GET /health  [public]

Response 200:
{
  "status": "ok",
  "version": "1.0.0",
  "geminiReady": true
}
```

### 5.2 Auth

```
POST /api/auth/guest-token  [public]

Request Body:
{
  "hotelId": "hotel_grand_mandi_01",
  "roomNumber": "412",
  "guestName": "Rahul Sharma",
  "language": "hi"
}

Response 200:
{
  "customToken": "<firebase_custom_token>",
  "guestId": "<uid>",
  "expiresIn": 3600
}

Errors:
  400: Missing required field
  404: Hotel not found
```

```
POST /api/auth/staff-login  [public]

Request Body:
{
  "email": "security@hotel.com",
  "password": "..."
}
→ Delegates to Firebase Admin signInWithEmailAndPassword pattern.
  Returns Firebase ID token via Firebase Auth REST API.

Response 200:
{
  "idToken": "<firebase_id_token>",
  "staffId": "<uid>",
  "hotelId": "hotel_grand_mandi_01",
  "role": "SECURITY" | "MANAGER" | "FIRST_RESPONDER"
}
```

### 5.3 Incidents

```
POST /api/incidents

Request Body:
{
  "incidentId": "uuid-v4",          // Pre-generated by client
  "hotelId": "hotel_grand_mandi_01",
  "roomNumber": "412",
  "floor": 4,
  "wing": "East Wing",
  "guestId": "<uid>",
  "guestName": "Rahul Sharma",
  "guestLanguage": "hi",
  "lat": 31.7048,
  "lng": 76.9301
}

Response 201:
{
  "incidentId": "uuid-v4",
  "status": "ACTIVE",
  "wsToken": "<short-lived JWT for WS auth>",
  "message": "SOS received. Help is being dispatched."
}

Errors:
  400: Validation failed
  409: Incident with this ID already exists
  503: Gemini service unavailable
```

```
GET /api/incidents/:incidentId

Response 200: Full Incident object (see Data Models §4.1)

Errors:
  403: Requester not in same hotelId
  404: Not found
```

```
PATCH /api/incidents/:incidentId/status

Request Body:
{
  "status": "ACKNOWLEDGED" | "RESOLVED" | "FALSE_ALARM",
  "note": "Fire team dispatched to floor 4"
}

Response 200:
{
  "incidentId": "...",
  "status": "ACKNOWLEDGED",
  "updatedAt": "ISO8601"
}
```

```
POST /api/incidents/:incidentId/log

Request Body:
{
  "action": "Dispatched paramedics to room 412",
  "type": "ACTION"
}

Response 201:
{
  "logEntryId": "...",
  "timestamp": "ISO8601"
}
```

```
GET /api/incidents?hotelId=hotel_grand_mandi_01&status=ACTIVE

Response 200:
{
  "incidents": [ ...Incident[] ],
  "total": 2
}
```

### 5.4 WebSocket Endpoint

```
WS /ws?token=<wsToken>&incidentId=<uuid>

Upgrade: websocket
Connection: Upgrade
```

The `wsToken` is the short-lived JWT returned by `POST /api/incidents`.
Expires in 5 minutes. After upgrade, all messages follow the protocol in §4.3.

---

## 6. Backend Internal Logic

### 6.1 WebSocket Server (`ws-server.ts`)

```typescript
// Pseudo-code for the core WS connection handler

onConnection(ws, req) {
  1. Parse & verify wsToken from query string (JWT, RS256, 5min TTL)
  2. Extract incidentId from token claims
  3. Register ws in sessionMap[incidentId]
  4. Set up heartbeat timer (ping every 30s; close if no pong in 10s)
  5. Forward to sos-handler.ts
}
```

### 6.2 SOS Handler (`sos-handler.ts`)

```typescript
onMessage(ws, rawMessage) {
  const msg = JSON.parse(rawMessage)

  switch (msg.type) {
    case 'SOS_INIT':
      1. Create Firestore incident document (status: ACTIVE)
      2. Write LiveIncidentCard to Realtime DB
      3. Open Gemini Live API session via gemini-bridge.ts
      4. Trigger FCM push to all staff in hotelId (see §6.4)
      5. Send SOS_ACCEPTED back to guest ws

    case 'MEDIA_CHUNK':
      1. Decode base64 video/audio
      2. Forward raw bytes to Gemini session via gemini-bridge.ts
      3. Append chunk to GCS buffer for recording

    case 'LOCATION_UPDATE':
      1. Update Firestore incident.location
      2. Update RTDB LiveIncidentCard

    case 'SOS_END':
      1. Close Gemini session
      2. Update Firestore status → RESOLVED / FALSE_ALARM
      3. Update RTDB LiveIncidentCard
      4. Finalize GCS recording (flush buffer, set metadata)
      5. Send INCIDENT_RESOLVED to guest ws

    case 'WS_PING':
      Send WS_PONG
  }
}
```

### 6.3 Gemini Bridge (`gemini-bridge.ts`)

```typescript
// Uses @google-cloud/vertexai SDK

async function openGeminiSession(incidentId: string, guestLanguage: string) {
  const client = new VertexAI({ project, location })
  const model = client.getGenerativeModel({
    model: GEMINI_MODEL,   // 'gemini-2.0-flash-live-001'
    systemInstruction: buildSystemPrompt(guestLanguage),
  })

  // Open bidirectional Live API stream
  const session = await model.startChat({ stream: true })
  geminiSessions[incidentId] = session

  // Listen for AI responses
  session.onMessage((response) => {
    parseGeminiResponse(response, incidentId)
  })
}

function buildSystemPrompt(lang: string): string {
  return `
    You are ResQLink AI Dispatcher — an autonomous emergency analysis agent.
    Your job:
    1. Analyze incoming live video frames and audio in real-time.
    2. Detect hazards: fire, smoke, medical emergency, weapons, structural damage, flood.
    3. Assess severity: LOW / MEDIUM / HIGH / CRITICAL.
    4. Extract key facts: exact location cues, number of people affected, visible injuries.
    5. Output a structured JSON response every 3 seconds with this exact schema:
    {
      "hazards": [{ "type": "...", "confidence": 0.0-1.0, "description": "..." }],
      "severity": "...",
      "aiSummary": "One sentence English summary for responders",
      "translatedTranscript": "English translation of guest speech",
      "originalTranscript": "Guest speech as heard",
      "detectedLanguage": "ISO 639-1",
      "guestCalm": "A short calming message in ${lang} to reassure the guest"
    }
    IMPORTANT: Always output ONLY valid JSON. No markdown. No preamble.
    Guest primary language is: ${lang}
  `
}

async function sendMediaToGemini(incidentId: string, chunk: MediaChunk) {
  const session = geminiSessions[incidentId]
  if (!session) return

  const parts = []
  if (chunk.video) parts.push({ inlineData: { data: chunk.video, mimeType: chunk.mimeTypeVideo } })
  if (chunk.audio) parts.push({ inlineData: { data: chunk.audio, mimeType: chunk.mimeTypeAudio } })

  await session.sendMessage({ role: 'user', parts })
}

function parseGeminiResponse(response: GenerateContentResponse, incidentId: string) {
  try {
    const text = response.candidates[0].content.parts[0].text
    const analysis = JSON.parse(text)  // Structured JSON per system prompt

    // 1. Update Firestore incident document
    firebaseService.updateIncidentAnalysis(incidentId, analysis)

    // 2. Push live update to RTDB (triggers dashboard update)
    firebaseService.updateLiveCard(incidentId, analysis)

    // 3. Send calm message back to guest over WebSocket
    wsServer.sendToGuest(incidentId, {
      type: 'AI_STATUS',
      payload: {
        incidentId,
        message: analysis.guestCalm,
        severity: analysis.severity,
        helpOnWay: true,
      }
    })

    // 4. Escalate FCM if severity jumps to CRITICAL
    if (analysis.severity === 'CRITICAL') {
      fcmService.sendCriticalAlert(incidentId, analysis.aiSummary)
    }
  } catch (e) {
    logger.error('Gemini parse error', { incidentId, error: e })
  }
}
```

### 6.4 FCM Service (`fcm.service.ts`)

```typescript
async function alertAllStaff(hotelId: string, incident: Incident) {
  // Fetch all staff FCM tokens from RTDB /hotels/{hotelId}/staff_online
  const snapshot = await rtdb.ref(`hotels/${hotelId}/staff_online`).once('value')
  const staff = snapshot.val()
  const tokens = Object.values(staff)
    .filter((s: any) => s.isOnDuty)
    .map((s: any) => s.fcmToken)

  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: '🚨 SOS ALERT — ResQLink',
      body: `Room ${incident.roomNumber} · ${incident.location.wing} · ${incident.severity}`,
    },
    data: {
      incidentId: incident.incidentId,
      type: 'SOS_ALERT',
      floor: String(incident.location.floor),
    },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'alarm.caf', badge: 1 } } },
  })
}
```

---

## 7. Flutter Mobile App

### 7.1 Screens and Navigation (GoRouter)

```
/                      → SplashScreen (check auth state)
/checkin               → GuestCheckinScreen
/home                  → SOSHomeScreen (idle state)
/sos/active/:id        → SOSActiveScreen (streaming)
/sos/resolved/:id      → SOSResolvedScreen
/profile               → GuestProfileScreen
```

### 7.2 State Management: Riverpod Providers

```dart
// auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final guestProfileProvider = StateNotifierProvider<GuestProfileNotifier, GuestProfile?>(...);
```

```dart
// sos_provider.dart
enum SOSStatus { idle, initiating, active, resolving, resolved, error }

class SOSState {
  final SOSStatus status;
  final String? incidentId;
  final String? aiMessage;         // Latest calm message from AI
  final String? severity;
  final bool helpOnWay;
  final String? error;
}

class SOSNotifier extends StateNotifier<SOSState> {
  final WebSocketService _ws;
  final CameraService _camera;
  final LocationService _location;
  final Ref _ref;

  Future<void> triggerSOS() async { ... }
  Future<void> endSOS(String reason) async { ... }
  void _handleWsMessage(Map<String, dynamic> msg) { ... }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>(...);
```

```dart
// stream_provider.dart
// Manages camera + microphone streaming
class StreamNotifier extends StateNotifier<StreamState> {
  Timer? _chunkTimer;

  void startStreaming(String incidentId) {
    _camera.startCapture();
    _chunkTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.mediaChunkIntervalMs),
      (_) => _captureAndSend(incidentId),
    );
  }

  Future<void> _captureAndSend(String incidentId) async {
    final videoFrame = await _camera.captureFrame();  // returns base64 H.264 keyframe
    final audioChunk = await _camera.captureAudio();   // returns base64 PCM
    _ws.sendMediaChunk(incidentId, videoFrame, audioChunk);
  }
}
```

### 7.3 Camera Service (`camera_service.dart`)

```dart
class CameraService {
  CameraController? _controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,   // ~640x480
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();
  }

  // Returns base64-encoded JPEG frame (for Gemini inline image input)
  Future<String> captureFrame() async {
    final XFile file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // Returns base64-encoded raw PCM audio
  Future<String> captureAudio() async { ... }

  Widget buildPreview() => CameraPreview(_controller!);
}
```

### 7.4 WebSocket Service (`websocket_service.dart`)

```dart
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect(String wsToken, String incidentId) async {
    final uri = Uri.parse(
      '${AppConstants.wsUrl}?token=$wsToken&incidentId=$incidentId'
    );
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) => _messageController.add(jsonDecode(data)),
      onError: (e) => _messageController.addError(e),
      onDone: () => _onDisconnected(),
    );
  }

  void sendSOSInit(SOSInitPayload payload) {
    _send({ 'type': 'SOS_INIT', 'payload': payload.toJson() });
  }

  void sendMediaChunk(String incidentId, String? videoB64, String? audioB64) {
    _send({
      'type': 'MEDIA_CHUNK',
      'payload': {
        'incidentId': incidentId,
        'chunkIndex': _chunkIndex++,
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
        'video': videoB64,
        'audio': audioB64,
        'mimeTypeVideo': 'video/webm',
        'mimeTypeAudio': 'audio/pcm',
      }
    });
  }

  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  // Exponential backoff reconnect
  void _onDisconnected() {
    Future.delayed(Duration(seconds: 2), () => reconnect());
  }
}
```

### 7.5 Key Screens

#### `SOSHomeScreen`
- Large centered SOS button (red, 160px diameter, pulsing animation)
- Hotel name + room number shown as subtitle
- "Hold for 2 seconds to trigger emergency" instruction
- Language selector (for accessibility)

#### `SOSActiveScreen`
- Full-screen camera preview (CameraPreview widget)
- Animated AI status card overlay at bottom:
  - Severity badge (color-coded)
  - AI message in guest's language
  - "Help is on the way" indicator
- "End SOS" button (bottom corner, gray, confirmation dialog required)
- Live blinking red indicator top-right

#### `SOSResolvedScreen`
- Confirmation that help has been dispatched or issue resolved
- Incident ID for reference
- "Return to Home" CTA

---

## 8. Flutter Web Dashboard

### 8.1 Screens and Navigation

```
/login           → StaffLoginScreen
/dashboard       → CommandCenterScreen  (main view, real-time)
/incident/:id    → IncidentDetailScreen
```

### 8.2 CommandCenterScreen Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  ResQLink Dashboard  |  Hotel: Grand Mandi  |  2 ACTIVE  [STAFF] │
├───────────────┬──────────────────────────────────────────────────┤
│  ACTIVE SOSes │  Selected Incident Detail                        │
│               │                                                   │
│  ┌──────────┐ │  ┌─────────────────────┐  ┌──────────────────┐  │
│  │ INCIDENT │ │  │  LIVE VIDEO FEED     │  │  AI ANALYSIS     │  │
│  │  #001    │ │  │  (camera stream via  │  │                  │  │
│  │ 🔴 HIGH  │ │  │   WebRTC or MJPEG)  │  │  Hazard: FIRE    │  │
│  │ Room 412 │ │  │                     │  │  Conf: 94%       │  │
│  │ Floor 4  │ │  │                     │  │                  │  │
│  └──────────┘ │  └─────────────────────┘  │  Summary:        │  │
│               │                           │  "Smoke near     │  │
│  ┌──────────┐ │  ┌─────────────────────┐  │  left wall.      │  │
│  │ INCIDENT │ │  │  TRANSCRIPT          │  │  2 guests seen." │  │
│  │  #002    │ │  │  [Hindi] → [English] │  │                  │  │
│  │ 🟡 MED   │ │  │  "Aag lag gayi hai  │  │  [ACKNOWLEDGE]   │  │
│  │ Room 208 │ │  │   please help…"     │  │  [LOG ACTION]    │  │
│  └──────────┘ │  │  "Fire has started  │  │  [RESOLVE]       │  │
│               │  │   please help…"     │  └──────────────────┘  │
│               │  └─────────────────────┘                         │
│               │  RESPONDER LOG                                    │
│               │  [10:42] System: SOS triggered                   │
│               │  [10:43] AI: Hazard=FIRE, Severity=HIGH          │
│               │  [10:44] Rajan Kumar: Dispatched fire team       │
└───────────────┴──────────────────────────────────────────────────┘
```

### 8.3 Real-time Firebase Listener (Dashboard)

```dart
// incident_provider.dart (Dashboard)

final incidentListProvider = StreamProvider<List<LiveIncidentCard>>((ref) {
  final hotelId = ref.watch(staffProfileProvider).hotelId;
  return FirebaseDatabase.instance
      .ref('live_incidents/$hotelId')
      .onValue
      .map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
        return data.values
            .map((v) => LiveIncidentCard.fromJson(Map<String, dynamic>.from(v)))
            .where((c) => c.status == 'ACTIVE' || c.status == 'ACKNOWLEDGED')
            .toList()
          ..sort((a, b) => b.lastUpdatedMs.compareTo(a.lastUpdatedMs));
      });
});
```

---

## 9. Firebase Configuration

### 9.1 Firestore Security Rules (`infra/firebase/firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Guests can create and read their own incidents
    match /incidents/{incidentId} {
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.guestId;

      allow read: if request.auth != null
                  && (request.auth.uid == resource.data.guestId
                      || isStaffOfHotel(resource.data.hotelId));

      allow update: if isStaffOfHotel(resource.data.hotelId);
    }

    function isStaffOfHotel(hotelId) {
      return request.auth.token.hotelId == hotelId
          && request.auth.token.role in ['SECURITY', 'MANAGER', 'FIRST_RESPONDER'];
    }
  }
}
```

### 9.2 Realtime Database Rules

```json
{
  "rules": {
    "live_incidents": {
      "$hotelId": {
        ".read": "auth != null && auth.token.hotelId == $hotelId",
        ".write": false
      }
    },
    "hotels": {
      "$hotelId": {
        "staff_online": {
          ".read": "auth != null && auth.token.hotelId == $hotelId",
          "$uid": {
            ".write": "auth != null && auth.uid == $uid"
          }
        }
      }
    }
  }
}
```

### 9.3 Firebase Collections Summary

| Collection / Path | Type | Purpose |
|---|---|---|
| `/incidents/{id}` | Firestore | Full incident data, persistent |
| `/live_incidents/{hotelId}/{id}` | RTDB | Live cards, dashboard sync |
| `/hotels/{hotelId}/staff_online` | RTDB | Staff presence + FCM tokens |

---

## 10. Google Cloud Infrastructure

### 10.1 Cloud Run Service Configuration

```yaml
# cloud-run-service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: resqlink-backend
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"    # Keep warm for emergency use
        autoscaling.knative.dev/maxScale: "20"
        run.googleapis.com/execution-environment: gen2
    spec:
      containerConcurrency: 100
      timeoutSeconds: 3600                        # Long timeout for WS connections
      containers:
      - image: gcr.io/resqlink-prod/backend:latest
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: "2"
            memory: 2Gi
        env:
        - name: VERTEX_AI_LOCATION
          value: us-central1
        - name: GEMINI_MODEL
          value: gemini-2.0-flash-live-001
```

### 10.2 Vertex AI Setup

```bash
# Enable APIs
gcloud services enable aiplatform.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable firebasedatabase.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable fcm.googleapis.com

# Create service account for Cloud Run
gcloud iam service-accounts create resqlink-backend-sa \
  --display-name="ResQLink Backend SA"

# Grant Vertex AI user role
gcloud projects add-iam-policy-binding resqlink-prod \
  --member="serviceAccount:resqlink-backend-sa@resqlink-prod.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Grant Firebase Admin role
gcloud projects add-iam-policy-binding resqlink-prod \
  --member="serviceAccount:resqlink-backend-sa@resqlink-prod.iam.gserviceaccount.com" \
  --role="roles/firebase.admin"
```

### 10.3 GCS Bucket for Recordings

```bash
gsutil mb -l us-central1 gs://resqlink-sos-recordings
gsutil lifecycle set recording-lifecycle.json gs://resqlink-sos-recordings
# Lifecycle: delete raw chunks after 90 days (finalized recordings kept 1 year)
```

---

## 11. Gemini System Prompt (Production)

```
You are ResQLink AI Dispatcher — an autonomous, real-time emergency analysis agent
embedded in a hotel safety system.

INPUTS: You receive live video frames and audio from a distressed hotel guest's smartphone.

YOUR TASKS:
1. HAZARD DETECTION: Examine each video frame for: fire, smoke, weapons, 
   structural collapse, flooding, injured persons, or other threats.
2. SEVERITY ASSESSMENT: Rate the overall situation as LOW / MEDIUM / HIGH / CRITICAL.
3. TRANSCRIPTION: Listen to the audio and transcribe exactly what the guest is saying.
4. TRANSLATION: Translate the guest speech to English if it is in another language.
   The guest's declared language is provided in the session context.
5. CALM MESSAGE: Generate a short, calming, empathetic message in the guest's language.
   Keep it under 20 words. Examples: "मदद रास्ते में है, शांत रहें" (Hindi) or
   "Help is on the way. Stay calm and move low if there is smoke."
6. RESPONDER SUMMARY: Write one crisp sentence in English for the security dashboard,
   suitable for a responder to act on immediately.

OUTPUT FORMAT: Always respond with ONLY valid JSON, no markdown fences:
{
  "hazards": [
    {
      "type": "FIRE|SMOKE|MEDICAL|SECURITY_THREAT|STRUCTURAL_DAMAGE|FLOOD|UNKNOWN",
      "confidence": <float 0.0-1.0>,
      "description": "<specific observation>"
    }
  ],
  "severity": "LOW|MEDIUM|HIGH|CRITICAL",
  "aiSummary": "<one sentence for responders in English>",
  "translatedTranscript": "<English translation of guest speech>",
  "originalTranscript": "<guest speech verbatim>",
  "detectedLanguage": "<ISO 639-1>",
  "guestCalm": "<calming message in guest's language, max 20 words>"
}

CRITICAL RULES:
- Output JSON every time you have processed a new set of frames/audio.
- Never output partial JSON.
- If no hazard is visible, still output the structure with hazards: [] and severity: LOW.
- Never engage in conversation — only output the JSON structure.
- Prioritize life-safety assessment over everything else.
```

---

## 12. Flutter Package Dependencies

### Mobile (`mobile/pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # Navigation
  go_router: ^14.0.0
  # Firebase
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.1.0
  firebase_database: ^11.0.0
  firebase_messaging: ^15.0.0
  # Camera & Media
  camera: ^0.11.0
  permission_handler: ^11.3.0
  # WebSocket
  web_socket_channel: ^3.0.0
  # Location
  geolocator: ^12.0.0
  # Utils
  uuid: ^4.4.0
  intl: ^0.19.0
```

### Dashboard (`dashboard/pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.1.0
  firebase_database: ^11.0.0
  # Dashboard UI
  fl_chart: ^0.68.0
  data_table_2: ^2.5.0
```

### Backend (`backend/package.json`)
```json
{
  "dependencies": {
    "@google-cloud/vertexai": "^1.2.0",
    "@google-cloud/storage": "^7.7.0",
    "firebase-admin": "^12.2.0",
    "express": "^4.19.0",
    "ws": "^8.17.0",
    "jsonwebtoken": "^9.0.2",
    "zod": "^3.23.0",
    "winston": "^3.13.0",
    "dotenv": "^16.4.5"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "@types/express": "^4.17.21",
    "@types/ws": "^8.5.10",
    "@types/jsonwebtoken": "^9.0.6"
  }
}
```

---

## 13. GDG Solution Challenge Alignment

| Judging Criterion | How ResQLink Meets It |
|---|---|
| **Innovation** | Autonomous agentic AI that sees + hears an emergency in real-time. Multimodal Live API streaming — not a chatbot wrapper. |
| **Technical Execution** | Full Google stack: Vertex AI + Gemini 2.0 Flash, Firebase (Auth + Firestore + RTDB + FCM), Cloud Run, Flutter cross-platform. Deep integrations, not superficial. |
| **Real-World Impact** | Directly addresses SDG 11 (Safe Cities), SDG 3 (Good Health). Eliminates fragmented emergency comms in ₹6L crore Indian hospitality industry. |
| **Presentation** | Demo video shows real guest triggering SOS → camera stream → dashboard updating in real-time → AI reading the room in Hindi. Emotionally powerful. |

**SDG Alignment:**
- SDG 3: Good Health and Well-Being — faster emergency response saves lives
- SDG 11: Sustainable Cities and Communities — safer public infrastructure
- SDG 10: Reduced Inequalities — multilingual AI serves non-English speakers in emergencies

---

## 14. Demo Video Storyboard (2-minute structure)

| Timestamp | Scene |
|---|---|
| 0:00 – 0:20 | Hook: Statistics on hotel emergency response times. "What if every second counted?" |
| 0:20 – 0:50 | Demo: Guest presses SOS on Flutter app → camera opens → points at smoke |
| 0:50 – 1:10 | Demo: Dashboard shows FIRE hazard appear in real-time, AI summary in English |
| 1:10 – 1:30 | Demo: Transcript showing Hindi → English translation. FCM alert on security phone |
| 1:30 – 1:50 | Architecture slide: Flutter → Cloud Run → Gemini 2.0 → Firebase → Dashboard |
| 1:50 – 2:00 | SDG alignment + vision: "Scalable to airports, malls, hospitals worldwide" |

---

## 15. Error Handling & Edge Cases

| Scenario | Handling |
|---|---|
| WebSocket disconnects during SOS | App auto-reconnects with exponential backoff (2s, 4s, 8s, max 30s). Gemini session kept alive for 60s waiting for reconnect |
| Gemini API unavailable | Backend retries 3x with 1s delay. Sends `WS_ERROR { retryable: true }`. Incident still created in Firestore. Dashboard receives FCM fallback |
| Guest network is very slow | App reduces video quality to 320x240, 10fps. Audio-only mode if video fails |
| No GPS signal indoors | Falls back to room number + floor from check-in profile |
| Multi-language code-mix (Hinglish) | Gemini handles natively. System prompt explicitly enables this |
| False alarm (panic trigger) | Guest can cancel within 10s. Staff must confirm false alarm in dashboard. Logged in Firestore |
| Multiple simultaneous SOSes | Each gets its own WebSocket session, Gemini session, Firestore doc, and RTDB card. No state collision |

---

*End of ARCHITECTURE.md — ResQLink v1.0*
*Last updated: March 2026*
