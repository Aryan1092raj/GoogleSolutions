import 'dart:async'; 
import 'dart:convert'; 
import 'package:web_socket_channel/web_socket_channel.dart'; 
import '../core/constants.dart'; 
 
class SOSInitPayload { 
  final Map data; 
  SOSInitPayload(this.data); 
  Map toJson() { 
    return Map.from(data); 
  } 
} 
 
class WebSocketService { 
  WebSocketChannel? _channel; 
  final StreamController _messageController = StreamController.broadcast(); 
  int _chunkIndex = 0; 
  String? _wsToken; 
  String? _incidentId; 
 
  Stream get messages { 
    return _messageController.stream; 
  } 
 
  Future connect(String wsToken, String incidentId) async { 
    _wsToken = wsToken; 
    _incidentId = incidentId; 
    final uri = Uri.parse(AppConstants.wsUrl + '?token=' + wsToken + '&incidentId=' + incidentId); 
    _channel = WebSocketChannel.connect(uri); 
    _channel!.stream.listen((data) { 
      _messageController.add(jsonDecode(data)); 
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
 
  void _send(Map msg) { 
    _channel?.sink.add(jsonEncode(msg)); 
  } 
 
  void _onDisconnected() { 
    Future.delayed(const Duration(seconds: 2), () { 
      reconnect(); 
    }); 
  } 
 
  Future reconnect() async { 
    if (_wsToken == null) { 
      return; 
    } 
    if (_incidentId == null) { 
      return; 
    } 
    await connect(_wsToken as String, _incidentId as String); 
  } 
}
