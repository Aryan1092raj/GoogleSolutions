import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart';
import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _activateFirebaseAppCheck();
  _configureFirestore();
  runApp(const ProviderScope(child: ResQLinkApp()));
}

Future<void> _activateFirebaseAppCheck() async {
  try {
    if (kIsWeb) {
      final siteKey = AppConstants.firebaseAppCheckWebSiteKey.trim();
      if (siteKey.isEmpty) {
        debugPrint(
          'Firebase App Check skipped on web: FIREBASE_APP_CHECK_WEB_SITE_KEY is not configured.',
        );
        return;
      }

      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(siteKey),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase App Check activation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _configureFirestore() {
  if (!kIsWeb) {
    return;
  }

  final firestore = FirebaseFirestore.instance;
  firestore.settings = firestore.settings.copyWith(
    webExperimentalForceLongPolling: true,
    webExperimentalAutoDetectLongPolling: false,
    webExperimentalLongPollingOptions: const WebExperimentalLongPollingOptions(
      timeoutDuration: Duration(seconds: 20),
    ),
  );
}
