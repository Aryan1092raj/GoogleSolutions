import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/websocket_service.dart';

final dashboardWsProvider = Provider<DashboardWebSocketService>((ref) {
  final service = DashboardWebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final videoFrameStreamProvider = StreamProvider.family<String, String>((ref, incidentId) async* {
  final ws = ref.read(dashboardWsProvider);
  
  if (incidentId.isEmpty) return;
  
  await ws.connect(incidentId);
  
  await for (final chunk in ws.mediaChunks) {
    if (chunk.video != null && chunk.video!.isNotEmpty) {
      yield chunk.video!;
    }
  }
});
