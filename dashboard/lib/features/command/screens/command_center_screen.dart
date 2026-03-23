import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  String? _selectedIncidentId;

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentListProvider);
    final profile = ref.watch(staffProfileProvider);
    final cards = incidentsAsync.value ?? <LiveIncidentCard>[];
    if (cards.isNotEmpty && _selectedIncidentId == null) {
      _selectedIncidentId = cards.first.incidentId;
    }
    final selected = cards.where((c) => c.incidentId == _selectedIncidentId).isNotEmpty
        ? cards.firstWhere((c) => c.incidentId == _selectedIncidentId)
        : (cards.isEmpty ? null : cards.first);
    final hotel = profile.hotelId.isEmpty ? 'Unassigned' : profile.hotelId;

    return Scaffold(
      appBar: AppBar(title: Text('ResQLink Dashboard  Hotel: ' + hotel + '  Active: ' + cards.length.toString())),
      body: Row(children: [
        SizedBox(
          width: 360,
          child: cards.isEmpty ? const Center(child: Text('No active incidents')) : ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIncidentId = card.incidentId;
                  });
                },
                child: IncidentCard(
                  title: 'INCIDENT ${card.incidentId}',
                  severity: card.severity,
                  room: 'Room ${card.roomNumber}',
                  floor: 'Floor ${card.floor}',
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Expanded(child: LiveFeedTile(hazard: selected == null ? 'UNKNOWN' : selected.primaryHazard.toString(), summary: selected == null ? '' : selected.aiSummary.toString())),
              const SizedBox(height: 8),
              Expanded(child: ResponderLog(incidentId: selected == null ? '-' : selected.incidentId.toString())),
            ]),
          ),
        ),
      ]),
    );
  }
}
