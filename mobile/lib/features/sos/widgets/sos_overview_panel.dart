import 'package:flutter/material.dart';

class SOSOverviewPanel extends StatelessWidget {
  const SOSOverviewPanel({
    super.key,
    required this.liveStreamCard,
    required this.aiStatusCard,
    required this.actionButtons,
  });

  final Widget liveStreamCard;
  final Widget aiStatusCard;
  final Widget actionButtons;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        liveStreamCard,
        const SizedBox(height: 14),
        aiStatusCard,
        const SizedBox(height: 14),
        actionButtons,
      ],
    );
  }
}
