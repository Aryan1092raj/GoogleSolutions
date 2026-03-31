import 'package:flutter/material.dart'; 
 
class IncidentCard extends StatelessWidget { 
  final String title; 
  final String severity; 
  final String room; 
  final String floor; 
  const IncidentCard({super.key, required this.title, required this.severity, required this.room, required this.floor}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Card(child: ListTile(title: Text(title), subtitle: Text('$severity - $room - $floor'))); 
  } 
} 
