import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resqlink_dashboard/features/command/widgets/incident_map_widget.dart';

void main() {
  testWidgets('shows no gps state when incident coordinates are missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: IncidentMapWidget(
              lat: null,
              lng: null,
              roomNumber: '402',
              severity: 'HIGH',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No GPS data'), findsOneWidget);
    expect(find.byIcon(Icons.location_off), findsOneWidget);
  });
}
