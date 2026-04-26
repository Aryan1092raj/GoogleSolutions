import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';
import '../widgets/action_controls.dart';
import '../widgets/command_chat_panel.dart';
import '../widgets/incident_map_widget.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';
import '../widgets/transcript_panel.dart';

class IncidentDetailScreen extends ConsumerWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (incidentId.isEmpty) {
      return const _InvalidIncidentScreen();
    }

    final detailAsync = ref.watch(incidentDetailProvider(incidentId));

    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kDashBg,
                    Color(0xFF071325),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -130,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kDashAccent.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: detailAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _ErrorState(message: '$error'),
              data: (detail) {
                if (detail == null) {
                  return _NotFoundState(incidentId: incidentId);
                }

                return Column(
                  children: [
                    _TopBar(incidentId: incidentId),
                    Expanded(
                      child: Row(
                        children: [
                          _SideRail(
                            onLiveBoardTap: () => context.go('/dashboard'),
                            onHistoryTap: () => context.go('/incident-history'),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _IncidentHeaderCard(detail: detail),
                                    const SizedBox(height: 14),
                                    _DetailGrid(detail: detail),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String incidentId;

  const _TopBar({required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          Text(
            'Obsidian Security',
            style: GoogleFonts.fustat(
              color: kDashText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: Text(
              'Dashboard',
              style: GoogleFonts.inter(color: kDashTextSub),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Incident Detail',
              style: GoogleFonts.inter(
                color: kDashAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/incident-history'),
            child: Text(
              'History',
              style: GoogleFonts.inter(color: kDashTextSub),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kDashBorder),
            ),
            child: Text(
              incidentId,
              style: GoogleFonts.robotoMono(
                color: kDashTextSub,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.go('/dashboard'),
            tooltip: 'Back to Dashboard',
            icon:
                const Icon(Icons.home_outlined, color: kDashTextSub, size: 19),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final VoidCallback onLiveBoardTap;
  final VoidCallback onHistoryTap;

  const _SideRail({
    required this.onLiveBoardTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: kDashGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Command Center',
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kDashBorder),
          _RailLink(
            label: 'Live Board',
            icon: Icons.sensors,
            selected: false,
            onTap: onLiveBoardTap,
          ),
          _RailLink(
            label: 'History',
            icon: Icons.history,
            selected: false,
            onTap: onHistoryTap,
          ),
          _RailLink(
            label: 'Incident Detail',
            icon: Icons.assistant_navigation,
            selected: true,
            onTap: () {},
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDashBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: kDashAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure Session',
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RailLink({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? kDashAccent.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? kDashAccent : kDashTextSub),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? kDashAccent : kDashTextSub,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentHeaderCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _IncidentHeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final statusChipColor = statusColor(detail.status);
    final severityChipColor = severityColor(detail.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusChipColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusChipColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            detail.status == 'ACTIVE'
                                ? Icons.circle
                                : Icons.check_circle,
                            color: statusChipColor,
                            size: 10,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(detail.status),
                            style: GoogleFonts.inter(
                              color: statusChipColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Started ${_relativeAge(detail.createdAtMs)}',
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${detail.incidentId}: ${_titleFor(detail)}',
                  style: GoogleFonts.fustat(
                    color: kDashText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Room ${detail.roomNumber} · Floor ${detail.floor} ${detail.wing.isEmpty ? '' : '· ${detail.wing}'} · Guest ${detail.guestName}',
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _Pill(
                label: detail.severity,
                color: severityChipColor,
              ),
              _Pill(
                label: detail.aiStatus,
                color: _aiStatusColor(detail.aiStatus),
              ),
              _Pill(
                label: detail.isStreamLive ? 'STREAM LIVE' : 'STREAM OFFLINE',
                color: detail.isStreamLive ? kDashDanger : kDashTextSub,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'ACTIVE EMERGENCY';
      case 'ACKNOWLEDGED':
        return 'ACKNOWLEDGED';
      case 'RESOLVED':
        return 'RESOLVED';
      case 'FALSE_ALARM':
        return 'FALSE ALARM';
      default:
        return status;
    }
  }

  String _titleFor(IncidentDetailRecord detail) {
    final hazard = detail.primaryHazard.replaceAll('_', ' ');
    if (hazard.trim().isEmpty || hazard == 'UNKNOWN') {
      return 'Emergency Signal Raised';
    }
    return '${_titleCase(hazard)} Alert';
  }

  String _titleCase(String value) {
    final words = value.toLowerCase().split(' ');
    return words
        .where((w) => w.trim().isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _relativeAge(int createdAtMs) {
    if (createdAtMs <= 0) {
      return 'unknown';
    }
    final delta = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
    if (delta.inMinutes < 1) {
      return 'just now';
    }
    if (delta.inHours < 1) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inDays < 1) {
      final hours = delta.inHours;
      final minutes = delta.inMinutes % 60;
      return '${hours}h ${minutes}m ago';
    }
    return '${delta.inDays}d ago';
  }

  Color _aiStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return kDashAccent;
      case 'UNAVAILABLE':
        return kDashDanger;
      case 'DEGRADED':
        return kDashWarning;
      default:
        return kDashTextSub;
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _DetailGrid({required this.detail});

  @override
  Widget build(BuildContext context) {
    final isResolved =
        detail.status == 'RESOLVED' || detail.status == 'FALSE_ALARM';

    if (isResolved) {
      return _ResolvedIncidentView(detail: detail);
    }

    final width = MediaQuery.of(context).size.width;
    final compact = width < 1280;

    if (compact) {
      return Column(
        children: _buildCompactSections(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _FixedSection(
                height: 290,
                child: LiveFeedTile(
                  hazard: detail.primaryHazard,
                  summary: detail.aiSummary,
                  incidentId: detail.incidentId,
                  aiStatus: detail.aiStatus,
                ),
              ),
              const SizedBox(height: 12),
              _FixedSection(
                height: 225,
                child: _LocationCard(detail: detail),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _FixedSection(
                height: 290,
                child: TranscriptPanel(incidentId: detail.incidentId),
              ),
              const SizedBox(height: 12),
              _FixedSection(
                height: 225,
                child: ResponderLog(incidentId: detail.incidentId),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              ActionControls(incidentId: detail.incidentId),
              const SizedBox(height: 12),
              _FixedSection(
                height: 290,
                child: CommandChatPanel(incidentId: detail.incidentId),
              ),
              const SizedBox(height: 12),
              _GuestCard(detail: detail),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCompactSections() {
    return [
      _FixedSection(
        height: 280,
        child: LiveFeedTile(
          hazard: detail.primaryHazard,
          summary: detail.aiSummary,
          incidentId: detail.incidentId,
          aiStatus: detail.aiStatus,
        ),
      ),
      const SizedBox(height: 12),
      _FixedSection(
        height: 220,
        child: _LocationCard(detail: detail),
      ),
      const SizedBox(height: 12),
      _FixedSection(
        height: 260,
        child: TranscriptPanel(incidentId: detail.incidentId),
      ),
      const SizedBox(height: 12),
      _FixedSection(
        height: 220,
        child: ResponderLog(incidentId: detail.incidentId),
      ),
      const SizedBox(height: 12),
      ActionControls(incidentId: detail.incidentId),
      const SizedBox(height: 12),
      _FixedSection(
        height: 300,
        child: CommandChatPanel(incidentId: detail.incidentId),
      ),
      const SizedBox(height: 12),
      _GuestCard(detail: detail),
    ];
  }
}

class _FixedSection extends StatelessWidget {
  final double height;
  final Widget child;

  const _FixedSection({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: child,
    );
  }
}

class _LocationCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _LocationCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassSurfaceDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: kDashAccent, size: 17),
              const SizedBox(width: 8),
              Text(
                'LOCATION INTEL',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
              const Spacer(),
              if (detail.lat != null && detail.lng != null)
                Text(
                  '${detail.lat!.toStringAsFixed(5)}, ${detail.lng!.toStringAsFixed(5)}',
                  style: GoogleFonts.robotoMono(
                    color: kDashTextSub,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IncidentMapWidget(
              lat: detail.lat,
              lng: detail.lng,
              roomNumber: detail.roomNumber,
              severity: detail.severity,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _GuestCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: glassSurfaceDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: kDashAccent, size: 17),
              const SizedBox(width: 8),
              Text(
                'GUEST CONTEXT',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Guest', value: detail.guestName),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Language',
            value: detail.detectedLanguage.isEmpty
                ? detail.guestLanguage
                : detail.detectedLanguage,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Phone',
            value:
                detail.guestPhone.isEmpty ? 'Not provided' : detail.guestPhone,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Acknowledged By',
            value: detail.acknowledgedBy ?? 'Pending',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'ETA',
            value:
                detail.etaMinutes == null ? '--' : '${detail.etaMinutes} min',
          ),
          if (detail.hazards.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Hazards',
              style: GoogleFonts.inter(
                color: kDashTextSub,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detail.hazards
                  .map(
                    (hazard) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kDashBorder),
                      ),
                      child: Text(
                        hazard.replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          color: kDashText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolvedIncidentView extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _ResolvedIncidentView({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResolvedHero(detail: detail),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 980) {
              return Column(
                children: [
                  _ResolvedMapCard(detail: detail),
                  const SizedBox(height: 12),
                  _ResolvedInfoCard(detail: detail),
                  const SizedBox(height: 12),
                  _ResolvedProtocolCard(detail: detail),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _ResolvedMapCard(detail: detail),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _ResolvedInfoCard(detail: detail),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _ResolvedProtocolCard(detail: detail),
      ],
    );
  }
}

class _ResolvedHero extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _ResolvedHero({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kDashGreen.withValues(alpha: 0.14),
              border: Border.all(color: kDashGreen.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.task_alt,
              color: kDashGreen,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help has been notified.',
                  style: GoogleFonts.fustat(
                    color: kDashText,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Responders are on-site for ${detail.roomNumber}.',
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Pill(
            label: detail.status,
            color: statusColor(detail.status),
          ),
        ],
      ),
    );
  }
}

class _ResolvedMapCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _ResolvedMapCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: glassSurfaceDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: kDashAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'LIVE LOCATION',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: IncidentMapWidget(
              lat: detail.lat,
              lng: detail.lng,
              roomNumber: detail.roomNumber,
              severity: detail.severity,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedInfoCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _ResolvedInfoCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassSurfaceDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incident Reference',
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail.incidentId,
            style: GoogleFonts.robotoMono(
              color: kDashAccent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: kDashBorder),
          const SizedBox(height: 10),
          _DetailRow(label: 'Priority', value: detail.severity),
          const SizedBox(height: 8),
          _DetailRow(label: 'Dispatched', value: _clock(detail.createdAtMs)),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Resolved',
            value: _clock(detail.resolvedAtMs ?? detail.updatedAtMs),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Team',
            value: detail.acknowledgedBy ?? 'Security Unit A-4',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Protocol',
            value:
                detail.status == 'FALSE_ALARM' ? 'Closed safely' : 'Completed',
          ),
        ],
      ),
    );
  }

  String _clock(int ms) {
    if (ms <= 0) {
      return '--:--';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _ResolvedProtocolCard extends StatelessWidget {
  final IncidentDetailRecord detail;

  const _ResolvedProtocolCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: glassSurfaceDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROTOCOL COMPLIANCE',
                  style: GoogleFonts.inter(
                    color: kDashTextMut,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: detail.status == 'FALSE_ALARM' ? 0.78 : 1,
                    minHeight: 8,
                    backgroundColor: kDashBorder,
                    valueColor: AlwaysStoppedAnimation(
                      detail.status == 'FALSE_ALARM'
                          ? kDashWarning
                          : kDashGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const _ResolvedLine(
                  icon: Icons.check_circle,
                  label: 'External services contacted',
                  complete: true,
                ),
                const SizedBox(height: 6),
                const _ResolvedLine(
                  icon: Icons.check_circle,
                  label: 'Building management alerted',
                  complete: true,
                ),
                const SizedBox(height: 6),
                _ResolvedLine(
                  icon: detail.status == 'FALSE_ALARM'
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  label: detail.status == 'FALSE_ALARM'
                      ? 'Marked as false alarm and archived'
                      : 'Incident report finalized',
                  complete: detail.status != 'FALSE_ALARM',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDashBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_2,
                    color: kDashAccent.withValues(alpha: 0.9)),
                const SizedBox(height: 8),
                Text(
                  'Emergency Link',
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/qr-generator'),
                  child: const Text('Open Portal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool complete;

  const _ResolvedLine({
    required this.icon,
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final color = complete ? kDashGreen : kDashWarning;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: complete ? kDashText : kDashTextSub,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: kDashText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InvalidIncidentScreen extends StatelessWidget {
  const _InvalidIncidentScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashBg,
      body: Center(
        child: Text(
          'Invalid incident id.',
          style: GoogleFonts.inter(
            color: kDashDanger,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NotFoundState extends StatelessWidget {
  final String incidentId;

  const _NotFoundState({required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: glassSurfaceDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: kDashTextSub, size: 42),
            const SizedBox(height: 12),
            Text(
              'Incident not found',
              style: GoogleFonts.fustat(
                color: kDashText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No Firestore incident document exists for $incidentId.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: kDashTextSub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Live Board'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(22),
        decoration: glassSurfaceDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kDashDanger, size: 40),
            const SizedBox(height: 12),
            Text(
              'Failed to load incident detail',
              style: GoogleFonts.fustat(
                color: kDashText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: kDashTextSub,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
