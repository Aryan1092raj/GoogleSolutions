import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _configureFirestore();
  runApp(const ProviderScope(child: ResQLinkApp()));
}

void _configureFirestore() {
  if (!kIsWeb) {
    return;
  }

  final firestore = FirebaseFirestore.instance;
  firestore.settings = firestore.settings.copyWith(
    webExperimentalForceLongPolling: true,
    webExperimentalAutoDetectLongPolling: false,
    webExperimentalLongPollingOptions:
        const WebExperimentalLongPollingOptions(
      timeoutDuration: Duration(seconds: 20),
    ),
  );
}
