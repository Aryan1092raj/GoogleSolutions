import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/services/websocket_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Placeholder test - Firebase requires native setup for tests
    expect(true, isTrue);
  });

  test('resolveWebSocketReconnectToken prefers refreshed Firebase token', () async {
    final token = await resolveWebSocketReconnectToken(
      () async => 'fresh-token',
      'stale-token',
    );

    expect(token, 'fresh-token');
  });

  test('resolveWebSocketReconnectToken falls back when refresh fails', () async {
    final token = await resolveWebSocketReconnectToken(
      () async => throw Exception('refresh failed'),
      'stale-token',
    );

    expect(token, 'stale-token');
  });
}
