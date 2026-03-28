import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/language_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hotelIdCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  String _selectedLang = 'en';
  bool _loading = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _hotelIdCtrl.dispose();
    _roomCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: kTextMuted.withOpacity(0.5)),
      labelStyle: const TextStyle(color: kTextMuted),
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      filled: true,
      fillColor: kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: kTextMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kSecondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorStyle: const TextStyle(color: kPrimary, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      ref.read(guestProfileProvider.notifier).register(
            hotelId: _hotelIdCtrl.text.trim(),
            roomNumber: _roomCtrl.text.trim(),
            language: _selectedLang,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground, Color(0xFF0A1929)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildForm(),
                    const SizedBox(height: 40),
                    _buildCTA(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, Color(0xFFff5545)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield,
            color: Colors.white,
            size: 40,
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Text(
            'ResQLink',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your emergency safety companion',
          style: TextStyle(color: kTextMuted, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kTextMuted.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check In',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your hotel details to get started',
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _hotelIdCtrl,
                style: const TextStyle(color: kTextPrimary),
                decoration:
                    _field('Hotel or Venue Code', Icons.hotel_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter hotel code' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomCtrl,
                style: const TextStyle(color: kTextPrimary),
                decoration:
                    _field('Room / Unit Number', Icons.meeting_room_outlined),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter room number' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kTextMuted.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your preferred language for emergency communications',
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              LanguagePicker(
                value: _selectedLang,
                onChanged: (v) => setState(() => _selectedLang = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCTA() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _loading
            ? null
            : [
                BoxShadow(
                  color: kPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kSecondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: kSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your location is only shared during an active emergency.',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
