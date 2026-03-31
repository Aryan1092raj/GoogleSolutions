import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/dashboard_theme.dart';

class HazardTag extends StatelessWidget {
  final String hazard;

  const HazardTag({super.key, required this.hazard});

  Color _getColor() {
    switch (hazard) {
      case 'FIRE':
        return kDashDanger;
      case 'SMOKE':
        return kDashWarning;
      case 'MEDICAL':
        return const Color(0xFFFF6B9D);
      case 'SECURITY_THREAT':
        return const Color(0xFFAA44FF);
      case 'FLOOD':
        return kDashInfo;
      default:
        return kDashTextSub;
    }
  }

  IconData _getIcon() {
    switch (hazard) {
      case 'FIRE':
        return Icons.local_fire_department;
      case 'SMOKE':
        return Icons.cloud;
      case 'MEDICAL':
        return Icons.medical_services;
      case 'SECURITY_THREAT':
        return Icons.shield_outlined;
      case 'FLOOD':
        return Icons.water;
      default:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            hazard,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
