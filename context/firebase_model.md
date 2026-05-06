# Firebase model

## Purpose
This file explains where Firebase configuration lives and highlights important conventions.

## Source of truth
- Firebase project aliases: `.firebaserc`
- Firebase hosting/functions/emulators config: `firebase.json`
- Firestore rules: `firestore.rules`
- Firestore indexes: `firestore.indexes.json`
- Storage rules: `storage.rules`
- Firebase client config: `lib/firebase_options.dart`
- Cloud Functions: `functions/`

## Agent instruction
Before changing Firebase-related code, rules, indexes, functions, hosting, storage, auth, or email-extension behavior, read the relevant source files directly.

## Notes
TODO: Add only high-level notes, gotchas, and decisions here.
