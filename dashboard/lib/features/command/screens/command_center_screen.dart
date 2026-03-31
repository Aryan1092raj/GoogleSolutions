// dashboard/lib/features/command/screens/command_center_screen.dart
// Liquid Glass Design System

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/incident_provider.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';
import '../widgets/transcript_panel.dart';
import '../widgets/action_controls.dart';
import '../widgets/command_chat_panel.dart';
import '../../../../core/dashboard_theme.dart';
import '../../../../core/severity_colors.dart' as severity_utils;

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() =>
      _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(incidentListProvider).value ?? [];
    final profile = ref.watch(staffProfileProvider);

    // Auto-select first incident
    if (cards.isNotEmpty &&
        (_selectedId == null ||
            !cards.any((c) => c.incidentId == _selectedId))) {
      _selectedId = cards.first.incidentId;
    }
    final selected = cards.isEmpty
        ? null
        : cards.firstWhere(
            (c) => c.incidentId == _selectedId,
            orElse: () => cards.first,
          );

    return Scaffold(
      backgroundColor: kDashBg,
      body: Stack(
        children: [
          // Background gradient
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
          // Background glow
          Positioned(
            top: -140,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kDashAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              _Header(
                hotel: profile.hotelId.isEmpty
                    ? 'UNASSIGNED'
                    : profile.hotelId.toUpperCase(),
                role: profile.role.isEmpty ? 'STAFF' : profile.role,
                activeCount: cards.length,
              ),
              Expanded(
                child: Row(
                  children: [
                    _IncidentSidebar(
                      cards: cards,
                      selectedId: _selectedId,
                      onSelect: (id) => setState(() => _selectedId = id),
                    ),
                    Container(
                      width: 1,
                      color: kDashBorder,
                    ),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 10),
                              child: LiveFeedTile(
                                hazard:
                                    selected == null ? 'UNKNOWN' : selected.primaryHazard.toString(),
                                summary:
                                    selected == null ? '' : selected.aiSummary.toString(),
                                incidentId: selected?.incidentId,
                                aiStatus: selected?.aiStatus,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 16),
                              child: TranscriptPanel(
                                incidentId: selected?.incidentId ?? '-',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      color: kDashBorder,
                    ),
                    SizedBox(
                      width: 420,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chatHeight =
                              constraints.maxHeight >= 860 ? 280.0 : 240.0;
                          final logHeight =
                              constraints.maxHeight >= 860 ? 240.0 : 220.0;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (selected != null) ...[
                                  _AiAnalysisPanel(incident: selected),
                                  const SizedBox(height: 12),
                                ],
                                ActionControls(
                                  incidentId: selected?.incidentId ?? '-',
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: chatHeight,
                                  child: CommandChatPanel(
                                    incidentId: selected?.incidentId ?? '-',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: logHeight,
                                  child: ResponderLog(
                                    incidentId: selected?.incidentId ?? '-',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header bar
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String hotel;
  final String role;
  final int activeCount;

  const _Header({
    required this.hotel,
    required this.role,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [kDashAccent, Color(0xFF0066CC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: kDashAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'RESQLINK',
            style: GoogleFonts.fustat(
              color: kDashText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 20,
            color: kDashBorder,
          ),
          // Hotel
          const Icon(Icons.business, size: 14, color: kDashTextSub),
          const SizedBox(width: 6),
          Text(
            hotel,
            style: GoogleFonts.inter(
              color: kDashTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 20),
          // Active count badge
          _StatusChip(
            label: '$activeCount ACTIVE',
            color: activeCount > 0 ? kDashDanger : kDashTextSub,
            dot: activeCount > 0,
          ),
          const SizedBox(width: 8),
          _StatusChip(label: role, color: kDashInfo),
          const Spacer(),
          // Online indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kDashGreen,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.inter(
                  color: kDashGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const _StatusChip({
    required this.label,
    required this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kDashDanger,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
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

// ─────────────────────────────────────────────────────────────────────────────
// Incident sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _IncidentSidebar extends StatelessWidget {
  final List<LiveIncidentCard> cards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _IncidentSidebar({
    required this.cards,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          // Sidebar header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'ACTIVE INCIDENTS',
              style: GoogleFonts.inter(
                color: kDashTextMut,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // List
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: kDashGreen,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ALL CLEAR',
                          style: GoogleFonts.fustat(
                            color: kDashGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No active incidents',
                          style: GoogleFonts.inter(
                            color: kDashTextMut,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cards.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (ctx, i) => _IncidentTile(
                      card: cards[i],
                      selected: cards[i].incidentId == selectedId,
                      onTap: () => onSelect(cards[i].incidentId),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final LiveIncidentCard card;
  final bool selected;
  final VoidCallback onTap;

  const _IncidentTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = severity_utils.severityColor(card.severity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x1AFFFFFF)
              : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: sevColor.withValues(alpha: 0.5),
                )
              : Border.all(
                  color: kDashBorder,
                ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: sevColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Severity bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: sevColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        card.roomNumber,
                        style: GoogleFonts.fustat(
                          color: kDashText,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _hazardIcon(card.primaryHazard),
                        color: _hazardColor(card.primaryHazard),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Floor ${card.floor}  ·  ${card.guestName}',
                    style: GoogleFonts.inter(
                      color: kDashTextSub,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sevColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: sevColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          card.severity,
                          style: GoogleFonts.inter(
                            color: sevColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (card.isStreamLive)
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: kDashDanger,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: GoogleFonts.inter(
                                color: kDashDanger,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _hazardIcon(String hazard) {
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

  Color _hazardColor(String hazard) {
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
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Analysis panel
// ─────────────────────────────────────────────────────────────────────────────
class _AiAnalysisPanel extends StatefulWidget {
  final LiveIncidentCard incident;

  const _AiAnalysisPanel({required this.incident});

  @override
  State<_AiAnalysisPanel> createState() => _AiAnalysisPanelState();
}

class _AiAnalysisPanelState extends State<_AiAnalysisPanel> {
  @override
  Widget build(BuildContext context) {
    final sevColor = severity_utils.severityColor(widget.incident.severity);
    final aiStatusColor = _aiStatusColor(widget.incident.aiStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: kDashAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'AI ANALYSIS',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'STATUS',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aiStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: aiStatusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.incident.aiStatus,
                  style: GoogleFonts.inter(
                    color: aiStatusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Severity meter
          Row(
            children: [
              Text(
                'SEVERITY',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: sevColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.incident.severity,
                  style: GoogleFonts.fustat(
                    color: sevColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Severity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _sevValue(widget.incident.severity),
              backgroundColor: kDashBorder,
              valueColor: AlwaysStoppedAnimation(sevColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          // Hazard chip
          Row(
            children: [
              Text(
                'HAZARD',
                style: GoogleFonts.inter(
                  color: kDashTextMut,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kDashBorder),
                ),
                child: Text(
                  widget.incident.primaryHazard,
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // AI Summary
          Text(
            'SUMMARY',
            style: GoogleFonts.inter(
              color: kDashTextMut,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDashBorder),
            ),
            child: Text(
              _summaryForState(widget.incident.aiStatus, widget.incident.aiSummary),
              style: GoogleFonts.inter(
                color: widget.incident.aiStatus == 'AVAILABLE' &&
                        widget.incident.aiSummary.isNotEmpty
                    ? kDashText
                    : kDashTextSub,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stream status
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.incident.isStreamLive ? kDashDanger : kDashTextSub,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.incident.isStreamLive ? 'STREAM LIVE' : 'STREAM OFFLINE',
                style: GoogleFonts.inter(
                  color:
                      widget.incident.isStreamLive ? kDashDanger : kDashTextSub,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (widget.incident.acknowledgedBy != null)
                Text(
                  'ACK',
                  style: GoogleFonts.inter(
                    color: kDashInfo,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _sevValue(String s) {
    switch (s.toUpperCase()) {
      case 'LOW':
        return 0.25;
      case 'MEDIUM':
        return 0.50;
      case 'HIGH':
        return 0.75;
      case 'CRITICAL':
        return 1.0;
      default:
        return 0.1;
    }
  }

  Color _aiStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return kDashAccent;
      case 'UNAVAILABLE':
        return kDashDanger;
      case 'DEGRADED':
        return kDashWarning;
      case 'PENDING':
      default:
        return kDashTextSub;
    }
  }

  String _summaryForState(String status, String summary) {
    if (summary.isNotEmpty) {
      return summary;
    }
    switch (status.toUpperCase()) {
      case 'UNAVAILABLE':
        return 'AI analysis is unavailable for this incident.';
      case 'DEGRADED':
        return 'AI is running in fallback mode and may respond more slowly.';
      case 'AVAILABLE':
        return 'AI analysis is available.';
      case 'PENDING':
      default:
        return 'Awaiting AI analysis...';
    }
  }
}
