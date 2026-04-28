# ResQLink Mobile

## Local setup

Generate the gitignored Firebase config before running:

```powershell
flutterfire configure --project=solution-e2a1c --platforms=android,ios --out=lib/firebase_options.dart --yes
```

`lib/firebase_options.dart` is not committed on purpose. The app imports that file at startup, so local generation is required before `flutter run`, `flutter analyze`, or release builds.
