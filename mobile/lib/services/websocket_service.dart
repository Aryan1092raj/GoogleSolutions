import 'dart:async'; 
import 'dart:convert'; 
import 'package:web_socket_channel/web_socket_channel.dart'; 
import '../core/constants.dart'; 
 
class SOSInitPayload { 
  final Map<String, dynamic> data; 
  SOSInitPayload(this.data); 
  Map<String, dynamic> toJson() { 
    return Map.from(data); 
  } 
} 
 
class WebSocketService { 
  WebSocketChannel? _channel; 
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast(); 
  int _chunkIndex = 0; 
  String? _wsToken; 
  String? _incidentId; 
  int _reconnectDelaySec = 2;
  Timer? _reconnectTimer;
  bool _reconnecting = false;
 
  Stream<Map<String, dynamic>> get messages { 
    return _messageController.stream; 
  } 
 
  Future<void> connect(String wsToken, String incidentId) async { 
    _wsToken = wsToken; 
    _incidentId = incidentId; 
    _reconnectTimer?.cancel();
    _reconnecting = false;
    final uri = Uri.parse(AppConstants.wsUrl + '?token=' + wsToken + '&incidentId=' + incidentId); 
    _channel = WebSocketChannel.connect(uri); 
    _channel!.stream.listen((data) { 
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        _messageController.add(decoded);
      } else if (decoded is Map) {
        _messageController.add(Map<String, dynamic>.from(decoded));
      }
      _reconnectDelaySec = 2;
    }, onError: (e) { 
      _messageController.addError(e); 
    }, onDone: () { 
      _onDisconnected(); 
    }); 
  }
 
  void sendSOSInit(SOSInitPayload payload) { 
    _send({'type': 'SOS_INIT', 'payload': payload.toJson()}); 
  } 
 
  void sendMediaChunk(String incidentId, String? videoB64, String? audioB64) { 
    _send({ 
      'type': 'MEDIA_CHUNK', 
      'payload': { 
        'incidentId': incidentId, 
        'chunkIndex': _chunkIndex++, 
        'timestampMs': DateTime.now().millisecondsSinceEpoch, 
        'video': videoB64, 
        'audio': audioB64, 
        'mimeTypeVideo': 'video/webm', 
        'mimeTypeAudio': 'audio/pcm', 
      } 
    }); 
  } 
 
  void sendSOSend(String incidentId, String reason) { 
    _send({ 
      'type': 'SOS_END', 
      'payload': {'incidentId': incidentId, 'reason': reason}, 
    }); 
  } 
 
  void sendLocationUpdate(
    String incidentId, {
    required double lat,
    required double lng,
    required double accuracyMeters,
    int? floor,
  }) {
    _send({
      'type': 'LOCATION_UPDATE',
      'payload': {
        'incidentId': incidentId,
        'lat': lat,
        'lng': lng,
        'accuracyMeters': accuracyMeters,
        'floor': floor,
      },
    });
  }

  void sendPing() {
    _send({
      'type': 'WS_PING',
      'payload': {'ts': DateTime.now().millisecondsSinceEpoch},
    });
  }

  void _send(Map<String, dynamic> msg) { 
    _channel?.sink.add(jsonEncode(msg)); 
  } 
 
  void _onDisconnected() { 
    if (_reconnecting) {
      return;
    }
    _reconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySec), () async {
      await reconnect();
      _reconnectDelaySec = (_reconnectDelaySec * 2).clamp(2, 30);
      _reconnecting = false;
    });
  } 
 
  Future<void> reconnect() async { 
    if (_wsToken == null) { 
      return; 
    } 
    if (_incidentId == null) { 
      return; 
    } 
    await connect(_wsToken as String, _incidentId as String); 
  } 

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
