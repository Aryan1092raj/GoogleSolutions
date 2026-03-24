import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sos_provider.dart';
import '../widgets/sos_trigger_button.dart';

class SOSHomeScreen extends ConsumerWidget {
  const SOSHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile  = ref.watch(guestProfileProvider);
    final sosState = ref.watch(sosProvider);
    final hotel    = profile?.hotelId    ?? '—';
    final room     = profile?.roomNumber ?? '—';
    final lang     = profile?.language   ?? 'en';

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // ── context bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: kSurface,
            child: Row(children: [
              const Icon(Icons.hotel, color: kSecondary, size: 16),
              const SizedBox(width: 8),
              Text(hotel, style: const TextStyle(color: kTextPrimary, fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.meeting_room, color: kTextMuted, size: 14),
              const SizedBox(width: 4),
              Text('Room $room', style: const TextStyle(color: kTextMuted, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, color: kSecondary, size: 8),
                  SizedBox(width: 4),
                  Text('Connected', style: TextStyle(color: kSecondary, fontSize: 11)),
                ]),
              ),
            ]),
          ),

          // ── main content ──
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ResQLink', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Hold the button for 2 seconds\nto trigger emergency',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 56),

                // SOS button
                SOSTriggerButton(
                  onPressed: () async {
                    await ref.read(sosProvider.notifier).triggerSOS();
                    final state = ref.read(sosProvider);
                    if (!context.mounted) return;
                    if (state.status == SOSStatus.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error ?? 'Failed'),
                          backgroundColor: kPrimary,
                        ),
                      );
                      return;
                    }
                    context.go('/sos/active/${state.incidentId}');
                  },
                ),

                const SizedBox(height: 48),

                if (sosState.status == SOSStatus.initiating)
                  const Column(children: [
                    CircularProgressIndicator(color: kPrimary),
                    SizedBox(height: 12),
                    Text('Connecting...', style: TextStyle(color: kTextMuted, fontSize: 13)),
                  ]),
              ],
            ),
          ),

          // ── language pill ──
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.language, color: kTextMuted, size: 14),
                const SizedBox(width: 6),
                Text(lang.toUpperCase(),
                  style: const TextStyle(color: kTextMuted, fontSize: 12, letterSpacing: 1)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
