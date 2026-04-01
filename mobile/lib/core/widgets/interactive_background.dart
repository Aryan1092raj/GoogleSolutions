// mobile/lib/core/widgets/interactive_background.dart
// Interactive background with touch-responsive glow effect

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class InteractiveBackground extends StatefulWidget {
  final Widget child;
  final Duration fadeDuration;
  final double touchRadius;

  const InteractiveBackground({
    super.key,
    required this.child,
    this.fadeDuration = const Duration(milliseconds: 800),
    this.touchRadius = 100.0,
  });

  @override
  State<InteractiveBackground> createState() => _InteractiveBackgroundState();
}

class _InteractiveBackgroundState extends State<InteractiveBackground>
    with TickerProviderStateMixin {
  final List<_TouchPoint> _touchPoints = [];
  late AnimationController _fadeController;
  double _fadeOpacity = 0.0;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _fadeTimer?.cancel();
    super.dispose();
  }

  void _onTouchDown(Offset position) {
    setState(() {
      _touchPoints.add(_TouchPoint(
        position: position,
        age: 0,
      ));
    });

    // Trigger fade animation
    _fadeController.forward(from: 0);
    setState(() => _fadeOpacity = 1.0);

    // Auto-fade after 2 seconds
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _fadeOpacity = 0.0);
      }
    });

    // Remove touch point after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _touchPoints.removeWhere((p) => p.age > 600);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (details) => _onTouchDown(details.globalPosition),
      onTapDown: (details) => _onTouchDown(details.globalPosition),
      child: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kBackground,
                  kBackground.withValues(alpha: 0.95),
                  kSurface.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Interactive glow layer
          CustomPaint(
            painter: _InteractiveGlowPainter(
              touchPoints: _touchPoints,
              fadeOpacity: _fadeOpacity,
              primaryColor: kPrimary,
              secondaryColor: kSecondary,
            ),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

class _TouchPoint {
  final Offset position;
  final int age;

  _TouchPoint({
    required this.position,
    required this.age,
  });
}

class _InteractiveGlowPainter extends CustomPainter {
  final List<_TouchPoint> touchPoints;
  final double fadeOpacity;
  final Color primaryColor;
  final Color secondaryColor;

  _InteractiveGlowPainter({
    required this.touchPoints,
    required this.fadeOpacity,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final point in touchPoints) {
      // Calculate age-based opacity
      final ageOpacity = 1.0 - (point.age / 600);
      if (ageOpacity <= 0) continue;

      // Create gradient
      final gradient = RadialGradient(
        center: Alignment(
          (point.position.dx / size.width * 2) - 1,
          (point.position.dy / size.height * 2) - 1,
        ),
        radius: 0.3,
        colors: [
          primaryColor.withValues(alpha: 0.15 * ageOpacity * fadeOpacity),
          secondaryColor.withValues(alpha: 0.08 * ageOpacity * fadeOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(
          center: point.position,
          radius: 150,
        ),
      );

      canvas.drawCircle(point.position, 150, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveGlowPainter oldDelegate) {
    return oldDelegate.touchPoints.length != touchPoints.length ||
        oldDelegate.fadeOpacity != fadeOpacity;
  }
}
