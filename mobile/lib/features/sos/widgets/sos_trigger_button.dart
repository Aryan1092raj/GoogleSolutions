import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/haptic_feedback.dart';
import '../../../core/theme.dart';

class SOSTriggerButton extends StatefulWidget {
  final VoidCallback onPressed;
  const SOSTriggerButton({super.key, required this.onPressed});

  @override
  State<SOSTriggerButton> createState() => _SOSTriggerButtonState();
}

class _SOSTriggerButtonState extends State<SOSTriggerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Timer? _holdTimer;
  bool   _holding = false;
  double _progress = 0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
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
      onLongPressEnd:   (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          final scale = _holding ? 1.08 : (1.0 + _pulse.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: Stack(alignment: Alignment.center, children: [
              // outer glow ring
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(0.08 + _pulse.value * 0.08),
                ),
              ),
              // progress ring
              if (_holding)
                SizedBox(
                  width: 180, height: 180,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    color: kPrimary,
                    backgroundColor: kPrimary.withOpacity(0.2),
                  ),
                ),
              // button
              Container(
                width: 160, height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimary, Color(0xFFff5545)],
                  ),
                ),
                child: const Center(
                  child: Text('SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    )),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
