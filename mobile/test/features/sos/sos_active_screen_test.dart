import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_mobile/features/sos/models/sos_active_panel.dart';
import 'package:resqlink_mobile/features/sos/screens/sos_active_screen.dart';

void main() {
  testWidgets('renders the guide panel when guide is selected', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SOSActiveScreen(
            incidentId: 'incident-42',
            initialPanel: SOSActivePanel.guide,
            autoStartStreaming: false,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('LIVE SAFETY GUIDE'), findsOneWidget);
    expect(find.text('AI SAFETY ASSISTANT'), findsNothing);
  });
}
