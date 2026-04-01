# ResQLink 🚨

**AI-Powered Hotel Emergency Response System**

ResQLink enables hotel guests to trigger SOS alerts with live video/audio streaming. AI analyzes the feed in real-time, detects hazards (fire, medical emergencies, threats), and dispatches help automatically.

---

## 🏗️ Architecture

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Mobile App     │      │  Backend         │      │  Security       │
│  (Flutter)      │─────▶│  (Node.js + AI)  │─────▶│  Dashboard      │
│  Guest SOS      │      │  Cloud Run       │      │  (Flutter Web)  │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                │
                         ┌──────▼──────┐
                         │  Firebase   │
                         │  Vertex AI  │
                         └─────────────┘
```

---

## 📦 Components

| Component | Tech | Purpose |
|-----------|------|---------|
| **Mobile** | Flutter (Android/iOS) | Guest SOS trigger, camera/mic streaming |
| **Backend** | Node.js + Express | WebSocket hub, AI orchestration |
| **Dashboard** | Flutter Web | Live incident monitoring for security staff |
| **AI** | Gemini 2.0 Flash | Real-time hazard detection, translation |

---

## 🚀 Quick Start

### Prerequisites

- Node.js 20+, Flutter 3.24+, Firebase CLI, GCP account
- Firebase project with Auth, Firestore, Realtime DB enabled
- Vertex AI API enabled

### Backend

```bash
cd backend
npm install
# Configure .env (see DEPLOYMENT_PLAN.md)
npm run build
npm start
```

### Mobile App

```bash
cd mobile
flutter pub get
# Add google-services.json & GoogleService-Info.plist
flutter run
```

### Dashboard

```bash
cd dashboard
flutter pub get
# Add firebase_options.dart
flutter run -d chrome
```

---

## 📁 Project Structure

```
gdgsolutions/
├── backend/           # Node.js backend (Cloud Run)
├── mobile/            # Flutter guest app
├── dashboard/         # Flutter security dashboard
├── infra/             # Terraform & Firebase configs
├── scripts/           # Utility scripts
└── docs/              # Documentation
```

---

## 📚 Documentation

| Doc | Purpose |
|-----|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Full system design, APIs, data models |
| [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md) | Step-by-step deployment guide |
| [PROJECT_RULES.md](PROJECT_RULES.md) | Development methodology |

---

## 🔑 Key Features

- **One-tap SOS** - Instant emergency alert with location
- **Live AI analysis** - Real-time hazard detection from video/audio
- **Multi-language** - Auto-translation for international guests
- **Live dashboard** - Security sees all incidents in real-time
- **FCM alerts** - Push notifications to on-duty staff
- **Incident logging** - Full audit trail in Firestore

---

## 🛠️ Tech Stack

- **Mobile:** Flutter, Riverpod, Camera, WebSocket, Geolocator
- **Backend:** Node.js, Express, WebSocket, Vertex AI, Firebase Admin
- **Dashboard:** Flutter Web, Firebase, Realtime DB
- **Cloud:** Google Cloud Run, Vertex AI, Firebase (Auth/Firestore/RTDB/FCM)
- **AI:** Gemini 2.0 Flash (multimodal live API)

---

## 📄 License

Built for Google GDG Solution Challenge 2026
