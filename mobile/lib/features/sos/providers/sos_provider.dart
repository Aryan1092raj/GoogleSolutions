import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/camera_service.dart';
import '../../../services/location_service.dart';
import '../../../services/websocket_service.dart';

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

  SOSState copyWith({
    SOSStatus? status,
    String? incidentId,
    String? aiMessage,
    String? severity,
    bool? helpOnWay,
    String? error,
  }) {
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

  Future<void> triggerSOS() async {
    final profile = _ref.read(guestProfileProvider);
    if (profile == null) {
      state = (state as SOSState).copyWith(status: SOSStatus.error, error: 'Guest profile missing');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = (state as SOSState).copyWith(status: SOSStatus.error, error: 'Guest is not authenticated');
      return;
    }

    state = (state as SOSState).copyWith(status: SOSStatus.initiating, error: null);

    try {
      await _camera.initialize();
    } catch (_) {}

    final incidentId = const Uuid().v4();
    final idToken = await user.getIdToken();

    double? lat;
    double? lng;
    try {
      final pos = await _location.getCurrentPosition();
      lat = pos.latitude as double?;
      lng = pos.longitude as double?;
    } catch (_) {}

    final createReq = {
      'incidentId': incidentId,
      'hotelId': profile.hotelId,
      'roomNumber': profile.roomNumber,
      'floor': 0,
      'wing': '',
      'guestId': profile.guestId,
      'guestName': profile.guestName,
      'guestLanguage': profile.language,
      'lat': lat,
      'lng': lng,
    };

    final client = HttpClient();
    try {
      final uri = Uri.parse(AppConstants.backendBaseUrl + '/api/incidents');
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ' + idToken);
      req.add(utf8.encode(jsonEncode(createReq)));

      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode != 201) {
        var message = 'Failed to create incident';
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          if (parsed['error'] != null) {
            message = parsed['error'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }

      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final wsToken = parsed['wsToken']?.toString() ?? '';
      if (wsToken.isEmpty) {
        throw Exception('Missing wsToken from /api/incidents response');
      }

      await _ws.connect(wsToken, incidentId);
      _ws.sendSOSInit(
        SOSInitPayload({
          'incidentId': incidentId,
          'guestId': profile.guestId,
          'guestName': profile.guestName,
          'guestLanguage': profile.language,
          'hotelId': profile.hotelId,
          'roomNumber': profile.roomNumber,
          'floor': 0,
          'wing': '',
          'lat': lat,
          'lng': lng,
          'deviceInfo': {
            'platform': Platform.isIOS ? 'ios' : 'android',
            'osVersion': Platform.operatingSystemVersion,
          }
        }),
      );

      state = (state as SOSState).copyWith(status: SOSStatus.active, incidentId: incidentId);
    } catch (error) {
      state = (state as SOSState).copyWith(status: SOSStatus.error, error: error.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<void> endSOS(String reason) async {
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
      state = current.copyWith(
        status: SOSStatus.active,
        aiMessage: payload['message']?.toString(),
        severity: payload['severity']?.toString(),
        helpOnWay: payload['helpOnWay'] == true,
      );
      return;
    }

    if (type == 'SOS_ACCEPTED') {
      state = current.copyWith(status: SOSStatus.active, helpOnWay: true);
      return;
    }

    if (type == 'INCIDENT_RESOLVED') {
      state = current.copyWith(status: SOSStatus.resolved);
      return;
    }

    if (type == 'WS_ERROR') {
      state = current.copyWith(status: SOSStatus.error, error: payload['message']?.toString());
      return;
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
