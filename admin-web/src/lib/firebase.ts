import { initializeApp } from 'firebase/app'
import {
  browserSessionPersistence,
  getAuth,
  setPersistence,
} from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getFunctions } from 'firebase/functions'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyCQk-8ohIvN9Je_BysyO0hEiZHEbJEntqs',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'qopchaapp.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'qopchaapp',
  storageBucket:
    import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'qopchaapp.firebasestorage.app',
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '727891551013',
  appId:
    import.meta.env.VITE_FIREBASE_APP_ID ||
    '1:727891551013:android:449ff2f178a82c693ab0cc',
}

const app = initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)
export const functions = getFunctions(app, 'us-central1')

void setPersistence(auth, browserSessionPersistence)
