import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import '../../../core/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/camera_service.dart';
import '../../../services/location_service.dart';
import '../../../services/websocket_service.dart';
import '../../../services/sos_queue_service.dart';

enum SOSStatus { idle, initiating, active, resolving, resolved, error, queued }

class SOSState {
  final SOSStatus status;
  final String? incidentId;
  final String? aiMessage;
  final String? severity;
  final bool helpOnWay;
  final int? etaMinutes;
  final String? error;

  const SOSState({
    required this.status,
    this.incidentId,
    this.aiMessage,
    this.severity,
    required this.helpOnWay,
    this.etaMinutes,
    this.error,
  });

  SOSState copyWith({
    SOSStatus? status,
    String? incidentId,
    String? aiMessage,
    String? severity,
    bool? helpOnWay,
    int? etaMinutes,
    String? error,
  }) {
    return SOSState(
      status: status ?? this.status,
      incidentId: incidentId ?? this.incidentId,
      aiMessage: aiMessage ?? this.aiMessage,
      severity: severity ?? this.severity,
      helpOnWay: helpOnWay ?? this.helpOnWay,
      etaMinutes: etaMinutes ?? this.etaMinutes,
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _locationTimer;
  Timer? _pingTimer;
  bool _ignoringIncomingMessages = false;

  SOSNotifier(this._ws, this._camera, this._location, this._ref)
      : super(const SOSState(status: SOSStatus.idle, helpOnWay: false)) {
    _sub = _ws.messages.listen(_handleWsMessage);
  }

  Future<void> triggerSOS() async {
    if (!mounted) return;
    final profile = _ref.read(guestProfileProvider);
    if (profile == null) {
      if (!mounted) return;
      state = state.copyWith(
          status: SOSStatus.error, error: 'Guest profile missing');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      state = state.copyWith(
          status: SOSStatus.error, error: 'Guest is not authenticated');
      return;
    }

    if (!mounted) return;
    state = state.copyWith(status: SOSStatus.initiating, error: null);

    try {
      await _camera.initialize();
    } catch (_) {}
    if (!mounted) return;

    final incidentId = const Uuid().v4();
    // Force refresh to get a fresh token after signInWithCustomToken
    final idToken = await user.getIdToken(true);
    if (!mounted) return;

    double? lat;
    double? lng;
    try {
      final pos = await _location.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}
    if (!mounted) return;

    final createReq = <String, dynamic>{
      'incidentId': incidentId,
      'hotelId': profile.hotelId,
      'roomNumber': profile.roomNumber,
      'floor': 0,
      'wing': '',
      'guestId': profile.guestId,
      'guestName': profile.guestName,
      'guestLanguage': profile.language,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    try {
      await _submitIncident(createReq, idToken, incidentId, lat, lng, profile);
    } on SocketException catch (_) {
      // Network unavailable - queue for retry
      await _handleNetworkFailure(createReq);
    } catch (error) {
      // Check if it's a connectivity issue
      final connectivity = await Connectivity().checkConnectivity();
      final isNone = connectivity.any((c) => c == ConnectivityResult.none);
      if (isNone ||
          error.toString().contains('Socket') ||
          error.toString().contains('connection') ||
          error.toString().contains('network')) {
        await _handleNetworkFailure(createReq);
      } else {
        if (!mounted) return;
        state =
            state.copyWith(status: SOSStatus.error, error: error.toString());
      }
    }
  }

  /// Submit incident to backend API.
  /// Throws exception on failure.
  Future<void> _submitIncident(
    Map<String, dynamic> createReq,
    String? idToken,
    String incidentId,
    double? lat,
    double? lng,
    GuestProfile profile,
  ) async {
    String appCheckToken = '';
    try {
      appCheckToken = await FirebaseAppCheck.instance.getToken() ?? '';
    } catch (_) {}

    final uri = Uri.parse('${AppConstants.backendBaseUrl}/api/incidents');
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${idToken ?? ""}',
        'X-Firebase-AppCheck': appCheckToken,
      },
      body: jsonEncode(createReq),
    );

    if (resp.statusCode != 201) {
      var message = 'Failed to create incident';
      try {
        final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
        if (parsed['error'] != null) {
          message = parsed['error'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }

    final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
    final wsToken = parsed['wsToken']?.toString() ?? '';
    if (wsToken.isEmpty) {
      throw Exception('Missing wsToken from /api/incidents response');
    }

    await _ws.connect(wsToken, incidentId);
    if (!mounted) return;
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
          'platform': kIsWeb
              ? 'android'
              : (defaultTargetPlatform == TargetPlatform.iOS
                  ? 'ios'
                  : 'android'),
          'osVersion': kIsWeb ? 'web' : '',
        }
      }),
    );

    _startLiveMetadataUpdates(incidentId);
    if (!mounted) return;
    state = state.copyWith(status: SOSStatus.active, incidentId: incidentId);
  }

