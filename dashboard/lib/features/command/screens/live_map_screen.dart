import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/incident_map_widget.dart';
import '../widgets/responder_log.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(incidentListProvider).value ?? const [];
    final profile = ref.watch(staffProfileProvider);

    if (cards.isNotEmpty &&
        (_selectedId == null ||
            !cards.any((card) => card.incidentId == _selectedId))) {
      _selectedId = cards.first.incidentId;
    }

    final selected = cards.isEmpty
        ? null
        : cards.firstWhere(
            (card) => card.incidentId == _selectedId,
            orElse: () => cards.first,
          );

    return DashboardShell(
      hotelLabel:
          profile.hotelId.isEmpty ? 'UNASSIGNED HOTEL' : profile.hotelId,
      roleLabel: profile.role.isEmpty ? 'STAFF' : profile.role,
      title: 'Live Map',
      subtitle: 'Room-level location tracking',
      activeCount: cards.length,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: DashboardPanel(
                child: cards.isEmpty
                    ? const DashboardEmptyState(
                        title: 'No mapped incidents',
                        subtitle:
                            'Live location overlays appear here when incidents carry room or GPS context.',
                        icon: Icons.map_outlined,
                      )
                    : ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final selectedCard = card.incidentId == _selectedId;
                          return InkWell(
                            onTap: () => setState(() => _selectedId = card.incidentId),
                            child: Container(
                              decoration: dashboardPanelDecoration(
                                selected: selectedCard,
                                border: selectedCard
                                    ? severityColor(card.severity)
                                        .withValues(alpha: 0.35)
                                    : kDashBorder,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room ${card.roomNumber}',
                                    style: GoogleFonts.inter(
                                      color: kDashText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${card.guestName} · ${card.primaryHazard}',
                                    style: GoogleFonts.inter(
                                      color: kDashTextSub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: selected == null
                  ? const DashboardPanel(
                      child: DashboardEmptyState(
                        title: 'Select an incident',
                        subtitle:
                            'The persisted incident location and room context render here.',
                        icon: Icons.my_location_outlined,
                      ),
                    )
                  : _SelectedIncidentMap(card: selected),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 360,
              child: selected == null
                  ? const DashboardPanel(
                      child: DashboardEmptyState(
                        title: 'No incident selected',
                        subtitle:
                            'Responder history for the selected room appears here.',
                        icon: Icons.history_outlined,
                      ),
                    )
                  : ResponderLog(incidentId: selected.incidentId),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedIncidentMap extends StatelessWidget {
  final LiveIncidentCard card;

  const _SelectedIncidentMap({required this.card});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .doc(card.incidentId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final location = data['location'] as Map<String, dynamic>?;
        final lat = (location?['lat'] as num?)?.toDouble();
        final lng = (location?['lng'] as num?)?.toDouble();
        return DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Floor ${card.floor} · Room ${card.roomNumber}',
                style: GoogleFonts.inter(
                  color: kDashText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: IncidentMapWidget(
                  lat: lat,
                  lng: lng,
                  roomNumber: card.roomNumber,
                  severity: card.severity,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
