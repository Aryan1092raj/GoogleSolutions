import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveIncidentCard {
  final String incidentId;
  final String status;
  final String severity;
  final String roomNumber;
  final int floor;
  final String wing;
  final String guestName;
  final String primaryHazard;
  final String aiStatus;
  final String aiSummary;
  final int lastUpdatedMs;
  final bool isStreamLive;
  final String? acknowledgedBy;

  LiveIncidentCard({
    required this.incidentId,
    required this.status,
    required this.severity,
    required this.roomNumber,
    required this.floor,
    required this.wing,
    required this.guestName,
    required this.primaryHazard,
    required this.aiStatus,
    required this.aiSummary,
    required this.lastUpdatedMs,
    required this.isStreamLive,
    this.acknowledgedBy,
  });

  factory LiveIncidentCard.fromJson(Map<String, dynamic> json) {
    return LiveIncidentCard(
      incidentId:
          json['incidentId'] == null ? '' : json['incidentId'].toString(),
      status: json['status'] == null ? '' : json['status'].toString(),
      severity: json['severity'] == null ? 'LOW' : json['severity'].toString(),
      roomNumber:
          json['roomNumber'] == null ? '' : json['roomNumber'].toString(),
      floor: json['floor'] == null
          ? 0
          : int.tryParse(json['floor'].toString()) ?? 0,
      wing: json['wing'] == null ? '' : json['wing'].toString(),
      guestName: json['guestName'] == null ? '' : json['guestName'].toString(),
      primaryHazard: json['primaryHazard'] == null
          ? 'UNKNOWN'
          : json['primaryHazard'].toString(),
      aiStatus: json['aiStatus'] == null
          ? ((json['aiSummary']?.toString().isNotEmpty ?? false)
              ? 'AVAILABLE'
              : 'PENDING')
          : json['aiStatus'].toString(),
      aiSummary: json['aiSummary'] == null ? '' : json['aiSummary'].toString(),
      lastUpdatedMs: json['lastUpdatedMs'] == null
          ? 0
          : int.tryParse(json['lastUpdatedMs'].toString()) ?? 0,
      isStreamLive: json['isStreamLive'] == true,
      acknowledgedBy: json['acknowledgedBy']?.toString(),
    );
  }
}

class IncidentHistoryRecord {
  final String incidentId;
  final String hotelId;
  final String status;
  final String severity;
  final String guestName;
  final String roomNumber;
  final int floor;
  final String wing;
  final String aiSummary;
  final String primaryHazard;
  final int createdAtMs;
  final int updatedAtMs;
  final int? resolvedAtMs;

  IncidentHistoryRecord({
    required this.incidentId,
    required this.hotelId,
    required this.status,
    required this.severity,
    required this.guestName,
    required this.roomNumber,
    required this.floor,
    required this.wing,
    required this.aiSummary,
    required this.primaryHazard,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.resolvedAtMs,
  });

  factory IncidentHistoryRecord.fromFirestore(
    String incidentId,
    Map<String, dynamic> json,
  ) {
    final location = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final hazards = _extractHazards(json['hazards']);
    final resolvedAtMs = _asTimestampMs(json['resolvedAt']);

    return IncidentHistoryRecord(
      incidentId: incidentId,
      hotelId: _asString(json['hotelId']),
      status: _asString(json['status'], 'ACTIVE'),
      severity: _asString(json['severity'], 'LOW'),
      guestName: _asString(json['guestName'], 'Unknown Guest'),
      roomNumber: _asString(
        json['roomNumber'],
        _asString(location['roomNumber'], '-'),
      ),
      floor: _asInt(json['floor'], _asInt(location['floor'])),
      wing:
          _asString(json['wing'], _asString(location['wing'], 'Unknown Wing')),
      aiSummary: _asString(json['aiSummary']),
      primaryHazard: _asString(
        json['primaryHazard'],
        hazards.isNotEmpty ? hazards.first : 'UNKNOWN',
      ),
      createdAtMs: _asTimestampMs(json['createdAt']),
      updatedAtMs: _asTimestampMs(json['updatedAt']),
      resolvedAtMs: resolvedAtMs > 0 ? resolvedAtMs : null,
    );
  }
}

class IncidentDetailRecord {
  final String incidentId;
  final String hotelId;
  final String status;
  final String severity;
  final String guestName;
  final String guestLanguage;
  final String guestPhone;
  final String roomNumber;
  final int floor;
  final String wing;
  final double? lat;
  final double? lng;
  final String aiStatus;
  final String aiSummary;
  final String primaryHazard;
  final List<String> hazards;
  final String originalTranscript;
  final String translatedTranscript;
  final String detectedLanguage;
  final bool isStreamLive;
  final String? acknowledgedBy;
  final int? etaMinutes;
  final int createdAtMs;
  final int updatedAtMs;
  final int? resolvedAtMs;
  final List<Map<String, dynamic>> actionHistory;
  final List<Map<String, dynamic>> responderLog;

