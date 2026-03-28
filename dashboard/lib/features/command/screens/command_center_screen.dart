// dashboard/lib/features/command/screens/command_center_screen.dart
// Full replacement — same providers, new layout & visual design.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/incident_provider.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';
import '../widgets/transcript_panel.dart';
import '../widgets/action_controls.dart';
import '../../../../core/dashboard_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});
  @override
  ConsumerState<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  String? _selectedId;
  late Timer _clockTimer;
  String _timeStr = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    setState(() => _timeStr =
      '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}');
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards    = ref.watch(incidentListProvider).value ?? [];
    final profile  = ref.watch(staffProfileProvider);

    // Auto-select first incident
    if (cards.isNotEmpty && (_selectedId == null ||
        !cards.any((c) => c.incidentId == _selectedId))) {
      _selectedId = cards.first.incidentId;
    }
    final selected = cards.isEmpty
        ? null
        : cards.firstWhere(
            (c) => c.incidentId == _selectedId,
            orElse: () => cards.first);

    return Scaffold(
      backgroundColor: kDashBg,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        _Header(
          hotel: profile.hotelId.isEmpty ? 'UNASSIGNED' : profile.hotelId.toUpperCase(),
          role: profile.role.isEmpty ? 'STAFF' : profile.role,
          activeCount: cards.length,
          timeStr: _timeStr,
        ),

        // ── Main area ────────────────────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Left sidebar: incident list
              _IncidentSidebar(
                cards: cards,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
              ),

              // Vertical divider
              Container(width: 1, color: kDashBorder),

              // Center: video + transcript
              Expanded(
                flex: 5,
                child: Column(children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: LiveFeedTile(
                        hazard: selected?.primaryHazard ?? 'UNKNOWN',
                        summary: selected?.aiSummary ?? '',
                      ),
                    ),
                  ),
                  Container(height: 1, color: kDashBorder),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TranscriptPanel(
                        incidentId: selected?.incidentId ?? '-'),
                    ),
                  ),
                ]),
              ),

              // Vertical divider
              Container(width: 1, color: kDashBorder),

              // Right panel: AI analysis + actions + log
              SizedBox(
                width: 340,
                child: Column(children: [
                  if (selected != null)
                    _AiAnalysisPanel(incident: selected),
                  Container(height: 1, color: kDashBorder),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ActionControls(
                      incidentId: selected?.incidentId ?? '-'),
                  ),
                  Container(height: 1, color: kDashBorder),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ResponderLog(
                        incidentId: selected?.incidentId ?? '-'),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header bar
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String hotel;
  final String role;
  final int    activeCount;
  final String timeStr;
  const _Header({
    required this.hotel, required this.role,
    required this.activeCount, required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: kDashSurface,
        border: Border(bottom: BorderSide(color: kDashBorder)),
      ),
      child: Row(children: [
        // Logo
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [kDashAccent, Color(0xFF007F6A)]),
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text('RESQLINK', style: GoogleFonts.rajdhani(
          color: kDashText, fontSize: 16,
          fontWeight: FontWeight.w700, letterSpacing: 3)),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 1, height: 20, color: kDashBorder),

        // Hotel
        Icon(Icons.business, size: 14, color: kDashTextMut),
        const SizedBox(width: 6),
        Text(hotel, style: GoogleFonts.rajdhani(
          color: kDashTextSub, fontSize: 13,
          fontWeight: FontWeight.w500, letterSpacing: 1)),

        const SizedBox(width: 20),

        // Active count
        _StatusChip(
          label: '$activeCount ACTIVE',
          color: activeCount > 0 ? kDashDanger : kDashTextMut,
          dot: activeCount > 0,
        ),
        const SizedBox(width: 8),
        _StatusChip(label: role, color: kDashInfo),

        const Spacer(),

        // Clock
        Text(timeStr, style: GoogleFonts.ibmPlexMono(
          color: kDashTextSub, fontSize: 13, letterSpacing: 2)),
        const SizedBox(width: 16),

        // Online indicator
        Container(width: 8, height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: kDashGreen)),
        const SizedBox(width: 6),
        Text('LIVE', style: GoogleFonts.ibmPlexMono(
          color: kDashGreen, fontSize: 10, letterSpacing: 2)),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;
  const _StatusChip({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
        ],
        Text(label, style: GoogleFonts.rajdhani(
          color: color, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 1)),
      ]),
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
    required this.cards, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(children: [
        // Sidebar header
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kDashBorder)),
          ),
          child: Text('ACTIVE INCIDENTS',
            style: GoogleFonts.ibmPlexMono(
              color: kDashTextMut, fontSize: 10, letterSpacing: 1.5)),
        ),
        // List
        Expanded(
          child: cards.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline,
                    color: kDashGreen, size: 32),
                  const SizedBox(height: 12),
                  Text('ALL CLEAR',
                    style: GoogleFonts.rajdhani(
                      color: kDashGreen, fontSize: 14,
                      fontWeight: FontWeight.w600, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('No active incidents',
                    style: GoogleFonts.karla(
                      color: kDashTextMut, fontSize: 12)),
                ]),
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
      ]),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final LiveIncidentCard card;
  final bool selected;
  final VoidCallback onTap;
  const _IncidentTile({required this.card, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sevColor = severityColor(card.severity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? kDashSurface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? sevColor.withValues(alpha: 0.5) : kDashBorder,
          ),
        ),
        child: Row(children: [
          // Severity bar
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: sevColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(card.roomNumber,
                      style: GoogleFonts.rajdhani(
                        color: kDashText, fontSize: 18,
                        fontWeight: FontWeight.w700)),
                    const Spacer(),
                    _HazardBadge(hazard: card.primaryHazard),
                  ]),
                  const SizedBox(height: 3),
                  Text('Floor ${card.floor}  ·  ${card.guestName}',
                    style: GoogleFonts.karla(
                      color: kDashTextSub, fontSize: 11)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(card.severity,
                        style: GoogleFonts.ibmPlexMono(
                          color: sevColor, fontSize: 9, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 6),
                    if (card.isStreamLive)
                      Row(children: [
                        Container(width: 5, height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: kDashDanger)),
                        const SizedBox(width: 4),
                        Text('LIVE', style: GoogleFonts.ibmPlexMono(
                          color: kDashDanger, fontSize: 9, letterSpacing: 1)),
                      ]),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}

class _HazardBadge extends StatelessWidget {
  final String hazard;
  const _HazardBadge({required this.hazard});

  Color get _color {
    switch (hazard) {
      case 'FIRE':             return kDashDanger;
      case 'SMOKE':            return kDashWarning;
      case 'MEDICAL':          return const Color(0xFFFF6B9D);
      case 'SECURITY_THREAT':  return const Color(0xFFAA44FF);
      case 'FLOOD':            return kDashInfo;
      default:                 return kDashTextMut;
    }
  }

  IconData get _icon {
    switch (hazard) {
      case 'FIRE':            return Icons.local_fire_department;
      case 'SMOKE':           return Icons.cloud;
      case 'MEDICAL':         return Icons.medical_services;
      case 'SECURITY_THREAT': return Icons.shield_outlined;
      case 'FLOOD':           return Icons.water;
      default:                return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) => Icon(_icon, color: _color, size: 16);
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Analysis panel (right column)
// ─────────────────────────────────────────────────────────────────────────────
class _AiAnalysisPanel extends StatelessWidget {
  final LiveIncidentCard incident;
  const _AiAnalysisPanel({required this.incident});

  @override
  Widget build(BuildContext context) {
    final sevColor = severityColor(incident.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kDashBorder)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI ANALYSIS',
          style: GoogleFonts.ibmPlexMono(
            color: kDashTextMut, fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 12),

        // Severity meter
        Row(children: [
          Text('SEVERITY', style: GoogleFonts.ibmPlexMono(
            color: kDashTextMut, fontSize: 10, letterSpacing: 1)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sevColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: sevColor.withValues(alpha: 0.3)),
            ),
            child: Text(incident.severity,
              style: GoogleFonts.rajdhani(
                color: sevColor, fontSize: 13,
                fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ]),
        const SizedBox(height: 8),

        // Severity bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: _sevValue(incident.severity),
            backgroundColor: kDashBorder,
            valueColor: AlwaysStoppedAnimation(sevColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 14),

        // Hazard chip
        Row(children: [
          Text('HAZARD', style: GoogleFonts.ibmPlexMono(
            color: kDashTextMut, fontSize: 10, letterSpacing: 1)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kDashSurface2,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: kDashBorder),
            ),
            child: Text(incident.primaryHazard,
              style: GoogleFonts.ibmPlexMono(
                color: kDashText, fontSize: 10, letterSpacing: 0.8)),
          ),
        ]),
        const SizedBox(height: 14),

        // AI Summary
        Text('SUMMARY', style: GoogleFonts.ibmPlexMono(
          color: kDashTextMut, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kDashSurface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kDashBorder),
          ),
          child: Text(
            incident.aiSummary.isEmpty
                ? 'Awaiting AI analysis…'
                : incident.aiSummary,
            style: GoogleFonts.karla(
              color: incident.aiSummary.isEmpty
                  ? kDashTextMut : kDashText,
              fontSize: 12, height: 1.5),
          ),
        ),

        const SizedBox(height: 12),
        // Stream status
        Row(children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: incident.isStreamLive ? kDashDanger : kDashTextMut,
            ),
          ),
          const SizedBox(width: 6),
          Text(incident.isStreamLive ? 'STREAM LIVE' : 'STREAM OFFLINE',
            style: GoogleFonts.ibmPlexMono(
              color: incident.isStreamLive ? kDashDanger : kDashTextMut,
              fontSize: 10, letterSpacing: 1)),
          const Spacer(),
          if (incident.acknowledgedBy != null)
            Text('ACK', style: GoogleFonts.ibmPlexMono(
              color: kDashInfo, fontSize: 10, letterSpacing: 1)),
        ]),
      ]),
    );
  }

  double _sevValue(String s) {
    switch (s.toUpperCase()) {
      case 'LOW':      return 0.25;
      case 'MEDIUM':   return 0.50;
      case 'HIGH':     return 0.75;
      case 'CRITICAL': return 1.0;
      default:         return 0.1;
    }
  }
}
