import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestProfile {
  final String guestId;
  final String guestName;
  final String roomNumber;
  final String language;
  final String hotelId;
  final int? floor;
  final String? wing;

  const GuestProfile({
    required this.guestId,
    required this.guestName,
    required this.roomNumber,
    required this.language,
    required this.hotelId,
    this.floor,
    this.wing,
  });

  // Fix #5 — copyWith required by onboarding_screen and SOS language picker
  GuestProfile copyWith({
    String? guestId,
    String? guestName,
    String? roomNumber,
    String? language,
    String? hotelId,
    int? floor,
    String? wing,
  }) {
    return GuestProfile(
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      roomNumber: roomNumber ?? this.roomNumber,
      language: language ?? this.language,
      hotelId: hotelId ?? this.hotelId,
      floor: floor ?? this.floor,
      wing: wing ?? this.wing,
    );
  }
}

class GuestProfileNotifier extends StateNotifier<GuestProfile?> {
  GuestProfileNotifier() : super(null);

  void setProfile(GuestProfile value) {
    state = value;
  }

  // Fix #4 — register() called by OnboardingScreen.
  // guestId/guestName are optional so the 3-arg onboarding call compiles.
  void register({
    String guestId = '',
    String guestName = '',
    required String hotelId,
    required String roomNumber,
    required String language,
    int? floor,
    String? wing,
  }) {
    state = GuestProfile(
      guestId: guestId,
      guestName: guestName,
      hotelId: hotelId,
      roomNumber: roomNumber,
      language: language,
      floor: floor,
      wing: wing,
    );
  }

  void clear() {
    state = null;
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final guestProfileProvider =
    StateNotifierProvider<GuestProfileNotifier, GuestProfile?>((ref) {
  return GuestProfileNotifier();
});
