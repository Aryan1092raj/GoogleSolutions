import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_card.dart';
import '../widgets/live_feed_tile.dart';
import '../widgets/responder_log.dart';

class CommandCenterScreen extends ConsumerWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentListProvider);
    final profile = ref.watch(staffProfileProvider);
    final cards = incidentsAsync.value == null ? [] : incidentsAsync.value as List;
    final selected = cards.isEmpty ? null : cards.first;
    final hotel = profile.hotelId.isEmpty ? 'Unassigned' : profile.hotelId;
    return Scaffold(
      appBar: AppBar(title: Text('ResQLink Dashboard  Hotel: ' + hotel + '  Active: ' + cards.length.toString())),
      body: Row(children: [
        SizedBox(
          width: 320,
          child: cards.isEmpty ? const Center(child: Text('No active incidents')) : ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return IncidentCard(title: 'INCIDENT ' + card.incidentId.toString(), severity: card.severity.toString(), room: 'Room ' + card.roomNumber.toString(), floor: 'Floor ' + card.floor.toString());
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