  IncidentDetailRecord({
    required this.incidentId,
    required this.hotelId,
    required this.status,
    required this.severity,
    required this.guestName,
    required this.guestLanguage,
    required this.guestPhone,
    required this.roomNumber,
    required this.floor,
    required this.wing,
    required this.lat,
    required this.lng,
    required this.aiStatus,
    required this.aiSummary,
    required this.primaryHazard,
    required this.hazards,
    required this.originalTranscript,
    required this.translatedTranscript,
    required this.detectedLanguage,
    required this.isStreamLive,
    required this.acknowledgedBy,
    required this.etaMinutes,
    required this.createdAtMs,
    required this.updatedAtMs,
    required this.resolvedAtMs,
    required this.actionHistory,
    required this.responderLog,
  });

  factory IncidentDetailRecord.fromFirestore(
    String incidentId,
    Map<String, dynamic> json,
  ) {
    final location = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final hazards = _extractHazards(json['hazards']);
    final acknowledgedBy = _asString(json['acknowledgedBy']);
    final eta = json['etaMinutes'] == null ? null : _asInt(json['etaMinutes']);
    final resolvedAtMs = _asTimestampMs(json['resolvedAt']);

    return IncidentDetailRecord(
      incidentId: incidentId,
      hotelId: _asString(json['hotelId']),
      status: _asString(json['status'], 'ACTIVE'),
      severity: _asString(json['severity'], 'LOW'),
      guestName: _asString(json['guestName'], 'Unknown Guest'),
      guestLanguage: _asString(json['guestLanguage']),
      guestPhone: _asString(json['guestPhone']),
      roomNumber: _asString(
        json['roomNumber'],
        _asString(location['roomNumber'], '-'),
      ),
      floor: _asInt(json['floor'], _asInt(location['floor'])),
      wing:
          _asString(json['wing'], _asString(location['wing'], 'Unknown Wing')),
      lat: _asDouble(location['lat']),
      lng: _asDouble(location['lng']),
      aiStatus: _asString(json['aiStatus'], 'PENDING'),
      aiSummary: _asString(json['aiSummary']),
      primaryHazard: _asString(
        json['primaryHazard'],
        hazards.isNotEmpty ? hazards.first : 'UNKNOWN',
      ),
      hazards: hazards,
      originalTranscript: _asString(json['originalTranscript']),
      translatedTranscript: _asString(json['translatedTranscript']),
      detectedLanguage: _asString(json['detectedLanguage'], 'en'),
      isStreamLive: json['isStreamLive'] == true,
      acknowledgedBy: acknowledgedBy.isEmpty ? null : acknowledgedBy,
      etaMinutes: (eta == null || eta <= 0) ? null : eta,
      createdAtMs: _asTimestampMs(json['createdAt']),
      updatedAtMs: _asTimestampMs(json['updatedAt']),
      resolvedAtMs: resolvedAtMs > 0 ? resolvedAtMs : null,
      actionHistory: _asMapList(json['actionHistory']),
      responderLog: _asMapList(json['responderLog']),
    );
  }
}

class StaffProfile {
  final String uid;
  final String hotelId;
  final String role;
  const StaffProfile({
    required this.uid,
    required this.hotelId,
    required this.role,
  });

  static const empty = StaffProfile(uid: '', hotelId: '', role: '');
}

final staffProfileProvider = StateProvider<StaffProfile>((ref) {
  return StaffProfile.empty;
});

const _allowedStaffRoles = <String>{
  'SECURITY',
  'MANAGER',
  'FIRST_RESPONDER',
};

Future<StaffProfile> resolveStaffProfile(
  User user, {
  StaffProfile? fallbackProfile,
}) async {
  final token = await user.getIdTokenResult();
  final claims = token.claims ?? const <String, dynamic>{};

  var hotelId = _asString(claims['hotelId'], fallbackProfile?.hotelId ?? '');
  var role = _normalizeStaffRole(
    _asString(claims['role'], fallbackProfile?.role ?? ''),
  );

  if (hotelId.isEmpty || role.isEmpty) {
    final profileDoc = await FirebaseFirestore.instance
        .collection('staff_profiles')
        .doc(user.uid)
        .get();
    final profileData = profileDoc.data() ?? const <String, dynamic>{};

    if (hotelId.isEmpty) {
      hotelId = _asString(profileData['hotelId']);
    }
    if (role.isEmpty) {
      role = _normalizeStaffRole(_asString(profileData['role']));
    }
  }

  return StaffProfile(
    uid: user.uid,
    hotelId: hotelId,
    role: role,
  );
}

