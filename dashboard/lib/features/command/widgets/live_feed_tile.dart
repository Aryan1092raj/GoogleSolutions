import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'hazard_tag.dart';

/// Displays a live video feed from [streamUrl] if provided,
/// falling back to a labelled placeholder when null or empty.
class LiveFeedTile extends StatefulWidget {
  final String hazard;
  final String summary;
  final String? streamUrl;

  const LiveFeedTile({
    super.key,
    required this.hazard,
    required this.summary,
    this.streamUrl,
  });

  @override
  State<LiveFeedTile> createState() => _LiveFeedTileState();
}

class _LiveFeedTileState extends State<LiveFeedTile> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _currentUrl;

  @override
  void didUpdateWidget(LiveFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _disposeController();
      _initController();
    }
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final url = widget.streamUrl;
    if (url == null || url.isEmpty) return;
    _currentUrl = url;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await ctrl.setLooping(true);
      await ctrl.play();
      setState(() => _isInitialized = true);
    } catch (_) {
      // Stream URL unavailable — fall back to placeholder.
      setState(() => _isInitialized = false);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _currentUrl = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('LIVE VIDEO FEED', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _isInitialized && _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : _Placeholder(hasUrl: widget.streamUrl != null && widget.streamUrl!.isNotEmpty),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            HazardTag(hazard: widget.hazard),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.summary.isEmpty ? 'Awaiting AI summary…' : widget.summary)),
          ]),
        ]),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool hasUrl;
  const _Placeholder({required this.hasUrl});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(hasUrl ? Icons.wifi_tethering : Icons.videocam_off, color: Colors.white54, size: 40),
          const SizedBox(height: 8),
          Text(
            hasUrl ? 'Connecting to stream…' : 'No stream available',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}
