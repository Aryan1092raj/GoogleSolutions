import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/incident_provider.dart';

class ActionControls extends ConsumerStatefulWidget {
  final String incidentId;
  const ActionControls({super.key, required this.incidentId});
  @override
  ConsumerState<ActionControls> createState() => _ActionControlsState();
}

class _ActionControlsState extends ConsumerState<ActionControls> {
  final _noteCtrl = TextEditingController();

  Future<void> _patchStatus(String status) async {
    if (widget.incidentId.isEmpty || widget.incidentId == '-') return;
    await FirebaseFirestore.instance
        .collection('incidents').doc(widget.incidentId)
        .update({'status': status});
  }

  Future<void> _logAction() async {
    final action = _noteCtrl.text.trim();
    if (action.isEmpty || widget.incidentId.isEmpty) return;
    final profile = ref.read(staffProfileProvider);
    await FirebaseFirestore.instance
        .collection('incidents').doc(widget.incidentId)
        .update({
      'responderLog': FieldValue.arrayUnion([{
        'timestamp': DateTime.now().toIso8601String(),
        'staffId': profile.uid,
        'staffName': profile.uid,
        'action': action,
        'type': 'ACTION',
      }])
    });
    _noteCtrl.clear();
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: FilledButton.tonal(
              onPressed: () => _patchStatus('ACKNOWLEDGED'),
              child: const Text('Acknowledge'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.tonal(
              onPressed: () => _patchStatus('RESOLVED'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800),
              child: const Text('Resolve'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Log an action...', isDense: true,
                border: OutlineInputBorder()),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _logAction, icon: const Icon(Icons.send)),
          ]),
        ]),
      ),
    );
  }
}