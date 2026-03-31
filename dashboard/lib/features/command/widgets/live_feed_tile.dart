import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/dashboard_theme.dart';
import 'hazard_tag.dart';

class LiveFeedTile extends StatefulWidget {
  final String hazard;
  final String summary;
  final String? incidentId;
  final String? aiStatus;

  const LiveFeedTile({
    super.key,
    required this.hazard,
    required this.summary,
    this.incidentId,
    this.aiStatus,
  });

  @override
  State<LiveFeedTile> createState() => _LiveFeedTileState();
}

class _LiveFeedTileState extends State<LiveFeedTile> {
  String? _frameBase64;
  int _updatedMs = 0;
  DatabaseReference? _ref;
  StreamSubscription<DatabaseEvent>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.incidentId);
  }

  @override
  void didUpdateWidget(LiveFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _unsubscribe();
      _subscribe(widget.incidentId);
    }
  }

  void _subscribe(String? incidentId) {
    if (incidentId == null || incidentId.isEmpty || incidentId == '-') return;
    _ref = FirebaseDatabase.instanceFor(app: Firebase.app())
        .ref('live_frames/$incidentId');
    _frameSubscription = _ref!.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          _frameBase64 = data['frame']?.toString();
          _updatedMs = (data['updatedMs'] as num?)?.toInt() ?? 0;
        });
      }
    });
  }

  void _unsubscribe() {
    _frameSubscription?.cancel();
    _frameSubscription = null;
    _ref = null;
    _frameBase64 = null;
    _updatedMs = 0;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE FEED',
                    style: GoogleFonts.inter(
                      color: kDashTextMut,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Guest view relay',
                    style: GoogleFonts.fustat(
                      color: kDashText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _updatedMs > 0
                      ? kDashDanger.withValues(alpha: 0.12)
                      : const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _updatedMs > 0
                        ? kDashDanger.withValues(alpha: 0.25)
                        : kDashBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _updatedMs > 0 ? kDashDanger : kDashTextSub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _updatedMs > 0 ? _timeAgo(_updatedMs).toUpperCase() : 'AWAITING FRAME',
                      style: GoogleFonts.inter(
                        color: _updatedMs > 0 ? kDashDanger : kDashTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF07111F), Color(0xFF03060B)],
                      ),
                    ),
                    child: _frameBase64 != null
                        ? Image.memory(
                            base64Decode(_frameBase64!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            gaplessPlayback: true,
                          )
                        : _Placeholder(
                            label: widget.incidentId != null &&
                                    widget.incidentId != '-'
                                ? 'Waiting for stream...'
                                : 'No incident selected',
                          ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ROOM FEED',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              HazardTag(hazard: widget.hazard),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _summaryLabel(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    color: kDashText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(int ms) {
    final secs =
        ((DateTime.now().millisecondsSinceEpoch - ms) / 1000).round();
    if (secs < 5) return 'live';
    if (secs < 60) return '${secs}s ago';
    return '${(secs / 60).round()}m ago';
  }

  String _summaryLabel() {
    if (widget.summary.isNotEmpty) {
      return widget.summary;
    }
    switch ((widget.aiStatus ?? 'PENDING').toUpperCase()) {
      case 'UNAVAILABLE':
        return 'AI analysis is unavailable for this incident.';
      case 'DEGRADED':
        return 'AI is running in fallback mode...';
      case 'AVAILABLE':
        return 'AI summary ready.';
      case 'PENDING':
      default:
        return 'Awaiting AI summary...';
    }
  }
}

class _Placeholder extends StatelessWidget {
  final String label;

  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF04070B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
