import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';

class SOSTriggerButton extends StatefulWidget {
  final VoidCallback onPressed;
  const SOSTriggerButton({super.key, required this.onPressed});

  @override
  State<SOSTriggerButton> createState() => _SOSTriggerButtonState();
}

class _SOSTriggerButtonState extends State<SOSTriggerButton>
    with TickerProviderStateMixin {
  // Three staggered pulse ring controllers
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _pulseController3;

  // Hold activation
  Timer? _holdTimer;
  bool _holding = false;
  double _progress = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    // Three pulse rings staggered by 400ms
    _pulseController1 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: false);

    _pulseController2 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController3 = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Stagger the rings
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _pulseController2.repeat(reverse: false);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _pulseController3.repeat(reverse: false);
    });
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    HapticFeedback.mediumImpact();
    setState(() { _holding = true; _progress = 0; });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      setState(() { _progress = (t.tick * 20) / 2000; });
      if (_progress >= 1) t.cancel();
    });
    _holdTimer = Timer(const Duration(seconds: 2), () {
      HapticFeedback.heavyImpact();
      widget.onPressed();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    setState(() { _holding = false; _progress = 0; });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _pulseController1,
        builder: (_, __) {
          final scale = _holding ? 1.08 : (1.0 + _pulseController1.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring 1 (largest, faintest)
                AnimatedBuilder(
                  animation: _pulseController3,
                  builder: (context, child) {
                    final pulseValue = _pulseController3.value;
                    final expandedSize = 280 * (0.7 + 0.3 * pulseValue);
                    final opacity = 0.04 * (1 - pulseValue);
                    return Positioned(
                      width: expandedSize,
                      height: expandedSize,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                ),
                // Outer pulse ring 2 (medium)
                AnimatedBuilder(
                  animation: _pulseController2,
                  builder: (context, child) {
                    final pulseValue = _pulseController2.value;
                    final expandedSize = 240 * (0.7 + 0.3 * pulseValue);
                    final opacity = 0.08 * (1 - pulseValue);
                    return Positioned(
                      width: expandedSize,
                      height: expandedSize,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                ),
                // Outer pulse ring 3 (innermost, most visible)
                AnimatedBuilder(
                  animation: _pulseController1,
                  builder: (context, child) {
                    final pulseValue = _pulseController1.value;
                    final expandedSize = 200 * (0.7 + 0.3 * pulseValue);
                    final opacity = 0.15 * (1 - pulseValue);
                    return Positioned(
                      width: expandedSize,
                      height: expandedSize,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimary.withValues(alpha: opacity),
                        ),
                      ),
                    );
                  },
                ),
                // Progress ring (visible during hold)
                if (_holding)
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 4,
                      color: kPrimary,
                      backgroundColor: kPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                // Main SOS Button - 160px diameter
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kPrimary, Color(0xFFff5545)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
