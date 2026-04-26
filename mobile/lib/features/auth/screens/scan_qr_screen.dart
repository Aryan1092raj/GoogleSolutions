// mobile/lib/features/auth/screens/scan_qr_screen.dart
// QR Code Scanner for Room Check-in

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme.dart';

class ScanQrScreen extends StatefulWidget {
  final Function(Map<String, dynamic> scannedData) onScanned;

  const ScanQrScreen({super.key, required this.onScanned});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _scanned = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              if (_scanned) return;

              final barcode = capture.barcodes.first;
              final rawValue = barcode.rawValue;

              if (rawValue == null || rawValue.isEmpty) return;

              try {
                // Parse JSON from QR code
                final data = jsonDecode(rawValue) as Map<String, dynamic>;

                // Validate required fields
                if (!data.containsKey('hotelId') ||
                    !data.containsKey('roomNumber') ||
                    !data.containsKey('floor') ||
                    !data.containsKey('wing')) {
                  _showError('Invalid QR code format');
                  return;
                }

                setState(() => _scanned = true);

                // Extract data
                final extractedData = {
                  'hotelId': data['hotelId'].toString(),
                  'roomNumber': data['roomNumber'].toString(),
                  'floor': data['floor'] is int
                      ? data['floor']
                      : int.tryParse(data['floor'].toString()) ?? 0,
                  'wing': data['wing'].toString(),
                  if (data['roomType'] != null)
                    'roomType': data['roomType'].toString(),
                  if (data['language'] != null)
                    'language': data['language'].toString(),
                };

                // Call callback and pop
                widget.onScanned(extractedData);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                _showError('Failed to parse QR code');
              }
            },
          ),
          // Overlay with scan area
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          // Instructions at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Scan the QR code on your room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() => _scanned = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner overlay painter
// ─────────────────────────────────────────────────────────────────────────────
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    // Dark overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Corner markers
    final markerPaint = Paint()
      ..color = kPrimary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const markerLength = 30.0;
    const cornerRadius = 20.0;

    // Top-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left - 2,
          rect.top - 2,
          markerLength,
          markerLength,
        ),
        const Radius.circular(cornerRadius),
      ),
      markerPaint..style = PaintingStyle.stroke,
    );

    // Top-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.right - markerLength + 2,
          rect.top - 2,
          markerLength,
          markerLength,
        ),
        const Radius.circular(cornerRadius),
      ),
      markerPaint..style = PaintingStyle.stroke,
    );

    // Bottom-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left - 2,
          rect.bottom - markerLength + 2,
          markerLength,
          markerLength,
        ),
        const Radius.circular(cornerRadius),
      ),
      markerPaint..style = PaintingStyle.stroke,
    );

    // Bottom-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.right - markerLength + 2,
          rect.bottom - markerLength + 2,
          markerLength,
          markerLength,
        ),
        const Radius.circular(cornerRadius),
      ),
      markerPaint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
