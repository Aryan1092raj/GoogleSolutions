import 'dart:async'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../core/constants.dart'; 
import '../../../services/camera_service.dart'; 
import '../../../services/websocket_service.dart'; 
 
class StreamState { 
  final bool streaming; 
  const StreamState({required this.streaming}); 
} 
 
class StreamNotifier extends StateNotifier { 
  final CameraService _camera; 
  final WebSocketService _ws; 
  Timer? _chunkTimer; 
 
  StreamNotifier(this._camera, this._ws) : super(const StreamState(streaming: false)); 
 
  void startStreaming(String incidentId) { 
    _camera.startCapture(); 
    _chunkTimer = Timer.periodic(Duration(milliseconds: AppConstants.mediaChunkIntervalMs), (_) { 
      _captureAndSend(incidentId); 
    }); 
    state = const StreamState(streaming: true); 
  } 
 
  Future _captureAndSend(String incidentId) async { 
    final videoFrame = await _camera.captureFrame(); 
    final audioChunk = await _camera.captureAudio(); 
    _ws.sendMediaChunk(incidentId, videoFrame, audioChunk); 
  } 
 
  void stopStreaming() { 
    _chunkTimer?.cancel(); 
    _camera.stopCapture(); 
    state = const StreamState(streaming: false); 
  } 
} 
 
final streamProvider = StateNotifierProvider((ref) { 
  return StreamNotifier(CameraService(), WebSocketService()); 
});
