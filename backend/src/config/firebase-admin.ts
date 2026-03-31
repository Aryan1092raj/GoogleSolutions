import admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

let firebaseApp: admin.app.App | null = null;

export function getFirebaseApp(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  // Try multiple credential sources
  let credential: admin.credential.Credential;
  
  // 1. Check for local service account file
  const localKeyPath = path.join(__dirname, '../../gcp-sa-key.json');
  const envKeyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  
  if (fs.existsSync(localKeyPath)) {
    credential = admin.credential.cert(localKeyPath);
  } else if (envKeyPath && fs.existsSync(envKeyPath)) {
    credential = admin.credential.cert(envKeyPath);
  } else {
    // Fallback to application default (works in Cloud Run)
    credential = admin.credential.applicationDefault();
  }

  firebaseApp = admin.initializeApp({
    credential,
    databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://solution-e2a1c-default-rtdb.firebaseio.com',
  });

  firebaseApp.firestore().settings({ ignoreUndefinedProperties: true });

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
