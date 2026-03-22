import 'package:firebase_core/firebase_core.dart'; 
 
class DashboardFirebaseService { 
  Future initialize() async { 
    await Firebase.initializeApp(); 
  } 
} 
