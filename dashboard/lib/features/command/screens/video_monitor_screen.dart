import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';
import '../providers/incident_provider.dart';
import '../widgets/dashboard_shell.dart';
import '../widgets/live_feed_tile.dart';

class VideoMonitorScreen extends ConsumerWidget {
  const VideoMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(incidentListProvider).value ?? const [];
    final profile = ref.watch(staffProfileProvider);
    final liveCards = cards.where((card) => card.isStreamLive).toList();

    return DashboardShell(
      hotelLabel:
          profile.hotelId.isEmpty ? 'UNASSIGNED HOTEL' : profile.hotelId,
      roleLabel: profile.role.isEmpty ? 'STAFF' : profile.role,
      title: 'Video Monitor',
      subtitle: 'Multi-room live feed monitor',
      activeCount: cards.length,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardPanel(
          child: liveCards.isEmpty
              ? const DashboardEmptyState(
                  title: 'No live streams available',
                  subtitle:
                      'Guest camera feeds appear here as incidents enter active relay state.',
                  icon: Icons.videocam_off_outlined,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Relay Grid',
                      style: GoogleFonts.inter(
                        color: kDashText,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: liveCards.length,
                        itemBuilder: (context, index) {
                          final card = liveCards[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      'Room ${card.roomNumber}',
                                      style: GoogleFonts.inter(
                                        color: kDashText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      card.severity,
                                      style: GoogleFonts.inter(
                                        color: severityColor(card.severity),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: LiveFeedTile(
                                  hazard: card.primaryHazard,
                                  summary: card.aiSummary,
                                  incidentId: card.incidentId,
                                  aiStatus: card.aiStatus,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
