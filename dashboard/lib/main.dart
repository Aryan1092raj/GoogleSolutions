import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/screens/staff_login_screen.dart';
import 'features/command/screens/command_center_screen.dart';
import 'features/command/screens/incident_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: DashboardApp()));
}

final dashboardRouter = GoRouter(routes: [
  GoRoute(
    path: '/',
    redirect: (context, state) => '/login',
  ),
  GoRoute(path: '/login', builder: (context, state) { return const StaffLoginScreen(); }),
  GoRoute(path: '/dashboard', builder: (context, state) { return const CommandCenterScreen(); }),
  GoRoute(path: '/incident/:id', builder: (context, state) {
    final id = state.pathParameters['id'] == null ? '' : state.pathParameters['id'].toString();
    return IncidentDetailScreen(incidentId: id);
  }),
], initialLocation: '/login');

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: dashboardRouter);
  }
}
