import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'core/dashboard_theme.dart';
import 'features/auth/screens/staff_login_screen.dart';
import 'features/auth/widgets/dashboard_auth_bootstrap.dart';
import 'features/command/screens/command_center_screen.dart';
import 'features/command/screens/incident_detail_screen.dart';
import 'features/command/screens/incident_history_screen.dart';
import 'features/command/screens/qr_generator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _configureFirestore();
  runApp(
    const ProviderScope(
      child: DashboardAuthBootstrap(
        child: DashboardApp(),
      ),
    ),
  );
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

class DashboardRouterRefresh extends ChangeNotifier {
  DashboardRouterRefresh(Stream<User?> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _dashboardRouterRefresh =
    DashboardRouterRefresh(FirebaseAuth.instance.authStateChanges());

final dashboardRouter = GoRouter(
  initialLocation:
      FirebaseAuth.instance.currentUser == null ? '/login' : '/dashboard',
  refreshListenable: _dashboardRouterRefresh,
  redirect: (_, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final onLogin = state.matchedLocation == '/login';

    if (!loggedIn && !onLogin) {
      return '/login';
    }

    if (loggedIn && onLogin) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => FirebaseAuth.instance.currentUser == null
          ? '/login'
          : '/dashboard',
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
      builder: (_, state) =>
          IncidentDetailScreen(incidentId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/incident-history',
      builder: (_, __) => const IncidentHistoryScreen(),
    ),
    GoRoute(
      path: '/qr-generator',
      builder: (_, __) => const QrGeneratorScreen(),
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
      theme: buildDashboardTheme(),
    );
  }
}
