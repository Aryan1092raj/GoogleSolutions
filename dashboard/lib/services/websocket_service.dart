import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';

class MediaChunk {
  final String incidentId;
  final int chunkIndex;
  final int timestampMs;
  final String? video;
  final String? audio;

  MediaChunk({
    required this.incidentId,
    required this.chunkIndex,
    required this.timestampMs,
    this.video,
    this.audio,
  });

  factory MediaChunk.fromJson(Map<String, dynamic> json) {
    return MediaChunk(
      incidentId: json['incidentId']?.toString() ?? '',
      chunkIndex: json['chunkIndex'] ?? 0,
      timestampMs: json['timestampMs'] ?? 0,
      video: json['video']?.toString(),
      audio: json['audio']?.toString(),
    );
  }
}

class DashboardWebSocketService {
  WebSocketChannel? _channel;
  final _mediaChunkController = StreamController<MediaChunk>.broadcast();
  String? _currentIncidentId;
  Timer? _reconnectTimer;
  bool _reconnecting = false;

  Stream<MediaChunk> get mediaChunks => _mediaChunkController.stream;

  Future<void> connect(String incidentId) async {
    if (_currentIncidentId == incidentId && _channel != null) {
      return;
    }
    await disconnect();
    _currentIncidentId = incidentId;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final idToken = await user.getIdToken();
    final backendBase = DashboardConstants.backendBaseUrl;
    if (backendBase.isEmpty) {
      return;
    }
    final backendUri = Uri.parse(backendBase);
    final wsScheme = backendUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = backendUri.replace(
      scheme: wsScheme,
      path: '/ws/dashboard',
      queryParameters: {
        'token': idToken,
        'incidentId': incidentId,
      },
    );

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            if (decoded['type'] == 'MEDIA_CHUNK') {
              final chunk = MediaChunk.fromJson(decoded['payload']);
              _mediaChunkController.add(chunk);
            }
          } catch (_) {}
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnecting || _currentIncidentId == null) return;
    _reconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnecting = false;
      if (_currentIncidentId != null) {
        connect(_currentIncidentId!);
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _currentIncidentId = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _mediaChunkController.close();
  }
}
