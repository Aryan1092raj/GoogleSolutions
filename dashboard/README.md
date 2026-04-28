# ResQLink Dashboard

## Local setup

Generate the gitignored Firebase config before running:

```powershell
flutterfire configure --project=solution-e2a1c --platforms=web --out=lib/firebase_options.dart --yes
```

## Google Maps build

The committed `web/index.html` keeps a placeholder key on purpose. Do not hardcode a real Maps key in git.

```powershell
copy .env.example .env.local
# set GOOGLE_MAPS_API_KEY in .env.local
scripts\run-with-maps.bat edge
scripts\build-with-maps.bat
```

The helper scripts inject the key into `web/index.html`, run Flutter, then restore the placeholder so the repo stays clean.
