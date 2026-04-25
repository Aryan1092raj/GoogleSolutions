import 'package:flutter/material.dart';

const _surface = Color(0xFF121215);
const _surfaceHigh = Color(0xFF18181B);
const _outlineVariant = Color(0xFF27272A);
const _primary = Color(0xFFA78BFA);
const _onSurface = Color(0xFFFAFAFA);
const _onSurfaceMuted = Color(0xFFA1A1AA);
const _critical = Color(0xFFEF4444);
const _warning = Color(0xFFF97316);
const _ok = Color(0xFF34D399);

class SOSGuidePanel extends StatelessWidget {
  const SOSGuidePanel({
    super.key,
    required this.severity,
    required this.aiMessage,
    required this.helpOnWay,
    this.etaMinutes,
    this.hotelId,
    this.roomNumber,
  });

  final String severity;
  final String aiMessage;
  final bool helpOnWay;
  final int? etaMinutes;
  final String? hotelId;
  final String? roomNumber;

  @override
  Widget build(BuildContext context) {
    final normalizedSeverity = severity.toUpperCase();
    final steps = _stepsFor(normalizedSeverity);
    final summary = _statusSummary();

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'LIVE SAFETY GUIDE',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
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
                    color: _onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _StatusCard(
              severity: normalizedSeverity,
              summary: summary,
              etaMinutes: etaMinutes,
            ),
            const SizedBox(height: 14),
            if (aiMessage.trim().isNotEmpty)
              _GuideSection(
                title: 'Assistant Update',
                child: Text(
                  aiMessage,
                  style: const TextStyle(
                    color: _onSurface,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (aiMessage.trim().isNotEmpty) const SizedBox(height: 14),
            _GuideSection(
              title: 'What To Do Now',
              child: Column(
                children: steps
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
                                  color: _onSurface,
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

  List<String> _stepsFor(String severity) {
    switch (severity) {
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

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
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
      _ => _primary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
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
              color: _onSurface,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (etaMinutes != null && etaMinutes! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Estimated arrival: $etaMinutes min',
                style: const TextStyle(
                  color: _onSurfaceMuted,
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
