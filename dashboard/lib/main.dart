// dashboard/lib/main.dart — full replacement
// Only change from original: uses buildDashboardTheme() instead of basic Material theme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'core/dashboard_theme.dart';
import 'features/auth/screens/staff_login_screen.dart';
import 'features/command/screens/command_center_screen.dart';
import 'features/command/screens/incident_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _configureFirestore();
  runApp(const ProviderScope(child: DashboardApp()));
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

final dashboardRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const StaffLoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const CommandCenterScreen(),
    ),
    GoRoute(
      path: '/incident/:id',
      builder: (_, state) => IncidentDetailScreen(
        incidentId: state.pathParameters['id'] ?? ''),
    ),
  ],
);

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ResQLink Dashboard',
      debugShowCheckedModeBanner: false,
      routerConfig: dashboardRouter,
      theme: buildDashboardTheme(),   // ← new polished theme
    );
  }
}
