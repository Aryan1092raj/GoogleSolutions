import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/services/camera_service.dart';

void main() {
  test('captureAudio wraps raw pcm bytes as wav before returning', () async {
    final audioSource = _FakeAudioChunkSource(
      chunk: base64Encode(const [1, 2, 3, 4]),
    );
    final service = CameraService(audioSource: audioSource);

    final result = await service.captureAudio();
    final bytes = base64Decode(result);

    expect(result, isNotEmpty);
    expect(bytes.sublist(0, 4), ascii.encode('RIFF'));
    expect(bytes.sublist(8, 12), ascii.encode('WAVE'));
    expect(bytes.sublist(bytes.length - 4), const [1, 2, 3, 4]);
    expect(audioSource.startCalls, 1);
    expect(audioSource.pullCalls, 1);
  });

  test('captureAudio returns empty chunk when audio source fails to start', () async {
    final audioSource = _ThrowingAudioChunkSource();
    final service = CameraService(audioSource: audioSource);

    final result = await service.captureAudio();

    expect(result, isEmpty);
  });
}

class _FakeAudioChunkSource implements AudioChunkSource {
  _FakeAudioChunkSource({required this.chunk});

  final String chunk;
  int startCalls = 0;
  int pullCalls = 0;

  @override
  Future<String> pullChunk() async {
    pullCalls++;
    return chunk;
  }

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<void> stop() async {}
}

class _ThrowingAudioChunkSource implements AudioChunkSource {
  @override
  Future<String> pullChunk() async => 'should-not-be-read';

  @override
  Future<void> start() async {
    throw Exception('mic denied');
  }

  @override
  Future<void> stop() async {}
}
