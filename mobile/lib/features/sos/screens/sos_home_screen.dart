import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../services/sos_queue_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sos_provider.dart';
import '../widgets/sos_trigger_button.dart';

class SOSHomeScreen extends ConsumerStatefulWidget {
  const SOSHomeScreen({super.key});

  @override
  ConsumerState<SOSHomeScreen> createState() => _SOSHomeScreenState();
}

class _SOSHomeScreenState extends ConsumerState<SOSHomeScreen> {
  bool _hasPendingSOS = false;

  @override
  void initState() {
    super.initState();
    _checkPendingSOS();
  }

  Future<void> _checkPendingSOS() async {
    final hasPending = await SOSQueueService.hasPending();
    if (mounted) {
      setState(() {
        _hasPendingSOS = hasPending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final profile = ref.watch(guestProfileProvider);
    final sosState = ref.watch(sosProvider);
    final hotel = profile?.hotelId ?? '—';
    final room = profile?.roomNumber ?? '—';
    final lang = profile?.language ?? 'en';

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            if (_hasPendingSOS) _buildPendingBanner(ref),
            _buildContextBar(context, hotel, room),
            Expanded(
              child: _buildMainContent(context, ref, sosState),
            ),
            _buildLanguagePill(lang),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x26F59E0B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x66F59E0B),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending SOS',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Waiting for connection to submit',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await ref.read(sosProvider.notifier).triggerSOS();
              final state = ref.read(sosProvider);
              if (state.status != SOSStatus.queued &&
                  state.status != SOSStatus.error) {
                setState(() {
                  _hasPendingSOS = false;
                });
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16),
                SizedBox(width: 6),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildContextBar(BuildContext context, String hotel, String room) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sos_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hotel $hotel',
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
          _buildConnectionBadge(),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1A22C55E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x6622C55E),
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

  Widget _buildMainContent(
      BuildContext context, WidgetRef ref, SOSState sosState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmergencyPanel(context),
              const SizedBox(height: 16),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HomeSignal(
                      label: 'Live video relay', icon: Icons.videocam_outlined),
                  _HomeSignal(
                      label: 'Location context',
                      icon: Icons.location_on_outlined),
                  _HomeSignal(
                      label: 'Rescue channel', icon: Icons.forum_outlined),
                ],
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: sosState.status == SOSStatus.initiating
                    ? _buildConnectingIndicator()
                    : _buildStandbyNotice(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMERGENCY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.9,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emergency Relay Console',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x22EF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x66EF4444)),
                ),
                child: const Text(
                  'ARMED',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Press and hold SOS if you are in danger. Room context, live media, and updates route to the security desk immediately.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kTextSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingIndicator() {
    return Container(
      key: const ValueKey('connecting'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: kPrimary,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Connecting to emergency services...',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandbyNotice(BuildContext context) {
    return Container(
      key: const ValueKey('standby'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.shield_moon_outlined, color: kSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Stay calm. The emergency desk is on standby.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kTextPrimary,
                    fontSize: 13,
                  ),
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
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0x1FFFFFFF),
            width: 1,
          ),
        ),
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
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x1FFFFFFF),
          width: 1,
        ),
      ),
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
