import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../../../../core/severity_colors.dart' as severity_utils;
import '../providers/incident_provider.dart';
import '../widgets/action_controls.dart';
import '../widgets/command_chat_panel.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/incident_map_widget.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';
import '../widgets/transcript_panel.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() =>
      _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  String? _selectedId;
  String _query = '';
  String _severityFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(incidentListProvider).value ?? const [];
    final profile = ref.watch(staffProfileProvider);
    final filteredCards = _applyFilters(cards);

    if (filteredCards.isNotEmpty &&
        (_selectedId == null ||
            !filteredCards.any((card) => card.incidentId == _selectedId))) {
      _selectedId = filteredCards.first.incidentId;
    }

    final selected = _selectedCard(filteredCards);
    final criticalCount =
        cards.where((card) => card.severity.toUpperCase() == 'CRITICAL').length;
    final highCount =
        cards.where((card) => card.severity.toUpperCase() == 'HIGH').length;
    final averageAge = _averageAge(cards);

    return DashboardShell(
      hotelLabel:
          profile.hotelId.isEmpty ? 'UNASSIGNED HOTEL' : profile.hotelId,
      roleLabel: profile.role.isEmpty ? 'STAFF' : profile.role,
      title: 'Command Center',
      subtitle: 'Search incidents, rooms, responders',
      activeCount: cards.length,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 368,
              child: _IncidentColumn(
                cards: filteredCards,
                totalCards: cards,
                selectedId: _selectedId,
                criticalCount: criticalCount,
                highCount: highCount,
                averageAge: averageAge,
                query: _query,
                severityFilter: _severityFilter,
                onQueryChanged: (value) => setState(() => _query = value),
                onSeverityFilterChanged: (value) =>
                    setState(() => _severityFilter = value),
                onSelect: (incidentId) =>
                    setState(() => _selectedId = incidentId),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: selected == null
                  ? const DashboardPanel(
                      child: DashboardEmptyState(
                        title: 'No active incidents in view',
                        subtitle:
                            'Adjust filters or wait for the next guest incident to appear.',
                        icon: Icons.fact_check_outlined,
                      ),
                    )
                  : _WorkspaceColumn(card: selected),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 400,
              child: selected == null
                  ? const DashboardPanel(
                      child: DashboardEmptyState(
                        title: 'Select an incident',
                        subtitle:
                            'Responder actions, AI analysis, chat, and timeline appear here.',
                        icon: Icons.touch_app_outlined,
                      ),
                    )
                  : _DetailColumn(card: selected),
            ),
          ],
        ),
      ),
    );
  }

  List<LiveIncidentCard> _applyFilters(List<LiveIncidentCard> cards) {
    return cards.where((card) {
      if (_severityFilter != 'ALL' &&
          card.severity.toUpperCase() != _severityFilter) {
        return false;
      }
      if (_query.trim().isEmpty) {
        return true;
      }
      final haystack = [
        card.incidentId,
        card.roomNumber,
        card.guestName,
        card.primaryHazard,
        card.aiSummary,
      ].join(' ').toLowerCase();
      return haystack.contains(_query.trim().toLowerCase());
    }).toList();
  }

  LiveIncidentCard? _selectedCard(List<LiveIncidentCard> cards) {
    if (cards.isEmpty) {
      return null;
    }
    return cards.firstWhere(
      (card) => card.incidentId == _selectedId,
      orElse: () => cards.first,
    );
  }

  String _averageAge(List<LiveIncidentCard> cards) {
    if (cards.isEmpty) {
      return '0m';
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final totalSeconds = cards.fold<int>(0, (accumulator, card) {
      final deltaMs = now - card.lastUpdatedMs;
      return accumulator + (deltaMs ~/ 1000);
    });
    final averageSeconds = totalSeconds ~/ cards.length;
    final minutes = averageSeconds ~/ 60;
    final seconds = averageSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

class _IncidentColumn extends StatelessWidget {
  final List<LiveIncidentCard> cards;
  final List<LiveIncidentCard> totalCards;
  final String? selectedId;
  final int criticalCount;
  final int highCount;
  final String averageAge;
  final String query;
  final String severityFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSeverityFilterChanged;
  final ValueChanged<String> onSelect;

  const _IncidentColumn({
    required this.cards,
    required this.totalCards,
    required this.selectedId,
    required this.criticalCount,
    required this.highCount,
    required this.averageAge,
    required this.query,
    required this.severityFilter,
    required this.onQueryChanged,
    required this.onSeverityFilterChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatsBar(
          activeCount: totalCards.length,
          criticalCount: criticalCount,
          highCount: highCount,
          averageAge: averageAge,
        ),
        if (criticalCount > 0) ...[
          const SizedBox(height: 14),
          _CriticalBanner(criticalCount: criticalCount),
        ],
        const SizedBox(height: 14),
        Expanded(
          child: DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Incidents',
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search incidents, rooms, responders',
                    prefixIcon: Icon(Icons.search, size: 16),
                  ),
                ),
                const SizedBox(height: 14),
                _FilterChips(
                  value: severityFilter,
                  onChanged: onSeverityFilterChanged,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: cards.isEmpty
                      ? const DashboardEmptyState(
                          title: 'No incidents match this view',
                          subtitle:
                              'Clear the search or switch severity filters to restore the live board.',
                          icon: Icons.filter_alt_off_outlined,
                        )
                      : ListView.separated(
                          itemCount: cards.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return _IncidentCardTile(
                              card: card,
                              selected: card.incidentId == selectedId,
                              onTap: () => onSelect(card.incidentId),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
          .map(
            (label) => InkWell(
              onTap: () => onChanged(label),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: value == label ? kDashSurfaceActive : kDashPanel,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value == label ? kDashBorderEmphasis : kDashBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: value == label ? kDashText : kDashTextMut,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int activeCount;
  final int criticalCount;
  final int highCount;
  final String averageAge;

  const _StatsBar({
    required this.activeCount,
    required this.criticalCount,
    required this.highCount,
    required this.averageAge,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _StatCell(label: 'ACTIVE', value: '$activeCount'),
          _StatCell(
              label: 'CRITICAL', value: '$criticalCount', color: kDashDanger),
          _StatCell(label: 'HIGH', value: '$highCount', color: kDashWarning),
          _StatCell(label: 'RESPONSE AGE', value: averageAge),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCell({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: kDashBorderSubtle),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: kDashTextMut,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: color ?? kDashText,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriticalBanner extends StatelessWidget {
  final int criticalCount;

  const _CriticalBanner({required this.criticalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: dashboardPanelDecoration(
        background: kDashDanger.withValues(alpha: 0.12),
        border: kDashDanger.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: kDashDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$criticalCount critical incidents require immediate acknowledgement.',
              style: GoogleFonts.inter(
                color: kDashText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCardTile extends StatelessWidget {
  final LiveIncidentCard card;
  final bool selected;
  final VoidCallback onTap;

  const _IncidentCardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severity = card.severity.toUpperCase();
    final color = severity_utils.severityColor(severity);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: dashboardPanelDecoration(
          background: color.withValues(alpha: 0.08),
          border: selected ? color.withValues(alpha: 0.4) : kDashBorder,
          selected: selected,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 72,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.incidentId,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardMonoTextStyle(
                            color: kDashTextMut,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _relativeAge(card.lastUpdatedMs),
                        style: GoogleFonts.inter(
                          color: kDashTextDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${card.primaryHazard.replaceAll('_', ' ')} - Room ${card.roomNumber}',
                    style: GoogleFonts.inter(
                      color: kDashText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Floor ${card.floor} - ${card.guestName}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: kDashTextSub,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SeverityBadge(label: severity, color: color),
                      const SizedBox(width: 8),
                      if (card.isStreamLive)
                        Text(
                          'LIVE FEED',
                          style: GoogleFonts.inter(
                            color: kDashDanger,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
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

  String _relativeAge(int timestampMs) {
    if (timestampMs <= 0) {
      return '--';
    }
    final deltaSeconds =
        (DateTime.now().millisecondsSinceEpoch - timestampMs) ~/ 1000;
    if (deltaSeconds < 60) {
      return '${deltaSeconds}s';
    }
    return '${deltaSeconds ~/ 60}m';
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SeverityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _WorkspaceColumn extends StatelessWidget {
  final LiveIncidentCard card;

  const _WorkspaceColumn({required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: LiveFeedTile(
            hazard: card.primaryHazard,
            summary: card.aiSummary,
            incidentId: card.incidentId,
            aiStatus: card.aiStatus,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: TranscriptPanel(incidentId: card.incidentId),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _IncidentMapSurface(card: card),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncidentMapSurface extends StatelessWidget {
  final LiveIncidentCard card;

  const _IncidentMapSurface({required this.card});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<IncidentDetailRecord?>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .doc(card.incidentId)
          .snapshots()
          .map((doc) {
        final data = doc.data();
        if (data == null) {
          return null;
        }
        return IncidentDetailRecord.fromFirestore(doc.id, data);
      }),
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return IncidentMapWidget(
          lat: detail?.lat,
          lng: detail?.lng,
          roomNumber: card.roomNumber,
          severity: card.severity,
        );
      },
    );
  }
}

class _DetailColumn extends StatelessWidget {
  final LiveIncidentCard card;

  const _DetailColumn({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardPanel(
            child: _IncidentSummaryHeader(card: card),
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            child: _AiAnalysisCard(card: card),
          ),
          const SizedBox(height: 12),
          ActionControls(incidentId: card.incidentId),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ResponderLog(incidentId: card.incidentId),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: CommandChatPanel(incidentId: card.incidentId),
          ),
        ],
      ),
    );
  }
}

class _IncidentSummaryHeader extends StatelessWidget {
  final LiveIncidentCard card;

  const _IncidentSummaryHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    final severity = card.severity.toUpperCase();
    final color = severity_utils.severityColor(severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SeverityBadge(label: severity, color: color),
            const SizedBox(width: 8),
            Text(
              card.status,
              style: GoogleFonts.inter(
                color: statusColor(card.status),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Room ${card.roomNumber}',
          style: GoogleFonts.inter(
            color: kDashText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${card.guestName} · Floor ${card.floor}',
          style: GoogleFonts.inter(
            color: kDashTextSub,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  final LiveIncidentCard card;

  const _AiAnalysisCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final severity = card.severity.toUpperCase();
    final severityColor = severity_utils.severityColor(severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI ANALYSIS',
          style: GoogleFonts.inter(
            color: kDashTextMut,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'STATUS',
              style: GoogleFonts.inter(
                color: kDashTextMut,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              card.aiStatus,
              style: GoogleFonts.inter(
                color: statusColor(card.aiStatus),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'SEVERITY',
              style: GoogleFonts.inter(
                color: kDashTextMut,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              severity,
              style: GoogleFonts.inter(
                color: severityColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: switch (severity) {
            'CRITICAL' => 1,
            'HIGH' => 0.75,
            'MEDIUM' => 0.5,
            _ => 0.25,
          },
          minHeight: 4,
          backgroundColor: kDashPanel,
          valueColor: AlwaysStoppedAnimation<Color>(severityColor),
        ),
        const SizedBox(height: 12),
        Text(
          card.aiSummary.isEmpty
              ? 'Awaiting AI analysis from the incident stream.'
              : card.aiSummary,
          style: GoogleFonts.inter(
            color: card.aiSummary.isEmpty ? kDashTextMut : kDashTextSub,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
