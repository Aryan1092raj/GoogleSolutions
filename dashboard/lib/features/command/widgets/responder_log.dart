import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResponderLog extends StatelessWidget {
  final String incidentId;
  const ResponderLog({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    if (incidentId.isEmpty || incidentId == '-') {
      return const Card(
        child: Center(child: Text('Select an incident to view responder log')),
      );
    }

    return Card(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('incidents').doc(incidentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final rawLog = data['responderLog'] as List<dynamic>? ?? <dynamic>[];
          final entries = rawLog.map((e) => Map<String, dynamic>.from(e as Map)).toList().reversed.toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No responder log entries yet'));
          }

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final action = entry['action']?.toString() ?? '';
              final staffName = entry['staffName']?.toString() ?? 'System';
              return ListTile(
                dense: true,
                leading: const Icon(Icons.history),
                title: Text(action),
                subtitle: Text(staffName),
              );
            },
          );
        },
      ),
    );
  }
}
