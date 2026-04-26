import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/severity_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sos_active_panel.dart';
import '../providers/sos_provider.dart';
import '../providers/stream_provider.dart' as sos_stream;
import '../widgets/incident_chat_panel.dart';
import '../widgets/sos_guide_panel.dart';
import '../widgets/sos_overview_panel.dart';

const _bg = Color(0xFF09090B);
const _surface = Color(0xFF121215);
const _surfaceHigh = Color(0xFF18181B);
const _surfaceHighest = Color(0xFF1E1E22);
const _outlineVariant = Color(0xFF27272A);
const _primary = Color(0xFFA78BFA);
const _primaryContainer = Color(0xFF7C3AED);
const _onSurface = Color(0xFFFAFAFA);
const _onSurfaceMuted = Color(0xFFA1A1AA);
const _tertiary = Color(0xFF34D399);
const _error = Color(0xFFEF4444);

class _CameraPreviewLayer extends ConsumerWidget {
  const _CameraPreviewLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = ref.watch(cameraServiceProvider);
    final preview = camera.buildPreview();
    if (!preview.toString().contains('CameraPreview')) {
      return Container(
        color: _surface,
        child: const Center(
          child: CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: preview,
        ),
      ),
    );
  }
}

class SOSActiveScreen extends ConsumerStatefulWidget {
  final String incidentId;
  final SOSActivePanel initialPanel;
  final bool autoStartStreaming;
  const SOSActiveScreen({
    super.key,
    required this.incidentId,
    this.initialPanel = SOSActivePanel.sos,
    this.autoStartStreaming = true,
  });

  @override
  ConsumerState<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final AnimationController _severityFlashController;
  late final sos_stream.StreamNotifier _streamNotifier;
  late final SOSNotifier _sosNotifier;
  final _start = DateTime.now();
  bool _streamStartRequested = false;
  String? _previousSeverity;
  ProviderSubscription<SOSState>? _sosSubscription;

