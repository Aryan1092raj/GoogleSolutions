// dashboard/lib/features/command/screens/qr_generator_screen.dart
// QR Code Generator for Room Check-in

import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final _floorCtrl = TextEditingController();
  final _wingCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  List<Map<String, dynamic>> _qrCodes = [];

  @override
  void dispose() {
    _floorCtrl.dispose();
    _wingCtrl.dispose();
    _roomsCtrl.dispose();
    super.dispose();
  }

  void _generateQrCodes() {
    final profile = ref.read(staffProfileProvider);
    final hotelId = profile.hotelId;
    if (hotelId.isEmpty) {
      _showError('Please login with a hotel account first');
      return;
    }

    final floor = int.tryParse(_floorCtrl.text.trim());
    if (floor == null || floor <= 0) {
      _showError('Please enter a valid floor number');
      return;
    }

    final wing = _wingCtrl.text.trim();
    if (wing.isEmpty) {
      _showError('Please enter a wing name');
      return;
    }

    final roomsText = _roomsCtrl.text.trim();
    if (roomsText.isEmpty) {
      _showError('Please enter room numbers');
      return;
    }

    final rooms = roomsText
        .split(',')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
    if (rooms.isEmpty) {
      _showError('Please enter at least one room number');
      return;
    }

    final codes = <Map<String, dynamic>>[];
    for (final room in rooms) {
      final qrData = {
        'hotelId': hotelId,
        'roomNumber': room,
        'floor': floor,
        'wing': wing,
      };
      codes.add({
        'roomNumber': room,
        'data': qrData,
      });
    }

    setState(() {
      _qrCodes = codes;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kDashDanger,
      ),
    );
  }

  void _printQrCodes() {
    if (_qrCodes.isEmpty) {
      _showError('No QR codes to print');
      return;
    }
    // Trigger browser print
    web.window.print();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(staffProfileProvider);

    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kDashBg,
                    Color(0xFF071325),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              _Header(
                hotel: profile.hotelId.isEmpty
                    ? 'UNASSIGNED'
                    : profile.hotelId.toUpperCase(),
                role: profile.role.isEmpty ? 'STAFF' : profile.role,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Input Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: glassSurfaceDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GENERATE ROOM QR CODES',
                              style: GoogleFonts.inter(
                                color: kDashTextMut,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _InputField(
                                    controller: _floorCtrl,
                                    label: 'Floor Number',
                                    hint: 'e.g., 1',
                                    isNumber: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _InputField(
                                    controller: _wingCtrl,
                                    label: 'Wing Name',
                                    hint: 'e.g., East Wing',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _InputField(
                              controller: _roomsCtrl,
                              label: 'Room Numbers (comma-separated)',
                              hint: 'e.g., 101, 102, 103, 104',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _generateQrCodes,
                                  icon: const Icon(Icons.qr_code_2, size: 18),
                                  label: const Text('Generate QR Codes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kDashAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_qrCodes.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: _printQrCodes,
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('Print'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kDashInfo,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // QR Code Grid
                      if (_qrCodes.isNotEmpty) ...[
                        Text(
                          'GENERATED QR CODES (${_qrCodes.length})',
                          style: GoogleFonts.inter(
                            color: kDashTextMut,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _qrCodes.length,
                          itemBuilder: (context, index) {
                            final qr = _qrCodes[index];
                            return _QrCard(
                              roomNumber: qr['roomNumber'] as String,
                              qrData: qr['data'] as Map<String, dynamic>,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header bar
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String hotel;
  final String role;
  final VoidCallback onBack;

  const _Header({
    required this.hotel,
    required this.role,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kDashText, size: 20),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [kDashAccent, Color(0xFF0066CC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: kDashAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_2,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'QR CODE GENERATOR',
            style: GoogleFonts.fustat(
              color: kDashText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Hotel
          const Icon(Icons.business, size: 14, color: kDashTextSub),
          const SizedBox(width: 6),
          Text(
            hotel,
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input field
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNumber;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: kDashText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.inter(
            color: kDashText,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: kDashTextMut,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0x0AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDashBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDashBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDashAccent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QR Code Card
// ─────────────────────────────────────────────────────────────────────────────
class _QrCard extends StatelessWidget {
  final String roomNumber;
  final Map<String, dynamic> qrData;

  const _QrCard({
    required this.roomNumber,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    final qrJson = jsonEncode(qrData);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: glassSurfaceDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: QrImageView(
              data: qrJson,
              version: QrVersions.auto,
              size: 120.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0066CC),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Room $roomNumber',
            style: GoogleFonts.fustat(
              color: kDashText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Floor ${qrData['floor']} · ${qrData['wing']}',
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
