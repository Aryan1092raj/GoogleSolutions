import 'dart:async'; 
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../../../services/websocket_service.dart'; 
import '../../../services/camera_service.dart'; 
import '../../../services/location_service.dart'; 
 
enum SOSStatus { idle, initiating, active, resolving, resolved, error } 
 
class SOSState { 
  final SOSStatus status; 
  final String? incidentId; 
  final String? aiMessage; 
  final String? severity; 
  final bool helpOnWay; 
  final String? error; 
 
  const SOSState({ 
    required this.status, 
    this.incidentId, 
    this.aiMessage, 
    this.severity, 
    required this.helpOnWay, 
    this.error, 
  }); 
 
  SOSState copyWith({SOSStatus? status, String? incidentId, String? aiMessage, String? severity, bool? helpOnWay, String? error}) { 
    return SOSState( 
      status: status ?? this.status, 
      incidentId: incidentId ?? this.incidentId, 
      aiMessage: aiMessage ?? this.aiMessage, 
      severity: severity ?? this.severity, 
      helpOnWay: helpOnWay ?? this.helpOnWay, 
      error: error ?? this.error, 
    ); 
  } 
}
 
class SOSNotifier extends StateNotifier { 
  final WebSocketService _ws; 
  final CameraService _camera; 
  final LocationService _location; 
  final Ref _ref; 
  StreamSubscription? _sub; 
 
  SOSNotifier(this._ws, this._camera, this._location, this._ref) 
      : super(const SOSState(status: SOSStatus.idle, helpOnWay: false)) { 
    _sub = _ws.messages.listen(_handleWsMessage); 
  } 
 
 
  Future triggerSOS() async { 
    state = (state as SOSState).copyWith(status: SOSStatus.initiating); 
  }
 
  Future endSOS(String reason) async { 
    final current = state as SOSState; 
    if (current.incidentId == null) { 
      return; 
    } 
    final id = current.incidentId as String; 
    _ws.sendSOSend(id, reason); 
    state = current.copyWith(status: SOSStatus.resolving); 
  } 
 
  void _handleWsMessage(dynamic msg) { 
    final current = state as SOSState; 
    if (msg is! Map) { 
      return; 
    } 
    final type = msg['type']; 
    final payload = msg['payload']; 
    if (type == 'AI_STATUS') { 
      state = current.copyWith(status: SOSStatus.active, aiMessage: payload['message'], severity: payload['severity'], helpOnWay: payload['helpOnWay'] == true); 
    } 
    if (type == 'INCIDENT_RESOLVED') { 
      state = current.copyWith(status: SOSStatus.resolved); 
    } 
  } 
 
  @override 
  void dispose() { 
    _sub?.cancel(); 
    super.dispose(); 
  } 
} 
 
final sosProvider = StateNotifierProvider((ref) { 
  return SOSNotifier(WebSocketService(), CameraService(), LocationService(), ref); 
});
