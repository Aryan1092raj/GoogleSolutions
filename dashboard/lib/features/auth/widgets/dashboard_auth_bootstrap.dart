import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../command/providers/incident_provider.dart';

class DashboardAuthBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardAuthBootstrap({super.key, required this.child});

  @override
  ConsumerState<DashboardAuthBootstrap> createState() =>
      _DashboardAuthBootstrapState();
}

class _DashboardAuthBootstrapState
    extends ConsumerState<DashboardAuthBootstrap> {
  StreamSubscription<User?>? _authSubscription;
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance
        .idTokenChanges()
        .listen(_syncStaffProfile, onError: (_, __) {
      if (mounted) {
        setState(() => _hydrating = false);
      }
    });
  }

  Future<void> _syncStaffProfile(User? user) async {
    if (!mounted) {
      return;
    }

    if (user == null) {
      ref.read(staffProfileProvider.notifier).state = StaffProfile.empty;
      setState(() => _hydrating = false);
      return;
    }

    setState(() => _hydrating = true);

    try {
      final profile = await resolveStaffProfile(user);
      ref.read(staffProfileProvider.notifier).state = profile;
    } catch (_) {
      ref.read(staffProfileProvider.notifier).state = StaffProfile(
        uid: user.uid,
        hotelId: '',
        role: '',
      );
    } finally {
      if (mounted) {
        setState(() => _hydrating = false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hydrating && FirebaseAuth.instance.currentUser != null) {
      return const ColoredBox(
        color: Color(0xFF071325),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return widget.child;
  }
}
