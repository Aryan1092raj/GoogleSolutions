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

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.dispose);
  return service;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class SOSNotifier extends StateNotifier<SOSState> {
  final WebSocketService _ws;
  final CameraService _camera;
  final LocationService _location;
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _locationTimer;
  Timer? _pingTimer;

  SOSNotifier(this._ws, this._camera, this._location, this._ref)
      : super(const SOSState(status: SOSStatus.idle, helpOnWay: false)) {
    _sub = _ws.messages.listen(_handleWsMessage);
  }

  Future<void> triggerSOS() async {
    final profile = _ref.read(guestProfileProvider);
    if (profile == null) {
      state = state.copyWith(status: SOSStatus.error, error: 'Guest profile missing');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(status: SOSStatus.error, error: 'Guest is not authenticated');
      return;
    }

    state = state.copyWith(status: SOSStatus.initiating, error: null);

    try {
      await _camera.initialize();
    } catch (_) {}

    final incidentId = const Uuid().v4();
    final idToken = await user.getIdToken();

    double? lat;
    double? lng;
    try {
      final pos = await _location.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
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

      _startLiveMetadataUpdates(incidentId);
      state = state.copyWith(status: SOSStatus.active, incidentId: incidentId);
    } catch (error) {
      state = state.copyWith(status: SOSStatus.error, error: error.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<void> endSOS(String reason) async {
    final current = state;
    if (current.incidentId == null) {
      return;
    }
    final id = current.incidentId as String;
    _ws.sendSOSend(id, reason);
    _locationTimer?.cancel();
    _pingTimer?.cancel();
    state = current.copyWith(status: SOSStatus.resolving);
  }

  void _handleWsMessage(Map<String, dynamic> msg) {
    final current = state;
    final type = msg['type'];
    final payload = msg['payload'] is Map ? Map<String, dynamic>.from(msg['payload']) : <String, dynamic>{};

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
    _locationTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  void _startLiveMetadataUpdates(String incidentId) {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final position = await _location.getCurrentPosition();
        _ws.sendLocationUpdate(
          incidentId,
          lat: position.latitude,
          lng: position.longitude,
          accuracyMeters: position.accuracy,
          floor: 0,
        );
      } catch (_) {
        // GPS may be unavailable indoors, room-based location is still valid.
      }
    });

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _ws.sendPing();
    });
  }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final ws = ref.read(webSocketServiceProvider);
  final camera = ref.read(cameraServiceProvider);
  final location = ref.read(locationServiceProvider);
  return SOSNotifier(ws, camera, location, ref);
});
