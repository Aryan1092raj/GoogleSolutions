import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestProfile {
  final String guestId;
  final String guestName;
  final String roomNumber;
  final String language;
  final String hotelId;

  const GuestProfile({
    required this.guestId,
    required this.guestName,
    required this.roomNumber,
    required this.language,
    required this.hotelId,
  });
}

class GuestProfileNotifier extends StateNotifier {
  GuestProfileNotifier() : super(null);

  void setProfile(GuestProfile value) {
    state = value;
  }

  void clear() {
    state = null;
  }
}

final authStateProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final guestProfileProvider = StateNotifierProvider((ref) {
  return GuestProfileNotifier();
});
