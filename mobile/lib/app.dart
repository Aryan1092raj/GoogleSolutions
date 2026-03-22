import 'package:flutter/material.dart'; 
import 'core/router.dart'; 
import 'core/theme.dart'; 
 
class ResQLinkApp extends StatelessWidget { 
  const ResQLinkApp({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 
    return MaterialApp.router( 
      title: 'ResQLink', 
      theme: buildAppTheme(), 
      routerConfig: appRouter, 
    ); 
  } 
}
