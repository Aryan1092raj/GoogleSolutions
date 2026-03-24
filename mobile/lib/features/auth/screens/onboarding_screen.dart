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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelIdCtrl    = TextEditingController();
  final _roomCtrl       = TextEditingController();
  String _selectedLang  = 'en';
  bool   _loading       = false;

  @override
  void dispose() {
    _hotelIdCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kTextMuted),
    prefixIcon: Icon(icon, color: kTextMuted, size: 18),
    filled: true,
    fillColor: kSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kSecondary, width: 1.5),
    ),
    errorStyle: const TextStyle(color: kPrimary),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(guestProfileProvider.notifier).register(
        hotelId:    _hotelIdCtrl.text.trim(),
        roomNumber: _roomCtrl.text.trim(),
        language:   _selectedLang,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: kPrimary,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // logo
                Container(
                  width: 64, height: 64,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, Color(0xFFff5545)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 32,
                    semanticLabel: 'ResQLink Logo'),
                ),

                Text('ResQLink',
                  style: Theme.of(context).textTheme.displayLarge
                    ?.copyWith(fontSize: 28)),
                const SizedBox(height: 4),
                const Text('Your emergency safety companion',
                  style: TextStyle(color: kTextMuted, fontSize: 14)),
                const SizedBox(height: 40),

                // Hotel ID
                TextFormField(
                  controller: _hotelIdCtrl,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: _field('Hotel or Venue Code', Icons.hotel_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Room number
                TextFormField(
                  controller: _roomCtrl,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: _field('Room / Unit Number', Icons.meeting_room_outlined),
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),

                // Language picker
                LanguagePicker(
                  value: _selectedLang,
                  onChanged: (v) => setState(() => _selectedLang = v),
                ),
                const SizedBox(height: 40),

                // CTA
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Get Started',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Your location is only shared during an active emergency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextMuted, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
