// dashboard/lib/features/command/screens/command_center_screen.dart
// Liquid Glass Design System

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';
import '../widgets/transcript_panel.dart';
import '../widgets/action_controls.dart';
import '../widgets/command_chat_panel.dart';
import '../widgets/incident_map_widget.dart';
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
                onStaffLogin: () => _showStaffLoginDialog(context),
                onHistory: () => context.go('/incident-history'),
                onOpenCurrent: selected == null
                    ? null
                    : () => context.go('/incident/${selected.incidentId}'),
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
                      child: selected == null
                          ? const _HomeSosOverview()
                          : Column(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 10),
                                    child: LiveFeedTile(
                                      hazard: selected.primaryHazard.toString(),
                                      summary: selected.aiSummary.toString(),
                                      incidentId: selected.incidentId,
                                      aiStatus: selected.aiStatus,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 10, 16, 16),
                                    child: TranscriptPanel(
                                      incidentId: selected.incidentId,
                                    ),
                                  ),
                                ),
                                Container(height: 1, color: kDashBorder),
                                SizedBox(
                                  height: 200,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: _buildMapPanel(selected),
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

  void _showStaffLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _StaffLoginDialog(),
    );
  }

  Widget _buildMapPanel(LiveIncidentCard card) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .doc(card.incidentId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final location = data?['location'] as Map<String, dynamic>?;
        final lat = (location?['lat'] as num?)?.toDouble();
        final lng = (location?['lng'] as num?)?.toDouble();
        return IncidentMapWidget(
          lat: lat,
          lng: lng,
          roomNumber: card.roomNumber,
          severity: card.severity,
        );
      },
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
  final VoidCallback onStaffLogin;
  final VoidCallback onHistory;
  final VoidCallback? onOpenCurrent;

  const _Header({
    required this.hotel,
    required this.role,
    required this.activeCount,
    required this.onStaffLogin,
    required this.onHistory,
    required this.onOpenCurrent,
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
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.history, size: 20, color: kDashText),
            tooltip: 'Incident History',
            onPressed: onHistory,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 20, color: kDashText),
            tooltip: 'Open Incident Detail',
            onPressed: onOpenCurrent,
          ),
          // QR Codes button
          IconButton(
            icon: const Icon(Icons.qr_code_2, size: 20, color: kDashText),
            tooltip: 'QR Codes',
            onPressed: () {
              context.go('/qr-generator');
            },
          ),
          // Staff Login button
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                size: 20, color: kDashText),
            tooltip: 'Staff Login',
            onPressed: onStaffLogin,
          ),
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

class _HomeSosOverview extends StatelessWidget {
  const _HomeSosOverview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: glassSurfaceDecoration,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: kDashBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kDashGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'System Status: Active',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: kDashText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Monitoring location and safety triggers',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        color: kDashTextSub,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kDashAccent.withValues(alpha: 0.4),
                          width: 4,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            kDashAccent.withValues(alpha: 0.25),
                            kDashAccent.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 156,
                          height: 156,
                          decoration: BoxDecoration(
                            color: kDashAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kDashAccent.withValues(alpha: 0.32),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SOS',
                                style: GoogleFonts.fustat(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Hold to activate',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _OverviewChip(
                          icon: Icons.shield_outlined,
                          title: 'Safe Check',
                          subtitle: 'Auto-call in 15m',
                        ),
                        _OverviewChip(
                          icon: Icons.location_on_outlined,
                          title: 'Share Location',
                          subtitle: '3 active watchers',
                        ),
                        _OverviewChip(
                          icon: Icons.call_outlined,
                          title: 'Emergency Contacts',
                          subtitle: 'Family and authorities',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OverviewChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 186,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDashBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: kDashAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: kDashTextSub,
                    fontSize: 10,
                  ),
                ),
              ],
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

    // Check if incident is unacknowledged for more than 3 minutes
    final now = DateTime.now().millisecondsSinceEpoch;
    final ageMs = now - card.lastUpdatedMs;
    final isUnacknowledged = card.status == 'ACTIVE' && ageMs > 3 * 60 * 1000;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AFFFFFF) : const Color(0x0FFFFFFF),
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
                  // Unacknowledged warning indicator
                  if (isUnacknowledged) ...[
                    const SizedBox(height: 8),
                    const _UnacknowledgedBadge(),
                  ],
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

// Pulsing badge for unacknowledged incidents
class _UnacknowledgedBadge extends StatefulWidget {
  const _UnacknowledgedBadge();

  @override
  State<_UnacknowledgedBadge> createState() => _UnacknowledgedBadgeState();
}

class _UnacknowledgedBadgeState extends State<_UnacknowledgedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: kDashWarning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: kDashWarning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: kDashWarning.withValues(
                    alpha: 0.6 + _opacityAnimation.value * 0.4),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'UNACKNOWLEDGED — ESCALATING',
                style: GoogleFonts.inter(
                  color: kDashWarning,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _summaryForState(
                  widget.incident.aiStatus, widget.incident.aiSummary),
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
                  color:
                      widget.incident.isStreamLive ? kDashDanger : kDashTextSub,
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

// ─────────────────────────────────────────────────────────────────────────────
// Staff Login Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _StaffLoginDialog extends ConsumerStatefulWidget {
  const _StaffLoginDialog();

  @override
  ConsumerState<_StaffLoginDialog> createState() => _StaffLoginDialogState();
}

class _StaffLoginDialogState extends ConsumerState<_StaffLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final current = ref.read(staffProfileProvider);

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final token = await credential.user?.getIdTokenResult(true);
      final claims = token?.claims;
      final hotelId = (claims?['hotelId'] as String?) ?? current.hotelId;
      final role = (claims?['role'] as String?) ??
          (current.role.isEmpty ? 'STAFF' : current.role);

      final profile = StaffProfile(
        uid: credential.user!.uid,
        hotelId: hotelId,
        role: role,
      );

      ref.read(staffProfileProvider.notifier).state = profile;
      await syncStaffAccessProfile(profile, email: email);
      await markStaffOnline(profile, name: email);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff login successful'),
            backgroundColor: kDashGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Login failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: kDashDanger,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kDashBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
      title: const Row(
        children: [
          Icon(Icons.person_add_outlined, color: kDashAccent, size: 24),
          SizedBox(width: 12),
          Text(
            'Staff Login',
            style: TextStyle(
                color: kDashText, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailCtrl,
              style: const TextStyle(color: kDashText),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: kDashTextSub),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: kDashTextSub, size: 20),
                filled: true,
                fillColor: const Color(0x0DFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kDashBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kDashAccent, width: 1.5),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || v.trim().isEmpty || !v.contains('@'))
                      ? 'Please enter a valid email'
                      : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              style: const TextStyle(color: kDashText),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: kDashTextSub),
                prefixIcon: const Icon(Icons.lock_outlined,
                    color: kDashTextSub, size: 20),
                filled: true,
                fillColor: const Color(0x0DFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kDashBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kDashAccent, width: 1.5),
                ),
              ),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6)
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: kDashTextSub,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: kDashAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Login'),
                    SizedBox(width: 8),
                    Icon(Icons.login, size: 18),
                  ],
                ),
        ),
      ],
    );
  }
}
