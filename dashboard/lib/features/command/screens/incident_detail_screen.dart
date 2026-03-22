import 'package:flutter/material.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Incident ' + incidentId)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Incident ID: ' + incidentId),
          const SizedBox(height: 8),
          const Text('Full incident details are loaded from Firestore in production mode.'),
        ]),
      ),
    );
  }
}
