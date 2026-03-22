import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/camera_service.dart';
import '../providers/sos_provider.dart';

class SOSActiveScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const SOSActiveScreen({super.key, required this.incidentId});

  @override
  ConsumerState createState() {
    return _SOSActiveScreenState();
  }
}

class _SOSActiveScreenState extends ConsumerState<SOSActiveScreen> {
  final CameraService _camera = CameraService();
  late final Future<void> _cameraInit;

  @override
  void initState() {
    super.initState();
    _cameraInit = _camera.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosProvider);
    final severity = state.severity == null ? 'LOW' : state.severity.toString();
    final message = state.aiMessage == null ? 'Analyzing emergency stream...' : state.aiMessage.toString();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _cameraInit,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return _camera.buildPreview();
                }
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
          const Positioned(top: 24, right: 24, child: Icon(Icons.circle, color: Colors.red)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Severity: ' + severity),
                    const SizedBox(height: 8),
                    Text(message),
                    const SizedBox(height: 8),
                    Text(state.helpOnWay ? 'Help is on the way' : 'Dispatch in progress'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
              onPressed: () async {
                final shouldEnd = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('End SOS'),
                      content: const Text('Are you sure you want to end this SOS session?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
                      ],
                    );
                  },
                );
                if (shouldEnd == true) {
                  await ref.read(sosProvider.notifier).endSOS('RESOLVED_BY_GUEST');
                  if (context.mounted) {
                    context.go('/sos/resolved/' + widget.incidentId);
                  }
                }
              },
              child: const Text('End SOS'),
            ),
          ),
        ],
      ),
    );
  }
}
