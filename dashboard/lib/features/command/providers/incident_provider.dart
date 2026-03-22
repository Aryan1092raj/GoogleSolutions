import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';

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

  LiveIncidentCard({required this.incidentId, required this.status, required this.severity, required this.roomNumber, required this.floor, required this.wing, required this.guestName, required this.primaryHazard, required this.aiSummary, required this.lastUpdatedMs, required this.isStreamLive});

  factory LiveIncidentCard.fromJson(Map json) {
    return LiveIncidentCard(incidentId: json['incidentId'] == null ? '' : json['incidentId'].toString(), status: json['status'] == null ? '' : json['status'].toString(), severity: json['severity'] == null ? 'LOW' : json['severity'].toString(), roomNumber: json['roomNumber'] == null ? '' : json['roomNumber'].toString(), floor: json['floor'] == null ? 0 : int.tryParse(json['floor'].toString()) ?? 0, wing: json['wing'] == null ? '' : json['wing'].toString(), guestName: json['guestName'] == null ? '' : json['guestName'].toString(), primaryHazard: json['primaryHazard'] == null ? 'UNKNOWN' : json['primaryHazard'].toString(), aiSummary: json['aiSummary'] == null ? '' : json['aiSummary'].toString(), lastUpdatedMs: json['lastUpdatedMs'] == null ? 0 : int.tryParse(json['lastUpdatedMs'].toString()) ?? 0, isStreamLive: json['isStreamLive'] == true);
  }
}

class StaffProfile {
  final String uid;
  final String hotelId;
  final String role;
  StaffProfile({required this.uid, required this.hotelId, required this.role});
}

final staffProfileProvider = StateProvider((ref) {
  return StaffProfile(uid: '', hotelId: '', role: '');
});

final incidentListProvider = StreamProvider((ref) {
  final profile = ref.watch(staffProfileProvider);
  final hotelId = profile.hotelId;
  if (hotelId.isEmpty) {
    return const Stream.empty();
  }
  return FirebaseDatabase.instance.ref('live_incidents/' + hotelId).onValue.map((event) {
    final data = event.snapshot.value as Map? ?? {};
    final cards = [];
    for (final value in data.values) {
      final card = LiveIncidentCard.fromJson(Map.from(value));
      if (card.status == 'ACTIVE') { cards.add(card); }
      if (card.status == 'ACKNOWLEDGED') { cards.add(card); }
    }
    cards.sort((a, b) { return b.lastUpdatedMs.compareTo(a.lastUpdatedMs); });
    return cards;
  });
});
