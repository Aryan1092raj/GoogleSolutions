import 'dart:convert'; 
import 'package:camera/camera.dart'; 
import 'package:flutter/widgets.dart'; 
 
class CameraService { 
  CameraController? _controller; 
 
  Future<void> initialize() async { 
    if (_controller != null && _controller!.value.isInitialized) {
      return;
    }
    final cameras = await availableCameras(); 
    _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: true, imageFormatGroup: ImageFormatGroup.yuv420); 
    await _controller!.initialize(); 
  } 
 
  void startCapture() {} 
  void stopCapture() {} 
 
  Future<String> captureFrame() async { 
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }
    final file = await _controller!.takePicture(); 
    final bytes = await file.readAsBytes(); 
    return base64Encode(bytes); 
  } 
 
  Future<String> captureAudio() async { 
    return ''; 
  } 
 
  Widget buildPreview() { 
    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(_controller!); 
  } 

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
