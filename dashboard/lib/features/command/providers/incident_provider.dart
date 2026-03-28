import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class LiveIncidentCard {
  final String incidentId;
  final String status;
  final String severity;
  final String roomNumber;
  final int floor;
  final String wing;
  final String guestName;
  final String primaryHazard;
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
    required this.aiSummary,
    required this.lastUpdatedMs,
    required this.isStreamLive,
    this.acknowledgedBy,
  });

  factory LiveIncidentCard.fromJson(Map<String, dynamic> json) {
    return LiveIncidentCard(
      incidentId: json['incidentId'] == null ? '' : json['incidentId'].toString(),
      status: json['status'] == null ? '' : json['status'].toString(),
      severity: json['severity'] == null ? 'LOW' : json['severity'].toString(),
      roomNumber: json['roomNumber'] == null ? '' : json['roomNumber'].toString(),
      floor: json['floor'] == null ? 0 : int.tryParse(json['floor'].toString()) ?? 0,
      wing: json['wing'] == null ? '' : json['wing'].toString(),
      guestName: json['guestName'] == null ? '' : json['guestName'].toString(),
      primaryHazard: json['primaryHazard'] == null ? 'UNKNOWN' : json['primaryHazard'].toString(),
      aiSummary: json['aiSummary'] == null ? '' : json['aiSummary'].toString(),
      lastUpdatedMs: json['lastUpdatedMs'] == null ? 0 : int.tryParse(json['lastUpdatedMs'].toString()) ?? 0,
      isStreamLive: json['isStreamLive'] == true,
      acknowledgedBy: json['acknowledgedBy'] == null ? null : json['acknowledgedBy'].toString(),
    );
  }
}

class StaffProfile {
  final String uid;
  final String hotelId;
  final String role;
  StaffProfile({required this.uid, required this.hotelId, required this.role});
}

final staffProfileProvider = StateProvider<StaffProfile>((ref) {
  return StaffProfile(uid: '', hotelId: '', role: '');
});

final incidentListProvider = StreamProvider<List<LiveIncidentCard>>((ref) {
  final profile = ref.watch(staffProfileProvider);
  final hotelId = profile.hotelId;
  if (hotelId.isEmpty) {
    return const Stream<List<LiveIncidentCard>>.empty();
  }
  final db = FirebaseDatabase.instanceFor(app: Firebase.app());
  return db.ref('live_incidents/$hotelId').onValue.map((event) {
    final raw = event.snapshot.value;
    final data = raw is Map ? Map<dynamic, dynamic>.from(raw) : <dynamic, dynamic>{};
    final cards = <LiveIncidentCard>[];
    for (final value in data.values) {
      final card = LiveIncidentCard.fromJson(Map<String, dynamic>.from(value as Map));
      if (card.status == 'ACTIVE') { cards.add(card); }
      if (card.status == 'ACKNOWLEDGED') { cards.add(card); }
    }
    cards.sort((a, b) { return b.lastUpdatedMs.compareTo(a.lastUpdatedMs); });
    return cards;
  });
});

Future<void> markStaffOnline(StaffProfile profile, {required String name}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || profile.hotelId.isEmpty) {
    return;
  }

  final db = FirebaseDatabase.instanceFor(app: Firebase.app());
  await db
      .ref('hotels/${profile.hotelId}/staff_online/${user.uid}')
      .set({
    'name': name,
    'fcmToken': '',
    'lastSeenMs': DateTime.now().millisecondsSinceEpoch,
    'isOnDuty': true,
  });
}