  /// Handle network failure by queuing the SOS payload and starting retry listener.
  Future<void> _handleNetworkFailure(Map<String, dynamic> payload) async {
    if (!mounted) return;

    // Enqueue the payload for later retry
    await SOSQueueService.enqueue(payload);

    // Update state to queued
    state = state.copyWith(
      status: SOSStatus.queued,
      error: null,
    );

    // Start listening for connectivity changes
    _startConnectivityRetry();
  }

  /// Listen for connectivity changes and retry pending SOS when network returns.
  void _startConnectivityRetry() {
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        // Network is back - try to submit pending SOS
        final pending = await SOSQueueService.peek();
        if (pending != null && mounted) {
          // Reset to initiating state for retry
          state = state.copyWith(status: SOSStatus.initiating, error: null);

          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final idToken = await user.getIdToken(true);
              await _submitIncident(
                pending,
                idToken,
                pending['incidentId'] as String,
                pending['lat'] as double?,
                pending['lng'] as double?,
                _ref.read(guestProfileProvider)!,
              );
              // Success - dequeue and stop listening
              await SOSQueueService.dequeue();
              _connectivitySub?.cancel();
            }
          } catch (error) {
            // Still failing - stay in queued state
            state = state.copyWith(
                status: SOSStatus.queued, error: error.toString());
          }
        }
      }
    });
  }

  Future<void> endSOS(String reason) async {
    if (!mounted) return;
    final current = state;
    if (current.incidentId == null) {
      return;
    }
    _ignoringIncomingMessages = true;
    final id = current.incidentId as String;
    _ws.sendSOSend(id, reason);
    _locationTimer?.cancel();
    _pingTimer?.cancel();
    state = current.copyWith(status: SOSStatus.resolving);
  }

  void _handleWsMessage(Map<String, dynamic> msg) {
    // Guard: do not update state if the notifier has been disposed
    if (!mounted || _ignoringIncomingMessages) return;

    final current = state;
    final type = msg['type'];
    final payload = msg['payload'] is Map
        ? Map<String, dynamic>.from(msg['payload'] as Map)
        : <String, dynamic>{};

    if (type == 'AI_STATUS') {
      if (!mounted) return;
      final etaMin = payload['estimatedArrivalMin'];
      state = current.copyWith(
        status: SOSStatus.active,
        aiMessage: payload['message']?.toString(),
        severity: payload['severity']?.toString(),
        helpOnWay: payload['helpOnWay'] == true,
        etaMinutes:
            etaMin is int ? etaMin : (etaMin is num ? etaMin.toInt() : null),
      );
      return;
    }

    if (type == 'SOS_ACCEPTED') {
      if (!mounted) return;
      state = current.copyWith(status: SOSStatus.active, helpOnWay: true);
      return;
    }

    if (type == 'INCIDENT_RESOLVED') {
      if (!mounted) return;
      state = current.copyWith(status: SOSStatus.resolved);
      return;
    }

    if (type == 'WS_ERROR') {
      if (!mounted) return;
      state = current.copyWith(
          status: SOSStatus.error, error: payload['message']?.toString());
      return;
    }
  }

  @override
  void dispose() {
    _ignoringIncomingMessages = true;
    _sub?.cancel();
    _connectivitySub?.cancel();
    _locationTimer?.cancel();
    _pingTimer?.cancel();
    unawaited(_ws.disconnect());
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
