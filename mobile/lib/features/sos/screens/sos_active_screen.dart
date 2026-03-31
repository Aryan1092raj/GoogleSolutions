import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/severity_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sos_provider.dart';
import '../providers/stream_provider.dart';
import '../widgets/incident_chat_panel.dart';

class SOSActiveScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const SOSActiveScreen({super.key, required this.incidentId});

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final AnimationController _severityFlashController;
  final _start = DateTime.now();
  bool _streamStartRequested = false;
  String? _previousSeverity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    _severityFlashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    Future.microtask(() async {
      if (!mounted || _streamStartRequested) {
        return;
      }
      _streamStartRequested = true;
      await ref.read(streamProvider.notifier).startStreaming(widget.incidentId);
    });
  }

  @override
  void dispose() {
    ref.read(streamProvider.notifier).stopStreaming();
    _pulseController.dispose();
    _slideController.dispose();
    _severityFlashController.dispose();
    super.dispose();
  }

  String get _elapsed {
    final d = DateTime.now().difference(_start);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Trigger flash animation 3 times when severity escalates
  void _triggerSeverityFlash() {
    int flashCount = 0;
    const maxFlashes = 6; // 3 on/off cycles

    void flashCallback() {
      flashCount++;
      if (flashCount < maxFlashes) {
        _severityFlashController.forward(from: 0);
      }
    }

    _severityFlashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        flashCallback();
      }
    });

    flashCallback();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(streamProvider);
    final state = ref.watch(sosProvider);
    final profile = ref.watch(guestProfileProvider);
    final severity = state.severity ?? 'LOW';
    final message = state.aiMessage ?? 'Analyzing emergency...';
    final severityColorVal = severityColor(severity);

    // Trigger flash animation when severity escalates to HIGH or CRITICAL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previousSeverity != null &&
          _previousSeverity != severity &&
          (severity == 'HIGH' || severity == 'CRITICAL')) {
        _triggerSeverityFlash();
      }
      _previousSeverity = severity;
    });

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          // Camera preview background would be here (handled by parent or overlay)
          Positioned.fill(
            child: Container(color: kBackground),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kBackground.withValues(alpha: 0.75),
                    Colors.transparent,
                    kBackground.withValues(alpha: 0.92),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildTopBar(severity),
                  const Spacer(),
                  _buildBottomPanel(
                    context,
                    state,
                    profile,
                    severity,
                    message,
                    severityColorVal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String severity) {
    return Row(
      children: [
        // EMERGENCY ACTIVE pill
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.5 * _pulseController.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Blinking white dot
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: 0.5 + _pulseController.value * 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EMERGENCY ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Spacer(),
        // LIVE badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: glassSurfaceDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimary.withValues(
                        alpha: 0.8 + _pulseController.value * 0.2,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Elapsed timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: glassSurfaceDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (_, __) => Text(
                  _elapsed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    SOSState state,
    GuestProfile? profile,
    String severity,
    String message,
    Color severityColorVal,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: kBackground.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: severityColorVal.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity badge
              _buildSeverityBadge(severity, severityColorVal),
              const SizedBox(height: 14),
              // AI Status card
              _buildAIStatusCard(state, severity, message, severityColorVal),
              const SizedBox(height: 14),
              // Chat panel
              IncidentChatPanel(
                incidentId: widget.incidentId,
                profile: profile,
              ),
              const SizedBox(height: 14),
              // Action buttons
              _buildActionButtons(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity, Color severityColorVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: severityColorVal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: severityColorVal.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severityIcon(severity),
            color: severityColorVal,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            severity,
            style: TextStyle(
              color: severityColorVal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatusCard(
    SOSState state,
    String severity,
    String message,
    Color severityColorVal,
  ) {
    return AnimatedBuilder(
      animation: _severityFlashController,
      builder: (context, child) {
        // Calculate flash opacity: oscillates between 0 and 1
        final flashValue = _severityFlashController.isAnimating
            ? _severityFlashController.value
            : 0.0;
        
        // Border color flashes between severity color and transparent
        final animatedBorderColor = severityColorVal.withValues(
          alpha: 0.4 + (flashValue * 0.6), // Oscillates between 0.4 and 1.0
        );

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: glassSurfaceDecoration.copyWith(
            border: Border.all(
              color: animatedBorderColor,
              width: 1.5,
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColorVal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  severityIcon(severity),
                  color: severityColorVal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColorVal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(
                          color: severityColorVal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          state.helpOnWay
                              ? Icons.local_shipping_outlined
                              : Icons.send_outlined,
                          color: state.helpOnWay ? kSecondary : kTextMuted,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.helpOnWay ? 'Help is on the way' : 'Dispatching...',
                          style: TextStyle(
                            color: state.helpOnWay ? kSecondary : kTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // AI Message
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0x1AFFFFFF),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  color: kSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SOSState state) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'False Alarm',
            icon: Icons.close,
            isPrimary: false,
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                context: context,
                title: 'False Alarm?',
                message: 'Are you sure this is a false alarm?',
              );
              if (confirm == true && context.mounted) {
                await ref.read(sosProvider.notifier).endSOS('FALSE_ALARM');
                if (context.mounted) {
                  context.go('/sos/resolved/${widget.incidentId}');
                }
              }
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'End Emergency',
            icon: Icons.check,
            isPrimary: true,
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                context: context,
                title: 'End Emergency?',
                message: 'Only end if the situation is resolved.',
              );
              if (confirm == true && context.mounted) {
                await ref.read(sosProvider.notifier).endSOS('RESOLVED_BY_GUEST');
                if (context.mounted) {
                  context.go('/sos/resolved/${widget.incidentId}');
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? kPrimary : Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: Color(0x4DFFFFFF)),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: kTextPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTextMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
