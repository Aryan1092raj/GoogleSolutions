// Shared severity color utilities for dashboard
import 'package:flutter/material.dart';

Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL':
      return const Color(0xFFFF3B30);
    case 'HIGH':
      return const Color(0xFFFF6B35);
    case 'MEDIUM':
      return const Color(0xFFFFCC00);
    default:
      return const Color(0xFF26A69A);
  }
}

IconData severityIcon(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL':
      return Icons.warning_amber_rounded;
    case 'HIGH':
      return Icons.error_outline;
    case 'MEDIUM':
      return Icons.info_outline;
    default:
      return Icons.check_circle_outline;
  }
}
