import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/dashboard_theme.dart';

class DashboardShell extends StatelessWidget {
  final String hotelLabel;
  final String roleLabel;
  final String title;
  final String subtitle;
  final int activeCount;
  final Widget body;

  const DashboardShell({
    super.key,
    required this.hotelLabel,
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.activeCount,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              hotelLabel: hotelLabel,
              roleLabel: roleLabel,
              title: title,
              subtitle: subtitle,
              activeCount: activeCount,
            ),
            Expanded(
              child: Row(
                children: [
                  const _NavRail(),
                  Expanded(child: body),
                ],
              ),
            ),
            const _StatusBar(),
          ],
        ),
      ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: dashboardPanelDecoration(),
      padding: padding,
      child: child,
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kDashTextDim, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: kDashText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: kDashTextMut,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String hotelLabel;
  final String roleLabel;
  final String title;
  final String subtitle;
  final int activeCount;

  const _TopBar({
    required this.hotelLabel,
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kDashTopBarHeight,
      color: kDashPanel,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'RESQLINK',
            style: GoogleFonts.inter(
              color: kDashText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: kDashTextSub,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activeCount > 0
                  ? kDashDanger.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: activeCount > 0 ? kDashDanger.withValues(alpha: 0.3) : kDashBorder,
              ),
            ),
            child: Text(
              '$activeCount ACTIVE',
              style: GoogleFonts.inter(
                color: activeCount > 0 ? kDashDanger : kDashTextMut,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          Text(
            hotelLabel,
            style: GoogleFonts.inter(
              color: kDashTextMut,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            roleLabel,
            style: GoogleFonts.inter(
              color: kDashInfo,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 280,
            child: TextField(
              readOnly: true,
              decoration: InputDecoration(
                isDense: true,
                hintText: subtitle,
                prefixIcon: const Icon(Icons.search, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Container(
      width: kDashNavRailWidth,
      color: kDashPanel,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.dashboard_outlined,
            tooltip: 'Command Center',
            selected: location == '/dashboard',
            onTap: () => context.go('/dashboard'),
          ),
          _NavItem(
            icon: Icons.map_outlined,
            tooltip: 'Live Map',
            selected: location == '/dashboard/map',
            onTap: () => context.go('/dashboard/map'),
          ),
          _NavItem(
            icon: Icons.videocam_outlined,
            tooltip: 'Video Monitor',
            selected: location == '/dashboard/video',
            onTap: () => context.go('/dashboard/video'),
          ),
          _NavItem(
            icon: Icons.history_outlined,
            tooltip: 'Incident History',
            selected: location == '/incident-history',
            onTap: () => context.go('/incident-history'),
          ),
          _NavItem(
            icon: Icons.qr_code_2_outlined,
            tooltip: 'QR Generator',
            selected: location == '/qr-generator',
            onTap: () => context.go('/qr-generator'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: kDashNavRailWidth,
          height: 52,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? kDashAccent : Colors.transparent,
                width: 2,
              ),
            ),
            color: selected ? kDashSurface : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: selected ? kDashText : kDashTextMut,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kDashStatusBarHeight,
      color: kDashPanel,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.circle, color: kDashGreen, size: 8),
          const SizedBox(width: 8),
          Text(
            'CONNECTED',
            style: GoogleFonts.inter(
              color: kDashTextMut,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Realtime incidents, frames, and guest chat active',
            style: GoogleFonts.inter(
              color: kDashTextDim,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
