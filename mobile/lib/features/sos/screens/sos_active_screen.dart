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

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen> {
  late final CameraService _camera;
  late final Future<void> _cameraInit;
  final _start = DateTime.now();

  @override
  void initState() {
    super.initState();
    _camera = ref.read(cameraServiceProvider);
    _cameraInit = _camera.initialize();
    Future.microtask(() =>
      ref.read(streamProvider.notifier).startStreaming(widget.incidentId));
  }

  @override
  void dispose() {
    ref.read(streamProvider.notifier).stopStreaming();
    super.dispose();
  }

  String get _elapsed {
    final d = DateTime.now().difference(_start);
    final m = d.inMinutes.toString().padLeft(2,'0');
    final s = (d.inSeconds % 60).toString().padLeft(2,'0');
    return '$m:$s';
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'CRITICAL': return const Color(0xFFFF3B30);
      case 'HIGH':     return const Color(0xFFFF6B35);
      case 'MEDIUM':   return const Color(0xFFFFCC00);
      default:         return kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(sosProvider);
    final severity = state.severity ?? 'LOW';
    final message  = state.aiMessage ?? 'Analyzing emergency...';

    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(children: [
        // camera full screen
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
                  child: CircularProgressIndicator(color: kPrimary)),
              );
            },
          ),
        ),

        // dark overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0, 0.4, 1],
              ),
            ),
          ),
        ),

        // top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 5),
                  Text('EMERGENCY ACTIVE',
                    style: TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
              ),
              const Spacer(),
              // live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, color: Color(0xFFFF3B30), size: 8),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
              ),
              const SizedBox(width: 8),
              // timer
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (_, __) => Text(_elapsed,
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 13,
                    fontFamily: 'monospace')),
              ),
            ]),
          ),
        ),

        // bottom panel
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AI status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _severityColor(severity).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _severityColor(severity).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(severity,
                              style: TextStyle(
                                color: _severityColor(severity),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.helpOnWay
                              ? 'Help is on the way'
                              : 'Dispatching...',
                            style: const TextStyle(
                              color: kSecondary, fontSize: 12)),
                        ]),
                        const SizedBox(height: 8),
                        Text(message,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 14,
                            height: 1.4)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextMuted,
                          side: BorderSide(color: kTextMuted.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: kSurface,
                              title: const Text('False Alarm?',
                                style: TextStyle(color: kTextPrimary)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm',
                                    style: TextStyle(color: kPrimary))),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref.read(sosProvider.notifier)
                              .endSOS('FALSE_ALARM');
                            if (context.mounted) {
                              context.go('/sos/resolved/${widget.incidentId}');
                            }
                          }
                        },
                        child: const Text('False Alarm'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: kSurface,
                              title: const Text('End Emergency?',
                                style: TextStyle(color: kTextPrimary)),
                              content: const Text(
                                'Only end if the situation is resolved.',
                                style: TextStyle(color: kTextMuted)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('End',
                                    style: TextStyle(color: kPrimary))),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            ref.read(streamProvider.notifier).stopStreaming();
                            await ref.read(sosProvider.notifier)
                              .endSOS('RESOLVED_BY_GUEST');
                            if (context.mounted) {
                              context.go('/sos/resolved/${widget.incidentId}');
                            }
                          }
                        },
                        child: const Text('End Emergency'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
