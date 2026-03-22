import 'package:flutter/material.dart';

class ResponderLog extends StatelessWidget {
  final String incidentId;
  const ResponderLog({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(children: [
        ListTile(title: Text('Responder log for incident: ' + incidentId)),
        const ListTile(title: Text('Logs will appear here in real-time.')),
      ]),
    );
  }
}
