import 'package:firebase_auth/firebase_auth.dart'; 
 
class FirebaseService { 
  Future signInWithCustomToken(String token) async { 
    return FirebaseAuth.instance.signInWithCustomToken(token); 
  } 
}
