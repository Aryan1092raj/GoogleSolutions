import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TranscriptPanel extends StatelessWidget {
  final String incidentId;
  const TranscriptPanel({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    if (incidentId.isEmpty || incidentId == '-') {
      return const Card(child: Center(child: Text('No incident selected')));
    }
    return Card(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('incidents').doc(incidentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() ?? {};
          final original = data['originalTranscript']?.toString() ?? '';
          final translated = data['translatedTranscript']?.toString() ?? '';
          final lang = data['detectedLanguage']?.toString() ?? 'en';
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Transcript', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (original.isNotEmpty) ...[
                Text('[$lang] $original', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('→ $translated',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
              ] else
                const Text('Awaiting transcript...', style: TextStyle(color: Colors.grey)),
            ]),
          );
        },
      ),
    );
  }
}