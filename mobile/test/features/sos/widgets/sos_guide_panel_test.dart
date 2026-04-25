import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/features/sos/widgets/sos_guide_panel.dart';

void main() {
  testWidgets('renders critical guidance and live assistant message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SOSGuidePanel(
            severity: 'CRITICAL',
            aiMessage: 'Intruder detected near the hallway.',
            helpOnWay: true,
            etaMinutes: 3,
          ),
        ),
      ),
    );

    expect(find.text('LIVE SAFETY GUIDE'), findsOneWidget);
    expect(find.text('Intruder detected near the hallway.'), findsOneWidget);
    expect(find.textContaining('Remain hidden'), findsOneWidget);
    expect(find.textContaining('Response ETA: 3 min'), findsOneWidget);
  });
}
