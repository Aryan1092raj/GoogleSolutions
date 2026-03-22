import admin from 'firebase-admin'; 
 
let firebaseApp = null; 
 
export function getFirebaseApp() { 
  if (firebaseApp) { 
    return firebaseApp; 
  } 
 
  firebaseApp = admin.initializeApp({ 
    credential: admin.credential.applicationDefault(), 
    databaseURL: process.env.FIREBASE_DATABASE_URL, 
  }); 
 
  return firebaseApp; 
} 
 
export function getFirestore() { 
  return getFirebaseApp().firestore(); 
} 
 
export function getRtdb() { 
  return getFirebaseApp().database(); 
} 
 
export function getMessaging() { 
  return getFirebaseApp().messaging(); 
}
