// dashboard/lib/features/auth/screens/staff_login_screen.dart
// Full replacement — drop-in, no logic changes.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../command/providers/incident_provider.dart';
import '../../../../core/dashboard_theme.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});
  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty) { _snack('Email is required'); return; }
    if (password.isEmpty) { _snack('Password is required'); return; }

    setState(() => _loading = true);
    try {
      final cred  = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final token  = await cred.user?.getIdTokenResult(true);
      final claims = token?.claims;
      final hotelId = (claims?['hotelId'] as String?) ?? 'hotel1';
      final role    = (claims?['role']    as String?) ?? 'SECURITY';
      ref.read(staffProfileProvider.notifier).state =
          StaffProfile(uid: cred.user?.uid ?? '', hotelId: hotelId, role: role);
      await markStaffOnline(ref.read(staffProfileProvider), name: email);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      _snack('Sign-in failed — check credentials');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.karla()),
      backgroundColor: kDashSurface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: kDashBorder),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(children: [
        // Background grid pattern
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        // Radial glow behind the card
        Center(
          child: Container(
            width: 600, height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [kDashAccent.withValues(alpha: 0.06), Colors.transparent],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        // Login card
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: kDashSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kDashBorder),
                boxShadow: [
                  BoxShadow(
                    color: kDashAccent.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00C9A7), Color(0xFF007F6A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kDashAccent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text('RESQLINK',
                  style: GoogleFonts.rajdhani(
                    color: kDashText, fontSize: 26,
                    fontWeight: FontWeight.w700, letterSpacing: 4,
                  )),
                const SizedBox(height: 4),
                Text('OPERATIONS DASHBOARD',
                  style: GoogleFonts.ibmPlexMono(
                    color: kDashTextMut, fontSize: 10, letterSpacing: 2,
                  )),
                const SizedBox(height: 36),

                // Divider with label
                Row(children: [
                  const Expanded(child: Divider(color: kDashBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('STAFF ACCESS',
                      style: GoogleFonts.ibmPlexMono(
                        color: kDashTextMut, fontSize: 10, letterSpacing: 1.5)),
                  ),
                  const Expanded(child: Divider(color: kDashBorder)),
                ]),
                const SizedBox(height: 24),

                // Email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.karla(color: kDashText),
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email, size: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.karla(color: kDashText),
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18, color: kDashTextMut,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: kDashBg))
                      : Text('SIGN IN',
                          style: GoogleFonts.rajdhani(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            letterSpacing: 2, color: kDashBg)),
                  ),
                ),
                const SizedBox(height: 24),

                // Footer note
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: kDashGreen)),
                  const SizedBox(width: 8),
                  Text('Secured via Firebase Authentication',
                    style: GoogleFonts.ibmPlexMono(
                      color: kDashTextMut, fontSize: 10, letterSpacing: 0.5)),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// Background grid painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2E44).withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(0, size.width), paint);
    }

    // Corner accents
    final accentPaint = Paint()
      ..color = const Color(0xFF00C9A7).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(cx, cy),
        i * math.min(size.width, size.height) * 0.18,
        accentPaint..style = PaintingStyle.stroke,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
