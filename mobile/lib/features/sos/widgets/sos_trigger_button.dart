import 'package:flutter/material.dart'; 
 
class SOSTriggerButton extends StatelessWidget { 
  final VoidCallback onPressed; 
  const SOSTriggerButton({super.key, required this.onPressed}); 
 
  @override 
  Widget build(BuildContext context) { 
    return ElevatedButton(onPressed: onPressed, child: const Text('SOS')); 
  } 
} 
