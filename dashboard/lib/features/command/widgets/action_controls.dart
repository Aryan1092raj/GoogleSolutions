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
  bool _sending = false;

  bool get _hasIncident =>
      widget.incidentId.isNotEmpty && widget.incidentId != '-';

  Future<void> _patchStatus(String status) async {
    if (!_hasIncident) return;
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incidentId)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logAction() async {
    final action = _noteCtrl.text.trim();
    if (action.isEmpty || !_hasIncident) {
      if (mounted && action.isNotEmpty && !_hasIncident) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Select an active incident first')));
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final profile = ref.read(staffProfileProvider);
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incidentId)
          .update({
        'responderLog': FieldValue.arrayUnion([
          {
            'timestamp': DateTime.now().toIso8601String(),
            'staffId': profile.uid,
            'staffName': profile.uid.isNotEmpty ? profile.uid : 'Staff',
            'action': action,
            'type': 'ACTION',
          }
        ])
      });
      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Action logged')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
              onPressed: _hasIncident ? () => _patchStatus('ACKNOWLEDGED') : null,
              child: const Text('Acknowledge'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.tonal(
              onPressed: _hasIncident ? () => _patchStatus('RESOLVED') : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800),
              child: const Text('Resolve'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _noteCtrl,
              enabled: _hasIncident,
              decoration: InputDecoration(
                hintText: _hasIncident
                    ? 'Log an action...'
                    : 'Select an incident first',
                isDense: true,
                border: const OutlineInputBorder()),
              onSubmitted: (_) => _logAction(),
            )),
            const SizedBox(width: 8),
            _sending
                ? const SizedBox(width: 40, height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton.filled(
                    onPressed: _hasIncident ? _logAction : null,
                    icon: const Icon(Icons.send)),
          ]),
        ]),
      ),
    );
  }
}