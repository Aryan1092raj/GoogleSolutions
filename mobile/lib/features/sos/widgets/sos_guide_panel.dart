import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../providers/sos_provider.dart';

const _guideBorder = Color(0x1FFFFFFF);
const _critical = kPrimary;
const _warning = Color(0xFFF59E0B);
const _ok = kSecondary;

class SOSGuidePanel extends StatelessWidget {
  const SOSGuidePanel({
    super.key,
    required this.severity,
    required this.aiMessage,
    required this.helpOnWay,
    this.etaMinutes,
    this.recentUpdates = const [],
    this.hotelId,
    this.roomNumber,
  });

  final String severity;
  final String aiMessage;
  final bool helpOnWay;
  final int? etaMinutes;
  final List<GuestIncidentUpdate> recentUpdates;
  final String? hotelId;
  final String? roomNumber;

  @override
  Widget build(BuildContext context) {
    final normalizedSeverity = severity.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _guideBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideHeader(
              hotelId: hotelId,
              roomNumber: roomNumber,
            ),
            const SizedBox(height: 14),
            _StatusCard(
              severity: normalizedSeverity,
              summary: _statusSummary(),
              etaMinutes: etaMinutes,
            ),
            const SizedBox(height: 14),
            if (aiMessage.trim().isNotEmpty) ...[
              _GuideSection(
                title: 'Assistant Update',
                child: Text(
                  aiMessage,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _GuideSection(
              title: 'What To Do Now',
              child: Column(
                children: _stepsFor(normalizedSeverity)
                    .map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.check_circle,
                                color: _ok,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (recentUpdates.isNotEmpty) ...[
              const SizedBox(height: 14),
              _GuideSection(
                title: 'Security Updates',
                child: Column(
                  children: recentUpdates
                      .map(
                        (update) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: kBrandBlue,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      update.title,
                                      style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (update.detail.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          update.detail,
                                          style: const TextStyle(
                                            color: kTextMuted,
                                            fontSize: 12,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusSummary() {
    if (helpOnWay) {
      if (etaMinutes != null && etaMinutes! > 0) {
        return 'Security is en route. Response ETA: $etaMinutes min.';
      }
      return 'Security is en route. Stay in your safest position.';
    }

    return 'Dispatch is still being coordinated. Keep this session open.';
  }

  List<String> _stepsFor(String currentSeverity) {
    switch (currentSeverity) {
      case 'CRITICAL':
        return const [
          'Remain hidden, keep your phone on silent, and avoid drawing attention.',
          'Move away from doors, hallways, and windows if you can do so safely.',
          'Do not open the door unless hotel security identifies themselves clearly.',
        ];
      case 'HIGH':
        return const [
          'Create distance from the hazard and put a barrier between you and it.',
          'Keep your exit path clear, but do not leave a safer position without a better option.',
          'Stay ready to answer security through chat if they ask for your exact condition.',
        ];
      default:
        return const [
          'Stay calm, keep this feed active, and follow instructions from dispatch.',
          'Keep the room door secure and remove nearby trip hazards if you can.',
          'Prepare to move only if security or the assistant tells you to relocate.',
        ];
    }
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({
    required this.hotelId,
    required this.roomNumber,
  });

  final String? hotelId;
  final String? roomNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _guideBorder),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: kBrandBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'LIVE SAFETY GUIDE',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        if ((hotelId?.isNotEmpty ?? false) || (roomNumber?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              [
                if (hotelId?.isNotEmpty ?? false) hotelId,
                if (roomNumber?.isNotEmpty ?? false) 'Room $roomNumber',
              ].join(' • '),
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _guideBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: kBrandBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.severity,
    required this.summary,
    required this.etaMinutes,
  });

  final String severity;
  final String summary;
  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (severity) {
      'CRITICAL' => _critical,
      'HIGH' => _warning,
      _ => kBrandBlue,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current severity: $severity',
            style: TextStyle(
              color: severityColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (etaMinutes != null && etaMinutes! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Estimated arrival: $etaMinutes min',
                style: const TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
