import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/features/sos/models/sos_active_panel.dart';

void main() {
  group('SOSActivePanel', () {
    test('defaults to sos for null or unknown query values', () {
      expect(SOSActivePanel.fromQueryValue(null), SOSActivePanel.sos);
      expect(SOSActivePanel.fromQueryValue('unknown'), SOSActivePanel.sos);
    });

    test('parses messages and guide query values', () {
      expect(
        SOSActivePanel.fromQueryValue('messages'),
        SOSActivePanel.messages,
      );
      expect(SOSActivePanel.fromQueryValue('guide'), SOSActivePanel.guide);
    });

    test('exposes stable query values for router usage', () {
      expect(SOSActivePanel.sos.queryValue, 'sos');
      expect(SOSActivePanel.messages.queryValue, 'messages');
      expect(SOSActivePanel.guide.queryValue, 'guide');
    });
  });
}
