import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/language_picker.dart';
import '../../auth/screens/scan_qr_screen.dart';

const _kRoomTypes = [
  'Standard Room',
  'Deluxe Room',
  'Suite',
  'Presidential Suite',
  'Conference Room',
  'Lobby',
  'Restaurant',
  'Gym',
  'Pool Area',
  'Other',
];

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
  String _roomType = 'Standard Room';
  int? _floor;
  String? _wing;
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
      hintStyle: TextStyle(color: kTextMuted.withValues(alpha: 0.75)),
      labelStyle: const TextStyle(color: kTextMuted),
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      filled: true,
      fillColor: kPanel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorStyle: const TextStyle(color: kPrimary, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0x1FFFFFFF),
        width: 1,
      ),
    );
  }

  void _scanQr() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanQrScreen(
          onScanned: (data) {
            setState(() {
              _hotelIdCtrl.text = data['hotelId'] as String;
              _roomCtrl.text = data['roomNumber'] as String;
              _floor = data['floor'] as int;
              _wing = data['wing'] as String;
              if (data['roomType'] is String &&
                  _kRoomTypes.contains(data['roomType'])) {
                _roomType = data['roomType'] as String;
              }
              if (data['language'] is String &&
                  ['en', 'hi'].contains(data['language'])) {
                _selectedLang = data['language'] as String;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hotelId = _hotelIdCtrl.text.trim();
    final room = _roomCtrl.text.trim();
    const name = 'Guest';

    setState(() => _loading = true);

    try {
      final uri =
          Uri.parse('${AppConstants.backendBaseUrl}/api/auth/guest-token');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hotelId': hotelId,
          'roomNumber': room,
          'roomType': _roomType,
          'guestName': name,
          'language': _selectedLang,
          if (_floor != null) 'floor': _floor,
          if (_wing != null) 'wing': _wing,
        }),
      );

      final body = resp.body;

      if (resp.statusCode != 200) {
        var message = 'Check-in failed';
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          if (parsed['error'] != null) {
            message = parsed['error'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }

      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final customToken = parsed['customToken']?.toString() ?? '';
      final guestId = parsed['guestId']?.toString() ?? '';

      if (customToken.isEmpty || guestId.isEmpty) {
        throw Exception('Invalid guest token response');
      }

      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      ref.read(guestProfileProvider.notifier).setProfile(
            GuestProfile(
              guestId: guestId,
              guestName: name,
              roomNumber: room,
              language: _selectedLang,
              hotelId: hotelId,
              floor: _floor,
              wing: _wing,
            ),
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
      backgroundColor: kBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildForm(),
                      const SizedBox(height: 18),
                      _buildCTA(),
                      const SizedBox(height: 14),
                      _buildFooter(),
                    ],
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: kBrandBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shield,
            color: Colors.white,
            size: 28,
          ),
        ),
        Text(
          'RESQLINK',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: kBrandBlue,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Guest Check-In',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join the emergency relay system before you proceed.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan your room QR or enter details manually.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: const Text('Scan QR Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'MANUAL ENTRY',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hotelIdCtrl,
                style: const TextStyle(color: kTextPrimary),
                decoration: _field('Hotel or Venue Code', Icons.hotel_outlined),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter hotel code'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _roomType,
                decoration: _field('Room Type', Icons.category_outlined),
                dropdownColor: kPanel,
                iconEnabledColor: kTextMuted,
                style: const TextStyle(color: kTextPrimary),
                items: _kRoomTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _roomType = v ?? 'Standard Room'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomCtrl,
                style: const TextStyle(color: kTextPrimary),
                decoration:
                    _field('Room / Unit Number', Icons.meeting_room_outlined),
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter room number'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your preferred language for emergency communications',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      onPressed: _loading ? null : _submit,
      child: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Activate Guest Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0x1A22C55E),
              borderRadius: BorderRadius.circular(7),
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
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