final incidentListProvider = StreamProvider<List<LiveIncidentCard>>((ref) {
  final profile = ref.watch(staffProfileProvider);
  final hotelId = profile.hotelId;
  if (hotelId.isEmpty) {
    return const Stream<List<LiveIncidentCard>>.empty();
  }
  final db = FirebaseDatabase.instanceFor(app: Firebase.app());
  return db.ref('live_incidents/$hotelId').onValue.map((event) {
    final raw = event.snapshot.value;
    final data =
        raw is Map ? Map<dynamic, dynamic>.from(raw) : <dynamic, dynamic>{};
    final cards = <LiveIncidentCard>[];
    for (final value in data.values) {
      final card =
          LiveIncidentCard.fromJson(Map<String, dynamic>.from(value as Map));
      if (card.status == 'ACTIVE') {
        cards.add(card);
      }
      if (card.status == 'ACKNOWLEDGED') {
        cards.add(card);
      }
    }
    cards.sort((a, b) {
      return b.lastUpdatedMs.compareTo(a.lastUpdatedMs);
    });
    return cards;
  });
});

final incidentHistoryProvider =
    StreamProvider<List<IncidentHistoryRecord>>((ref) {
  final profile = ref.watch(staffProfileProvider);
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || profile.hotelId.isEmpty) {
    return Stream<List<IncidentHistoryRecord>>.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('incidents')
      .where('hotelId', isEqualTo: profile.hotelId)
      .limit(300)
      .snapshots()
      .map((snapshot) {
    final records = snapshot.docs
        .map((doc) => IncidentHistoryRecord.fromFirestore(doc.id, doc.data()))
        .toList();

    records.sort((a, b) {
      return b.updatedAtMs.compareTo(a.updatedAtMs);
    });
    return records;
  });
});

final incidentDetailProvider =
    StreamProvider.family<IncidentDetailRecord?, String>((ref, incidentId) {
  if (incidentId.isEmpty) {
    return Stream<IncidentDetailRecord?>.value(null);
  }

  return FirebaseFirestore.instance
      .collection('incidents')
      .doc(incidentId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return IncidentDetailRecord.fromFirestore(doc.id, data);
  });
});

Future<void> markStaffOnline(StaffProfile profile,
    {required String name}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || profile.hotelId.isEmpty) {
    return;
  }

  final db = FirebaseDatabase.instanceFor(app: Firebase.app());
  await db.ref('hotels/${profile.hotelId}/staff_online/${user.uid}').set({
    'name': name,
    'fcmToken': '',
    'lastSeenMs': DateTime.now().millisecondsSinceEpoch,
    'isOnDuty': true,
  });
}

Future<void> syncStaffAccessProfile(StaffProfile profile,
    {required String email}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return;
  }

  final resolvedProfile =
      await resolveStaffProfile(user, fallbackProfile: profile);

  if (resolvedProfile.hotelId.isEmpty ||
      !_allowedStaffRoles.contains(resolvedProfile.role)) {
    return;
  }

  await FirebaseFirestore.instance
      .collection('staff_profiles')
      .doc(user.uid)
      .set({
    'hotelId': resolvedProfile.hotelId,
    'role': resolvedProfile.role,
    'email': email,
    'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
  }, SetOptions(merge: true));
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value.toString()) ?? fallback;
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int _asTimestampMs(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }
  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }
  if (value is num) {
    final raw = value.round();
    return raw > 9999999999 ? raw : raw * 1000;
  }
  if (value is String) {
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return _asTimestampMs(numeric);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch;
    }
    return 0;
  }
  if (value is Map) {
    final map = Map<dynamic, dynamic>.from(value);
    final seconds = map['_seconds'] ?? map['seconds'];
    if (seconds != null) {
      return _asInt(seconds) * 1000;
    }
    final ms = map['millisecondsSinceEpoch'] ?? map['ms'];
    if (ms != null) {
      return _asInt(ms);
    }
  }
  return 0;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

List<String> _extractHazards(dynamic value) {
  if (value is! List) {
    return const [];
  }

  final hazards = <String>[];
  for (final item in value) {
    if (item is String) {
      hazards.add(item.toUpperCase());
      continue;
    }
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final type = _asString(map['type']).toUpperCase();
      if (type.isNotEmpty) {
        hazards.add(type);
      }
    }
  }
  return hazards;
}

String _normalizeStaffRole(String value) {
  final role = value.trim().toUpperCase();
  return _allowedStaffRoles.contains(role) ? role : '';
}

