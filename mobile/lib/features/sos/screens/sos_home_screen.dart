import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sos_provider.dart';

class SOSHomeScreen extends ConsumerWidget {
  const SOSHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(guestProfileProvider);
    final hotel = profile == null ? '-' : profile.hotelId;
    final room = profile == null ? '-' : profile.roomNumber;
    final language = profile == null ? 'en' : profile.language;
    return Scaffold(
      appBar: AppBar(title: const Text('ResQLink SOS')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Hotel: ' + hotel + '  Room: ' + room),
          const SizedBox(height: 20),
          GestureDetector(
            onLongPress: () async {
              await ref.read(sosProvider.notifier).triggerSOS();
              final state = ref.read(sosProvider);
              final id = state.incidentId == null ? DateTime.now().millisecondsSinceEpoch.toString() : state.incidentId.toString();
              if (context.mounted) {
                context.go('/sos/active/' + id);
              }
            },
            child: Container(width: 160, height: 160, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 32))),
          ),
          const SizedBox(height: 16),
          const Text('Hold for 2 seconds to trigger emergency'),
          const SizedBox(height: 16),
          Text('Language: ' + language),
        ]),
      ),
    );
  }
}
