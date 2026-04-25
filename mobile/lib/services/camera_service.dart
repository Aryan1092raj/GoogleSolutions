import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract class AudioChunkSource {
  Future<void> start();
  Future<String> pullChunk();
  Future<void> stop();
}

class MethodChannelAudioChunkSource implements AudioChunkSource {
  static const MethodChannel _channel = MethodChannel('resqlink/audio_capture');
  bool _started = false;
  bool _available = true;

  @override
  Future<String> pullChunk() async {
    if (!_available || !_started) {
      return '';
    }

    try {
      return await _channel.invokeMethod<String>('pullChunk') ?? '';
    } on MissingPluginException {
      _available = false;
      _started = false;
      return '';
    } on PlatformException {
      return '';
    }
  }

  @override
  Future<void> start() async {
    if (!_available || _started) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('start');
      _started = true;
    } on MissingPluginException {
      _available = false;
      _started = false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_available || !_started) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      _available = false;
    } on PlatformException {
      // Ignore stop failures; the next start will re-establish state.
    } finally {
      _started = false;
    }
  }
}

class CameraService {
  CameraService({AudioChunkSource? audioSource})
      : _audioSource = audioSource ?? MethodChannelAudioChunkSource();

  CameraController? _controller;
  Future<void>? _initializeFuture;
  final AudioChunkSource _audioSource;

  // Frame streaming fields for continuous capture
  String? _latestFrameBase64;
  bool _streaming = false;
  bool _processingFrame = false;
  bool _audioStreaming = false;
  bool _imageStreamStarted = false;

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

  Future<void> startCapture() async {
    if (_streaming ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }
    _streaming = true;
    unawaited(_ensureAudioStarted());

    // `camera` does not support image streaming on web. Fall back to
    // `takePicture()` in captureFrame() for the periodic stream loop.
    if (kIsWeb) {
      _imageStreamStarted = false;
      return;
    }

    try {
      await _controller!.startImageStream((CameraImage image) async {
        if (_processingFrame) return;
        _processingFrame = true;

        try {
          // Convert YUV420 image to JPEG bytes
          final bytes = await _convertYuv420ToJpeg(image);
          _latestFrameBase64 = base64Encode(bytes);
        } finally {
          _processingFrame = false;
        }
      });
      _imageStreamStarted = true;
    } catch (_) {
      // Web and some platforms/drivers do not support image streaming.
      // Keep streaming enabled but rely on `takePicture()` in captureFrame().
      _imageStreamStarted = false;
    }
  }

  Future<void> stopCapture() async {
    if (!_streaming || _controller == null) {
      unawaited(_stopAudio());
      return;
    }
    _streaming = false;
    _latestFrameBase64 = null;

    if (_imageStreamStarted) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
    _imageStreamStarted = false;
    await _stopAudio();
  }

  Future<String> captureFrame() async {
    // Return latest frame if streaming (much faster)
    if (_latestFrameBase64 != null) {
      return _latestFrameBase64!;
    }

    // Fallback to single capture
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }
    final file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Convert YUV420 CameraImage to JPEG bytes
  Future<Uint8List> _convertYuv420ToJpeg(CameraImage image) async {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final rowStrideY = yPlane.bytesPerRow;
    final rowStrideUV = uPlane.bytesPerRow;
    final pixelStrideY = yPlane.bytesPerPixel ?? 1;
    final pixelStrideUV = uPlane.bytesPerPixel ?? 2;

    final jpegBytes = Uint8List(width * height * 3);
    var jpegIndex = 0;

    for (var y = 0; y < height; y++) {
      final uvRow = (y ~/ 2);
      for (var x = 0; x < width; x++) {
        final yIndex = y * rowStrideY + x * pixelStrideY;
        final uvIndex = uvRow * rowStrideUV + (x ~/ 2) * pixelStrideUV;

        final yValue = yBuffer[yIndex];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];

        // YUV to RGB conversion
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        jpegBytes[jpegIndex++] = r;
        jpegBytes[jpegIndex++] = g;
        jpegBytes[jpegIndex++] = b;
      }
    }

    return jpegBytes;
  }

  Future<String> captureAudio() async {
    await _ensureAudioStarted();
    return _audioSource.pullChunk();
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
    unawaited(_stopAudio());
  }

  Future<void> _ensureAudioStarted() async {
    if (_audioStreaming) {
      return;
    }

    await _audioSource.start();
    _audioStreaming = true;
  }

  Future<void> _stopAudio() async {
    if (!_audioStreaming) {
      return;
    }

    _audioStreaming = false;
    await _audioSource.stop();
  }
}
