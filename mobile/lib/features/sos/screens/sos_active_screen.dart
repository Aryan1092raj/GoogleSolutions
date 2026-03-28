import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../services/camera_service.dart';
import '../providers/sos_provider.dart';
import '../providers/stream_provider.dart';

class SOSActiveScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const SOSActiveScreen({super.key, required this.incidentId});

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen>
    with TickerProviderStateMixin {
  late final CameraService _camera;
  late final Future<void> _cameraInit;
  final _start = DateTime.now();
  late final AnimationController _pulseController;
  late final AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(cameraServiceProvider);
    _cameraInit = _camera.initialize();
    Future.microtask(() =>
        ref.read(streamProvider.notifier).startStreaming(widget.incidentId));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    ref.read(streamProvider.notifier).stopStreaming();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String get _elapsed {
    final d = DateTime.now().difference(_start);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'CRITICAL':
        return const Color(0xFFFF3B30);
      case 'HIGH':
        return const Color(0xFFFF6B35);
      case 'MEDIUM':
        return const Color(0xFFFFCC00);
      default:
        return kSecondary;
    }
  }

  IconData _severityIcon(String? s) {
    switch (s) {
      case 'CRITICAL':
        return Icons.warning_amber_rounded;
      case 'HIGH':
        return Icons.error_outline;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosProvider);
    final severity = state.severity ?? 'LOW';
    final message = state.aiMessage ?? 'Analyzing emergency...';

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(children: [
        Positioned.fill(
          child: FutureBuilder(
            future: _cameraInit,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.done) {
                return _camera.buildPreview();
              }
              return Container(
                color: kSurface,
                child: const Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0, 0.35, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildTopBar(severity),
                const Spacer(),
                _buildBottomPanel(context, state, severity, message),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTopBar(String severity) {
    return Row(children: [
      AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.9 + (_pulseController.value * 0.1)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.5 * _pulseController.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                Icons.sos,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'SOS ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ]),
          );
        },
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF3B30).withOpacity(0.8 + (_pulseController.value * 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF3B30).withOpacity(0.5 * _pulseController.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
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
        ]),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    ]);
  }

  Widget _buildBottomPanel(
      BuildContext context, SOSState state, String severity, String message) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAIStatusCard(state, severity, message),
            const SizedBox(height: 16),
            _buildActionButtons(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildAIStatusCard(SOSState state, String severity, String message) {
    final severityClr = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: severityClr.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: severityClr.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityClr.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _severityIcon(severity),
                color: severityClr,
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
                      color: severityClr.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                        color: severityClr,
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
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
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
                      color: Colors.white,
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
    return Row(children: [
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
              ref.read(streamProvider.notifier).stopStreaming();
              await ref.read(sosProvider.notifier).endSOS('RESOLVED_BY_GUEST');
              if (context.mounted) {
                context.go('/sos/resolved/${widget.incidentId}');
              }
            }
          },
        ),
      ),
    ]);
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
                  color: kPrimary.withOpacity(0.3),
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
                : BorderSide(color: kTextMuted.withOpacity(0.3)),
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
          style: const TextStyle(
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
