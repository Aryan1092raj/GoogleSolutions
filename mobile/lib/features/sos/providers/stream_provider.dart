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
 
  StreamNotifier(this._camera, this._ws) : super(const StreamState(streaming: false)); 
 
  Future<void> startStreaming(String incidentId) async {
    await _camera.initialize();
    _chunkTimer?.cancel();
    _camera.startCapture(); 
    _chunkTimer = Timer.periodic(Duration(milliseconds: AppConstants.mediaChunkIntervalMs), (_) { 
      _captureAndSend(incidentId);
    }); 
    state = const StreamState(streaming: true); 
  } 
 
  Future<void> _captureAndSend(String incidentId) async { 
    try {
      final videoFrame = await _camera.captureFrame();
      final audioChunk = await _camera.captureAudio();
      _ws.sendMediaChunk(incidentId, videoFrame, audioChunk);
    } catch (_) {
      // keep streaming loop resilient; next tick retries capture
    }
  } 
 
  void stopStreaming() { 
    _chunkTimer?.cancel(); 
    _chunkTimer = null;
    _camera.stopCapture(); 
    state = const StreamState(streaming: false); 
  } 

  @override
  void dispose() {
    _chunkTimer?.cancel();
    super.dispose();
  }
}
 
final streamProvider = StateNotifierProvider<StreamNotifier, StreamState>((ref) { 
  final camera = ref.read(cameraServiceProvider);
  final ws = ref.read(webSocketServiceProvider);
  return StreamNotifier(camera, ws); 
});
