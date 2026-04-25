import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants.dart';

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

abstract class CapturePermissionGate {
  Future<void> ensureCapturePermissions();
}

class PermissionHandlerCapturePermissionGate implements CapturePermissionGate {
  @override
  Future<void> ensureCapturePermissions() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    final statuses = await <Permission>[
      Permission.camera,
      Permission.microphone,
    ].request();

    final denied = <String>[];
    if (!(statuses[Permission.camera]?.isGranted ?? false)) {
      denied.add('camera');
    }
    if (!(statuses[Permission.microphone]?.isGranted ?? false)) {
      denied.add('microphone');
    }

    if (denied.isEmpty) {
      return;
    }

    throw CameraException(
      'permissionDenied',
      'Required capture permissions denied: ${denied.join(', ')}.',
    );
  }
}

class CameraService {
  CameraService({
    AudioChunkSource? audioSource,
    CapturePermissionGate? permissionGate,
  })  : _audioSource = audioSource ?? MethodChannelAudioChunkSource(),
        _permissionGate =
            permissionGate ?? PermissionHandlerCapturePermissionGate();

  CameraController? _controller;
  Future<void>? _initializeFuture;
  final AudioChunkSource _audioSource;
  final CapturePermissionGate _permissionGate;

  bool _streaming = false;
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
    await _permissionGate.ensureCapturePermissions();
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

    // Use still JPEG capture in the periodic loop for consistent payload format.
    _imageStreamStarted = false;
    if (kIsWeb) {
      return;
    }
  }

  Future<void> stopCapture() async {
    if (!_streaming || _controller == null) {
      unawaited(_stopAudio());
      return;
    }
    _streaming = false;

    if (_imageStreamStarted) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
    _imageStreamStarted = false;
    await _stopAudio();
  }

  Future<String> captureFrame() async {
    // Fallback to single capture
    if (_controller == null || !_controller!.value.isInitialized) {
      await initialize();
    }
    final file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> captureAudio() async {
    try {
      await _ensureAudioStarted();
      if (!_audioStreaming) {
        return '';
      }

      final chunk = await _audioSource.pullChunk();
      if (chunk.isEmpty) {
        return '';
      }

      return _encodePcm16ChunkAsWavBase64(chunk);
    } catch (_) {
      return '';
    }
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

    try {
      await _audioSource.start();
      _audioStreaming = true;
    } catch (_) {
      _audioStreaming = false;
    }
  }

  Future<void> _stopAudio() async {
    if (!_audioStreaming) {
      return;
    }

    _audioStreaming = false;
    await _audioSource.stop();
  }

  String _encodePcm16ChunkAsWavBase64(String pcmBase64) {
    final pcmBytes = base64Decode(pcmBase64);
    if (pcmBytes.isEmpty) {
      return '';
    }

    final wavBytes = Uint8List(44 + pcmBytes.length);
    final header = ByteData.sublistView(wavBytes, 0, 44);
    const byteRate = AppConstants.audioSampleRate * 2;

    wavBytes.setRange(44, wavBytes.length, pcmBytes);
    header.setUint32(0, 0x52494646, Endian.big); // RIFF
    header.setUint32(4, pcmBytes.length + 36, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // WAVE
    header.setUint32(12, 0x666d7420, Endian.big); // fmt
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, AppConstants.audioSampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits per sample
    header.setUint32(36, 0x64617461, Endian.big); // data
    header.setUint32(40, pcmBytes.length, Endian.little);

    return base64Encode(wavBytes);
  }
}
