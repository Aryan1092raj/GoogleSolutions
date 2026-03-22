import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/sos_provider.dart';
import '../widgets/sos_trigger_button.dart';

class SOSHomeScreen extends ConsumerWidget {
  const SOSHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(guestProfileProvider);
    final sosState = ref.watch(sosProvider);

    final hotel = profile == null ? '-' : profile.hotelId;
    final room = profile == null ? '-' : profile.roomNumber;
    final language = profile == null ? 'en' : profile.language;

    return Scaffold(
      appBar: AppBar(title: const Text('ResQLink SOS')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hotel: ' + hotel + '  Room: ' + room),
            const SizedBox(height: 20),
            SOSTriggerButton(
              onPressed: () async {
                await ref.read(sosProvider.notifier).triggerSOS();
                final state = ref.read(sosProvider);
                if (state.status == SOSStatus.error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error ?? 'Unable to trigger SOS')),
                    );
                  }
                  return;
                }
                final id = state.incidentId ?? DateTime.now().millisecondsSinceEpoch.toString();
                if (context.mounted) {
                  context.go('/sos/active/' + id);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Hold for 2 seconds to trigger emergency'),
            const SizedBox(height: 16),
            Text('Language: ' + language),
            if (sosState.status == SOSStatus.initiating) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