  Timer? _etaTimer;
  int _etaSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _streamNotifier = ref.read(sos_stream.streamProvider.notifier);
    _sosNotifier = ref.read(sosProvider.notifier);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    )..forward();

    _severityFlashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sosSubscription = ref.listenManual<SOSState>(sosProvider, (
      previous,
      next,
    ) {
      if (next.etaMinutes != null &&
          next.etaMinutes != _etaSecondsRemaining ~/ 60) {
        _startEtaTimer(next.etaMinutes!);
      }
    });

    Future.microtask(() async {
      if (!mounted) {
        return;
      }
      _sosNotifier.observeIncident(widget.incidentId);
      if (_streamStartRequested || !widget.autoStartStreaming) {
        return;
      }
      _streamStartRequested = true;
      await _streamNotifier.startStreaming(widget.incidentId);
    });
  }

  void _startEtaTimer(int etaMinutes) {
    _etaTimer?.cancel();
    _etaSecondsRemaining = etaMinutes * 60;

    _etaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_etaSecondsRemaining > 0) {
          _etaSecondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _streamNotifier.stopStreaming();
    _pulseController.dispose();
    _slideController.dispose();
    _severityFlashController.dispose();
    _etaTimer?.cancel();
    _sosSubscription?.close();
    super.dispose();
  }

  String get _elapsed {
    final d = DateTime.now().difference(_start);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _triggerSeverityFlash() async {
    if (_severityFlashController.isAnimating || !mounted) {
      return;
    }
    for (var i = 0; i < 3; i++) {
      if (!mounted) {
        return;
      }
      await _severityFlashController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sos_stream.streamProvider);
    final state = ref.watch(sosProvider);
    final profile = ref.watch(guestProfileProvider);
    final activePanel = widget.initialPanel;
    final severity = (state.severity ?? 'LOW').toUpperCase();
    final message = state.aiMessage ??
        'Security is on the way. Stay calm and remain in place.';
    final severityColorVal = severityColor(severity);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previousSeverity != null &&
          _previousSeverity != severity &&
          (severity == 'HIGH' || severity == 'CRITICAL')) {
        _triggerSeverityFlash();
      }
      _previousSeverity = severity;
    });

    if (state.status == SOSStatus.queued) {
      return _buildQueuedOverlay();
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0C0C0F), _bg],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopHeader(profile),
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 126),
                      child: _buildPanelContent(
                        context: context,
                        profile: profile,
                        state: state,
                        activePanel: activePanel,
                        severity: severity,
                        message: message,
                        severityColorVal: severityColorVal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(GuestProfile? profile) {
    final hotel = (profile?.hotelId.trim().isNotEmpty ?? false)
        ? profile!.hotelId.trim()
        : 'Hotel';
    final room = (profile?.roomNumber.trim().isNotEmpty ?? false)
        ? profile!.roomNumber.trim()
        : '--';
    final initial = (profile?.guestName.trim().isNotEmpty ?? false)
        ? profile!.guestName.trim().substring(0, 1).toUpperCase()
        : 'G';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(
            color: _outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emergency_share,
            color: _primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$hotel • Room $room',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: _outlineVariant),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: _onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStreamCard(String severity, Color severityColorVal) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _CameraPreviewLayer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bg.withValues(alpha: 0.10),
                      _bg.withValues(alpha: 0.22),
                      _bg.withValues(alpha: 0.76),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildCapsule(
                  leading: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _error.withValues(
                            alpha: 0.72 + (0.28 * _pulseController.value),
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  label: 'LIVE STREAM ACTIVE',
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildCapsule(
                  leading: const Icon(
                    Icons.mic,
                    color: _primary,
                    size: 14,
                  ),
                  label: 'AUDIO ON',
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              color: _onSurfaceMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Severity Level: ${_toTitle(severity)}',
                            style: TextStyle(
                              color: severityColorVal,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'DURATION',
                          style: TextStyle(
                            color: _onSurfaceMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (_, __) => Text(
                            _elapsed,
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsule({required Widget leading, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
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
        final flashValue = _severityFlashController.isAnimating
            ? _severityFlashController.value
            : 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  severityColorVal.withValues(alpha: 0.18 + flashValue * 0.56),
            ),
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: _primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI SAFETY ASSISTANT',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                state.helpOnWay ? Icons.security : Icons.send_rounded,
                color: state.helpOnWay ? _tertiary : _onSurfaceMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.helpOnWay ? 'Dispatch confirmed' : 'Dispatching...',
                  style: TextStyle(
                    color: state.helpOnWay ? _tertiary : _onSurfaceMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.etaMinutes != null)
                Text(
                  _etaSecondsRemaining > 0
                      ? _formatCountdown(_etaSecondsRemaining)
                      : 'Arriving now',
                  style: const TextStyle(
                    color: _primary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                severityIcon(severity),
                color: severityColorVal,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Severity: ${_toTitle(severity)}',
                style: TextStyle(
                  color: severityColorVal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'False Alarm',
            icon: Icons.backspace_outlined,
            backgroundColor: _surface,
            foregroundColor: _onSurface,
            borderColor: _outlineVariant,
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
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            label: 'End Emergency',
            icon: Icons.cancel_outlined,
            backgroundColor: const Color(0xFF3B1111),
            foregroundColor: const Color(0xFFFCA5A5),
            borderColor: _error.withValues(alpha: 0.35),
            onPressed: () async {
              final confirm = await _showConfirmDialog(
                context: context,
                title: 'End Emergency?',
                message: 'Only end if the situation is resolved.',
              );
              if (confirm == true && context.mounted) {
                await ref
                    .read(sosProvider.notifier)
                    .endSOS('RESOLVED_BY_GUEST');
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
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelContent({
    required BuildContext context,
    required GuestProfile? profile,
    required SOSState state,
    required SOSActivePanel activePanel,
    required String severity,
    required String message,
    required Color severityColorVal,
  }) {
    switch (activePanel) {
      case SOSActivePanel.messages:
        return SingleChildScrollView(
          child: IncidentChatPanel(
            incidentId: widget.incidentId,
            profile: profile,
            expanded: true,
          ),
        );
      case SOSActivePanel.guide:
        return SingleChildScrollView(
          child: SOSGuidePanel(
            severity: severity,
            aiMessage: message,
            helpOnWay: state.helpOnWay,
            etaMinutes: state.etaMinutes,
            recentUpdates: state.recentUpdates,
            hotelId: profile?.hotelId,
            roomNumber: profile?.roomNumber,
          ),
        );
      case SOSActivePanel.sos:
        return SingleChildScrollView(
          child: SOSOverviewPanel(
            liveStreamCard: _buildLiveStreamCard(severity, severityColorVal),
            aiStatusCard: _buildAIStatusCard(
              state,
              severity,
              message,
              severityColorVal,
            ),
            actionButtons: _buildActionButtons(context),
          ),
        );
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    final activePanel = widget.initialPanel;
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(
            color: _outlineVariant,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: SOSActivePanel.sos.icon,
              label: SOSActivePanel.sos.label,
              active: activePanel == SOSActivePanel.sos,
              onTap: () => _showPanel(context, SOSActivePanel.sos),
            ),
            _BottomNavItem(
              icon: SOSActivePanel.messages.icon,
              label: SOSActivePanel.messages.label,
              active: activePanel == SOSActivePanel.messages,
              onTap: () => _showPanel(context, SOSActivePanel.messages),
            ),
            _BottomNavItem(
              icon: SOSActivePanel.guide.icon,
              label: SOSActivePanel.guide.label,
              active: activePanel == SOSActivePanel.guide,
              onTap: () => _showPanel(context, SOSActivePanel.guide),
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: false,
              onTap: () => context.go('/profile'),
            ),
        ],
      ),
    );
  }

  Widget _buildQueuedOverlay() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.orange.withValues(
                      alpha: 0.42 + (_pulseController.value * 0.45),
                    ),
                    width: 2.8,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sos_rounded,
                      size: 42,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'SOS Queued',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Network unavailable. We will send your emergency request automatically when connection returns.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _onSurfaceMuted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPanel(BuildContext context, SOSActivePanel panel) {
    context.go('/sos/active/${widget.incidentId}?panel=${panel.queryValue}');
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _outlineVariant),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _onSurfaceMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _toTitle(String value) {
    final lower = value.toLowerCase();
    return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = _primary;
    const inactiveColor = _onSurfaceMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: active
            ? BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? activeColor : inactiveColor,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
