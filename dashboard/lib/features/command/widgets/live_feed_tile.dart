import 'package:flutter/material.dart';
import 'hazard_tag.dart';

class LiveFeedTile extends StatelessWidget {
  final String hazard;
  final String summary;
  const LiveFeedTile({super.key, required this.hazard, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('LIVE VIDEO FEED'),
          const SizedBox(height: 10),
          const Expanded(child: ColoredBox(color: Colors.black12)),
          const SizedBox(height: 10),
          Row(children: [HazardTag(hazard: hazard), const SizedBox(width: 8), Expanded(child: Text(summary.isEmpty ? 'Awaiting AI summary' : summary))]),
        ]),
      ),
    );
  }
}
