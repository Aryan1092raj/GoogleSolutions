import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(guestProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profile == null ? const Text('No guest profile is available.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Name: ' + profile.guestName),
          const SizedBox(height: 8),
          Text('Hotel: ' + profile.hotelId),
          const SizedBox(height: 8),
          Text('Room: ' + profile.roomNumber),
          const SizedBox(height: 8),
          Text('Language: ' + profile.language),
        ]),
      ),
    );
  }
}
