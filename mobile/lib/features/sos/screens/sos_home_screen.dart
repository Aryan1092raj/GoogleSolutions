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
    final profile = ref.watch(guestProfileProvider);
    final sosState = ref.watch(sosProvider);
    final hotel = profile?.hotelId ?? '—';
    final room = profile?.roomNumber ?? '—';
    final lang = profile?.language ?? 'en';

    return Scaffold(
      body: Stack(
        children: [
          // Dark background
          Container(color: kBackground),
          // Background glow
          buildBackgroundGlow(alignment: Alignment.topLeft),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildContextBar(context, hotel, room),
                Expanded(
                  child: _buildMainContent(context, ref, sosState),
                ),
                _buildLanguagePill(lang),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBar(BuildContext context, String hotel, String room) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: glassSurfaceDecoration,
      child: Row(
        children: [
          // Shield icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, Color(0xFFff5545)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Hotel & Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Row(
                  children: [
                    const Icon(Icons.meeting_room, color: kTextMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Room $room',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connection badge
          _buildConnectionBadge(),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kSecondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kSecondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: kSecondary, size: 8),
          SizedBox(width: 6),
          Text(
            'Connected',
            style: TextStyle(
              color: kSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, SOSState sosState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero icon with glow
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 118,
              height: 118,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, Color(0xFFFF6B5B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.34),
                    blurRadius: 40,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          // Headline
          Text(
            'One hold. Live relay. Help moving.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 12),
          // Instruction text
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'If you are in danger, press and hold. Your room, camera feed, and live updates go straight to the security desk.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.65,
                    fontSize: 15,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          // Feature pills
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _HomeSignal(label: 'Live video relay', icon: Icons.videocam_outlined),
              _HomeSignal(label: 'Location context', icon: Icons.location_on_outlined),
              _HomeSignal(label: 'Rescue channel', icon: Icons.forum_outlined),
            ],
          ),
          const SizedBox(height: 42),
          // SOS Trigger Button
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
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                return;
              }
              context.go('/sos/active/${state.incidentId}');
            },
          ),
          const SizedBox(height: 28),
          // Reassurance pill
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: sosState.status == SOSStatus.initiating
                ? _buildConnectingIndicator()
                : Container(
                    key: const ValueKey('reassurance'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: glassSurfaceDecoration,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_moon_outlined, color: kSecondary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Stay calm. The emergency desk is on standby.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: kTextPrimary,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: kPrimary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Connecting to emergency services...',
            style: TextStyle(
              color: kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: glassSurfaceDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: kSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              lang.toUpperCase(),
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSignal extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HomeSignal({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: glassSurfaceDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kSecondary, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
