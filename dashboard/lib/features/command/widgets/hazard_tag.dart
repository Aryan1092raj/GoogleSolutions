import 'package:flutter/material.dart'; 
 
class HazardTag extends StatelessWidget { 
  final String hazard; 
  const HazardTag({super.key, required this.hazard}); 
 
  @override 
  Widget build(BuildContext context) { 
    return Chip(label: Text(hazard)); 
  } 
}
