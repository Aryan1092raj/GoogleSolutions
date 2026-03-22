import 'dart:async';

import 'package:flutter/material.dart';

class SOSTriggerButton extends StatefulWidget {
  final VoidCallback onPressed;
  const SOSTriggerButton({super.key, required this.onPressed});

  @override
  State<SOSTriggerButton> createState() => _SOSTriggerButtonState();
}

class _SOSTriggerButtonState extends State<SOSTriggerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(seconds: 2), widget.onPressed);
  }

  void _cancelHold() {
    _holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1 + (_pulseController.value * 0.06);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
