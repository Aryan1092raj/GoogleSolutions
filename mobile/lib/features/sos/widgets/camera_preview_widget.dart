import 'package:flutter/material.dart'; 
 
class CameraPreviewWidget extends StatelessWidget { 
  final Widget child; 
  const CameraPreviewWidget({super.key, required this.child}); 
 
  @override 
  Widget build(BuildContext context) { 
    return SizedBox.expand(child: child); 
  } 
} 
