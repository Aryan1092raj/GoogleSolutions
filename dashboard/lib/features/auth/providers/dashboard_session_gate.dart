import 'package:flutter/foundation.dart';

import '../../command/providers/incident_provider.dart';

enum DashboardSessionStatus {
  hydrating,
  signedOut,
  authorized,
  unauthorized,
}

class DashboardSessionSnapshot {
  final DashboardSessionStatus status;
  final StaffProfile profile;

  const DashboardSessionSnapshot({
    required this.status,
    required this.profile,
  });

  bool get canAccessDashboard => status == DashboardSessionStatus.authorized;

  static const signedOut = DashboardSessionSnapshot(
    status: DashboardSessionStatus.signedOut,
    profile: StaffProfile.empty,
  );

  static const hydrating = DashboardSessionSnapshot(
    status: DashboardSessionStatus.hydrating,
    profile: StaffProfile.empty,
  );

  static const unauthorized = DashboardSessionSnapshot(
    status: DashboardSessionStatus.unauthorized,
    profile: StaffProfile.empty,
  );
}

final dashboardSessionGate =
    ValueNotifier<DashboardSessionSnapshot>(DashboardSessionSnapshot.signedOut);
