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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackground, Color(0xFF0A1929)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildContextBar(hotel, room),
            Expanded(
              child: _buildMainContent(context, ref, sosState),
            ),
            _buildLanguagePill(lang),
          ]),
        ),
      ),
    );
  }

  Widget _buildContextBar(String hotel, String room) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kSurface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: kSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, Color(0xFFff5545)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotel,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.meeting_room, color: kTextMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Room $room',
                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildConnectionBadge(),
      ]),
    );
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
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
      ]),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, SOSState sosState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, Color(0xFFff5545)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: Text(
            'ResQLink',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hold the button for 2 seconds\nto trigger emergency',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.6,
                fontSize: 15,
              ),
        ),
        const SizedBox(height: 48),
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
        const SizedBox(height: 48),
        if (sosState.status == SOSStatus.initiating)
          _buildConnectingIndicator(),
      ],
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
      child: Column(children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: kPrimary,
            strokeWidth: 3,
            backgroundColor: kSurface,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connecting to emergency services...',
          style: TextStyle(
            color: kTextMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }

  Widget _buildLanguagePill(String lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kTextMuted.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    );
  }
}
