# ResQLink 🚨

**AI-Powered Hotel Emergency Response System**

## The Problem

Hotel guests face critical delays during emergencies. Traditional panic buttons lack context, security teams arrive unprepared, and language barriers worsen situations. Every second counts, but information doesn't reach responders fast enough.

## Our Solution

ResQLink transforms emergency response with AI-powered real-time situational awareness:

1. **One-Tap SOS** - Guest triggers alert via mobile app or QR code scan
2. **Live AI Analysis** - Gemini 2.0 Flash analyzes video/audio feed in real-time, detecting hazards (fire, smoke, medical emergencies, threats) and assessing severity
3. **Instant Dispatch** - Security dashboard receives live incident data with AI-generated summaries, hazard classifications, and guest location
4. **Real-Time Translation** - Breaks language barriers by translating guest speech instantly
5. **Live Dashboard** - Security staff see all active incidents, AI findings, and responder status in one view

## How It Works

```
Guest (Mobile App)
    ↓ SOS trigger + camera/mic stream
Backend (Cloud Run + WebSocket)
    ↓ streams to Vertex AI
Gemini 2.0 Flash (AI)
    ↓ hazard detection + translation
Firebase (Realtime DB)
    ↓ pushes to all screens
Security Dashboard (Flutter Web)
```

## Tech Stack

- **Backend:** Node.js, Express, TypeScript, WebSocket
- **AI:** Google Vertex AI (Gemini 2.0 Flash Live API)
- **Mobile:** Flutter (Android/iOS) with camera streaming
- **Dashboard:** Flutter Web with real-time updates
- **Cloud:** Firebase (Auth, Firestore, Realtime DB, FCM), Google Cloud Run

## Impact

- **Faster response** - Security knows what they're walking into before arrival
- **Better preparedness** - AI identifies hazards, severity, and required resources
- **Language inclusive** - Auto-translation for international guests
- **Audit trail** - Full incident logging for post-event review

---

Built for Google GDG Solution Challenge 2026
