import 'package:flutter/material.dart'; 
 
class StatusIndicator extends StatelessWidget { 
  final String label; 
  final Color color; 
  const StatusIndicator({super.key, required this.label, required this.color}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Row(children: [Icon(Icons.circle, color: color, size: 10), const SizedBox(width: 6), Text(label)]); 
  } 
}
