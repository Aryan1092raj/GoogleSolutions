import 'package:flutter/material.dart'; 
import 'package:go_router/go_router.dart'; 
import '../features/auth/screens/guest_checkin_screen.dart'; 
import '../features/sos/screens/sos_home_screen.dart'; 
import '../features/sos/screens/sos_active_screen.dart'; 
import '../features/sos/screens/sos_resolved_screen.dart'; 
import '../features/profile/screens/guest_profile_screen.dart'; 
 
final GoRouter appRouter = GoRouter( 
  initialLocation: '/', 
  routes: [ 
    GoRoute( 
      path: '/', 
      builder: (context, state) { 
        return const SplashScreen(); 
      }, 
    ), 
    GoRoute( 
      path: '/checkin', 
      builder: (context, state) { 
        return const GuestCheckinScreen(); 
      }, 
    ), 
    GoRoute( 
      path: '/home', 
      builder: (context, state) { 
        return const SOSHomeScreen(); 
      }, 
    ), 
    GoRoute( 
      path: '/sos/active/:id', 
      builder: (context, state) { 
        final id = state.pathParameters['id'] ?? ''; 
        return SOSActiveScreen(incidentId: id); 
      }, 
    ), 
    GoRoute( 
      path: '/sos/resolved/:id', 
      builder: (context, state) { 
        final id = state.pathParameters['id'] ?? ''; 
        return SOSResolvedScreen(incidentId: id); 
      }, 
    ), 
    GoRoute( 
      path: '/profile', 
      builder: (context, state) { 
        return const GuestProfileScreen(); 
      }, 
    ), 
  ], 
); 
 
class SplashScreen extends StatelessWidget { 
  const SplashScreen({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    Future.microtask(() { 
      context.go('/checkin'); 
    }); 
    return const Scaffold(body: Center(child: CircularProgressIndicator())); 
  } 
}
