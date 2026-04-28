# ResQLink

AI-powered hotel emergency response system with three active apps:

- `backend/` - Node.js + TypeScript websocket/API server
- `mobile/` - Flutter guest SOS app
- `dashboard/` - Flutter web command dashboard

## Reviewer Setup

### 1. Backend

Copy `backend/.env.example` to `backend/.env` and fill the required values.

- For Gemini analysis, configure either:
- `GEMINI_API_KEY` + `GEMINI_MODEL`
- `GOOGLE_CLOUD_PROJECT` + `GOOGLE_CLOUD_LOCATION` (or `VERTEX_AI_LOCATION`) + `GEMINI_MODEL`
- `FIREBASE_WEB_API_KEY` is required for staff login.
- `GCS_BUCKET` is required if you want finalized recordings uploaded.

### 2. Mobile Firebase config

`mobile/lib/firebase_options.dart` is intentionally gitignored. Generate it locally with FlutterFire:

```powershell
cd mobile
flutterfire configure --project=solution-e2a1c --platforms=android,ios --out=lib/firebase_options.dart --yes
```

### 3. Dashboard Firebase config

`dashboard/lib/firebase_options.dart` is intentionally gitignored. Generate it locally with FlutterFire:

```powershell
cd dashboard
flutterfire configure --project=solution-e2a1c --platforms=web --out=lib/firebase_options.dart --yes
```

### 4. Dashboard Google Maps key

The dashboard web map key is not hardcoded in the repo. Build or run the dashboard through the helper scripts so the key is injected at build time and restored afterward:

```powershell
cd dashboard
copy .env.example .env.local
# set GOOGLE_MAPS_API_KEY in .env.local
scripts\run-with-maps.bat edge
scripts\build-with-maps.bat
```

## Runtime Flow

```text
Guest mobile app
  -> backend websocket/API
  -> Gemini / Vertex AI analysis
  -> Firebase realtime state
  -> dashboard + mobile status updates
```

Built for Google GDG Solution Challenge 2026.
