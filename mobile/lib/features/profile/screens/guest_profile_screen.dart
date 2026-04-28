import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

class GuestProfileScreen extends ConsumerWidget {
  const GuestProfileScreen({super.key});

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0x1FFFFFFF),
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(guestProfileProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Guest Profile'),
      ),
      body: SafeArea(
        child: profile == null
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(18),
                  decoration: _panelDecoration(),
                  child: Text(
                    'No guest profile available.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: kTextMuted,
                        ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _panelDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PROFILE',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(letterSpacing: 0.9),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Guest Identity',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'This profile is attached to your active safety session.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildProfileRow(
                          context,
                          label: 'Name',
                          value: profile.guestName,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        _buildProfileRow(
                          context,
                          label: 'Hotel',
                          value: profile.hotelId,
                          icon: Icons.hotel_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildProfileRow(
                          context,
                          label: 'Room',
                          value: profile.roomNumber,
                          icon: Icons.meeting_room_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildProfileRow(
                          context,
                          label: 'Language',
                          value: profile.language.toUpperCase(),
                          icon: Icons.language,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _panelDecoration(),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  color: kSecondary, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Profile fields are read-only during an active session.',
                                  style: TextStyle(
                                    color: kTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kPanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0x1FFFFFFF),
              ),
            ),
            child: Icon(
              icon,
              color: kBrandBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
