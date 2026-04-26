// Shared severity color utilities for dashboard
import 'package:flutter/material.dart';

Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL':
      return const Color(0xFFEF4444);
    case 'HIGH':
      return const Color(0xFFF59E0B);
    case 'MEDIUM':
      return const Color(0xFF3B82F6);
    case 'LOW':
      return const Color(0xFF8A8F98);
    default:
      return const Color(0xFF22C55E);
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
