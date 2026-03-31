import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(guestProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Profile'),
      ),
      body: Stack(
        children: [
          Container(color: kBackground),
          buildBackgroundGlow(alignment: Alignment.topLeft),
          SafeArea(
            child: profile == null
                ? Center(
                    child: Text(
                      'No guest profile available.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: kTextMuted,
                          ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: glassSurfaceDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileRow(
                            context,
                            label: 'Name',
                            value: profile.guestName,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileRow(
                            context,
                            label: 'Hotel',
                            value: profile.hotelId,
                            icon: Icons.hotel_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileRow(
                            context,
                            label: 'Room',
                            value: profile.roomNumber,
                            icon: Icons.meeting_room_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildProfileRow(
                            context,
                            label: 'Language',
                            value: profile.language.toUpperCase(),
                            icon: Icons.language,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBrandBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: kBrandBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
