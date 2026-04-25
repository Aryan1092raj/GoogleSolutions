import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/services/camera_service.dart';

void main() {
  test('captureAudio starts the source lazily and returns the next chunk', () async {
    final audioSource = _FakeAudioChunkSource(chunk: 'ZmFrZS1wY20=');
    final service = CameraService(audioSource: audioSource);

    final result = await service.captureAudio();

    expect(result, 'ZmFrZS1wY20=');
    expect(audioSource.startCalls, 1);
    expect(audioSource.pullCalls, 1);
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
