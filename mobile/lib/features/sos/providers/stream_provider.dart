import 'dart:async'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/constants.dart'; 
import '../../../services/camera_service.dart'; 
import '../../../services/websocket_service.dart'; 
import 'sos_provider.dart';
 
class StreamState { 
  final bool streaming; 
  const StreamState({required this.streaming}); 
} 
 
class StreamNotifier extends StateNotifier<StreamState> { 
  final CameraService _camera; 
  final WebSocketService _ws; 
  Timer? _chunkTimer; 
  bool _captureInFlight = false;
  String? _activeIncidentId;
 
  StreamNotifier(this._camera, this._ws) : super(const StreamState(streaming: false)); 
 
  Future<void> startStreaming(String incidentId) async {
    if (state.streaming && _activeIncidentId == incidentId) {
      return;
    }

    await _camera.initialize();
    if (!mounted) return;
    _chunkTimer?.cancel();
    _activeIncidentId = incidentId;
    await _camera.startCapture();
    _chunkTimer = Timer.periodic(const Duration(milliseconds: AppConstants.mediaChunkIntervalMs), (_) { 
      _captureAndSend(incidentId);
    }); 
    if (!mounted) return;
    state = const StreamState(streaming: true); 
  } 
 
  Future<void> _captureAndSend(String incidentId) async { 
    if (_captureInFlight) {
      return;
    }
    _captureInFlight = true;
    try {
      final videoFrame = await _camera.captureFrame();
      final audioChunk = await _camera.captureAudio();
      if (videoFrame.isNotEmpty || audioChunk.isNotEmpty) {
        _ws.sendMediaChunk(incidentId, videoFrame, audioChunk);
      }
    } catch (_) {
      // keep streaming loop resilient; next tick retries capture
    } finally {
      _captureInFlight = false;
    }
  } 
 
  void stopStreaming() { 
    if (!mounted) return;
    _chunkTimer?.cancel(); 
    _chunkTimer = null;
    _captureInFlight = false;
    _activeIncidentId = null;
    unawaited(_camera.stopCapture());
    state = const StreamState(streaming: false); 
  } 

  @override
  void dispose() {
    stopStreaming();
    super.dispose();
  }
}
 
final streamProvider = StateNotifierProvider.autoDispose<StreamNotifier, StreamState>((ref) { 
  final camera = ref.read(cameraServiceProvider);
  final ws = ref.read(webSocketServiceProvider);
  return StreamNotifier(camera, ws); 
});
