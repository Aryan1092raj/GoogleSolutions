import 'package:flutter/material.dart'; 
import 'package:go_router/go_router.dart';
 
class SOSResolvedScreen extends StatelessWidget { 
  final String incidentId; 
  const SOSResolvedScreen({super.key, required this.incidentId}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar(title: const Text('SOS Resolved')), 
      body: Center( 
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [ 
            const Text('Help has been dispatched or issue resolved.'), 
            const SizedBox(height: 8), 
            Text('Incident ID: ' + incidentId), 
            const SizedBox(height: 16), 
            ElevatedButton(onPressed: () { context.go('/home'); }, child: const Text('Return to Home')), 
          ], 
        ), 
      ), 
    ); 
  } 
}
