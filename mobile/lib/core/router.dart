import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/sos/models/sos_active_panel.dart';
import '../features/sos/screens/sos_home_screen.dart';
import '../features/sos/screens/sos_active_screen.dart';
import '../features/sos/screens/sos_resolved_screen.dart';
import '../features/profile/screens/guest_profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/checkin', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (c, s) => const SOSHomeScreen()),
    GoRoute(
      path: '/sos/active/:id',
      builder: (c, s) => SOSActiveScreen(
        incidentId: s.pathParameters['id'] ?? '',
        initialPanel: SOSActivePanel.fromQueryValue(
          s.uri.queryParameters['panel'],
        ),
      ),
    ),
    GoRoute(path: '/sos/resolved/:id', builder: (c, s) =>
      SOSResolvedScreen(incidentId: s.pathParameters['id'] ?? '')),
    GoRoute(path: '/profile', builder: (c, s) => const GuestProfileScreen()),
  ],
);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_navigate);
  }

  void _navigate() {
    final auth = ref.read(authStateProvider);
    final profile = ref.read(guestProfileProvider);
    auth.when(
      data: (user) {
        if (user != null && profile != null) {
          context.go('/home');
        } else {
          context.go('/checkin');
        }
      },
      loading: () {},
      error: (_, __) => context.go('/checkin'),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) => _navigate());
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
