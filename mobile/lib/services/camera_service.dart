import 'dart:convert'; 
import 'package:camera/camera.dart'; 
import 'package:flutter/widgets.dart'; 
 
class CameraService { 
  CameraController? _controller; 
 
  Future initialize() async { 
    final cameras = await availableCameras(); 
    _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: true, imageFormatGroup: ImageFormatGroup.yuv420); 
    await _controller!.initialize(); 
  } 
 
  void startCapture() {} 
  void stopCapture() {} 
 
  Future captureFrame() async { 
    final file = await _controller!.takePicture(); 
    final bytes = await file.readAsBytes(); 
    return base64Encode(bytes); 
  } 
 
  Future captureAudio() async { 
    return ''; 
  } 
 
  Widget buildPreview() { 
    return CameraPreview(_controller!); 
  } 
}
