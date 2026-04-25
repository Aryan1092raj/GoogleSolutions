// dashboard/lib/features/auth/screens/staff_login_screen.dart
// Liquid Glass Design System

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
  static const Set<String> _allowedStaffRoles = <String>{
    'SECURITY',
    'MANAGER',
    'FIRST_RESPONDER',
  };

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty) {
      _snack('Email is required');
      return;
    }
    if (password.isEmpty) {
      _snack('Password is required');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final token = await cred.user?.getIdTokenResult(true);
      final claims = token?.claims;
      final hotelId = (claims?['hotelId'] as String?)?.trim() ?? '';
      final role = ((claims?['role'] as String?) ?? '').trim().toUpperCase();
      if (hotelId.isEmpty || !_allowedStaffRoles.contains(role)) {
        await FirebaseAuth.instance.signOut();
        _snack('Account is not provisioned for staff dashboard access.');
        return;
      }
      final profile = StaffProfile(
        uid: cred.user?.uid ?? '',
        hotelId: hotelId,
        role: role,
      );
      ref.read(staffProfileProvider.notifier).state = profile;
      await syncStaffAccessProfile(profile, email: email);
      await markStaffOnline(profile, name: email);
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      _snack(_authMessageFor(e));
    } catch (_) {
      _snack('Sign-in failed unexpectedly. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: kDashSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ));
  }

  String _authMessageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This staff account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network issue while signing in. Check connection and retry.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this Firebase project.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Sign-in failed (${error.code}).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(
        children: [
          // Background grid pattern
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Radial glow behind the card
          Center(
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kDashAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
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
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0x1AFFFFFF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: Color(0x14FFFFFF),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kDashAccent, Color(0xFF0066CC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kDashAccent.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'RESQLINK',
                      style: GoogleFonts.fustat(
                        color: kDashText,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Precision safety for your stay.',
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Divider with label
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: kDashBorder),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'STAFF ACCESS',
                            style: GoogleFonts.inter(
                              color: kDashTextMut,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: kDashBorder),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Email
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: kDashText),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.alternate_email, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.inter(color: kDashText),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: kDashTextSub,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kDashAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            const BoxShadow(
                              color: Color(0x59FFFFFF),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDashAccent.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'SIGN IN',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: kDashGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ResQLink onboarding secured by Firebase Auth',
                          style: GoogleFonts.inter(
                            color: kDashTextMut,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background grid painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF).withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner accents
    final accentPaint = Paint()
      ..color = kDashAccent.withValues(alpha: 0.12)
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
