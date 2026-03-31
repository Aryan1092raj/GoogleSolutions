import 'dart:convert'; 
import 'package:camera/camera.dart'; 
import 'package:flutter/widgets.dart'; 
 
class CameraService { 
  CameraController? _controller; 
  Future<void>? _initializeFuture;
 
  Future<void> initialize() async { 
    if (_controller != null && _controller!.value.isInitialized) {
      return;
    }
    if (_initializeFuture != null) {
      return _initializeFuture!;
    }

    _initializeFuture = _initializeInternal();
    try {
      await _initializeFuture;
    } finally {
      _initializeFuture = null;
    }
  } 

  Future<void> _initializeInternal() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('noCamera', 'No camera available on this device.');
    }

    final previous = _controller;
    final nextController = CameraController(
      cameras.first,
      ResolutionPreset.low,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await nextController.initialize();
      _controller = nextController;
      await previous?.dispose();
    } catch (_) {
      await nextController.dispose();
      rethrow;
    }
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
    _initializeFuture = null;
    _controller?.dispose();
    _controller = null;
  }
}
