import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sos_provider.dart';

class SOSActiveScreen extends ConsumerWidget {
  final String incidentId;
  const SOSActiveScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sosProvider);
    final severity = state.severity == null ? 'LOW' : state.severity.toString();
    final message = state.aiMessage == null ? 'Analyzing emergency stream...' : state.aiMessage.toString();
    return Scaffold(
      body: Stack(children: [
        Container(color: Colors.black12),
        const Positioned(top: 24, right: 24, child: Icon(Icons.circle, color: Colors.red)),
        Positioned(left: 16, right: 16, bottom: 24, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Severity: ' + severity), const SizedBox(height: 8), Text(message), const SizedBox(height: 8), Text(state.helpOnWay ? 'Help is on the way' : 'Dispatch in progress')] )))),
        Positioned(
          right: 16,
          bottom: 140,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
            onPressed: () async {
              final shouldEnd = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('End SOS'),
                    content: const Text('Are you sure you want to end this SOS session?'),
                    actions: [TextButton(onPressed: () { Navigator.of(context).pop(false); }, child: const Text('No')), TextButton(onPressed: () { Navigator.of(context).pop(true); }, child: const Text('Yes'))],
                  );
                },
              );
              if (shouldEnd == true) {
                await ref.read(sosProvider.notifier).endSOS('RESOLVED_BY_GUEST');
                if (context.mounted) { context.go('/sos/resolved/' + incidentId); }
              }
            },
            child: const Text('End SOS'),
          ),
        ),
      ]),
    );
  }
}
