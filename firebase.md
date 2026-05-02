# 🔥 Firebase Production Deployment Checklist

> This document tracks Firebase configuration tasks required **before releasing to production**.
> During development, all Firebase services run via the **Local Emulator Suite**.

---

## Current Development Setup

| Service | Emulator Port | Status |
|---------|--------------|--------|
| Firestore | `8080` | ✅ Active |
| Auth | `9099` | ✅ Active |
| Storage | `9199` | ✅ Active |
| Hosting | `5000` | ✅ Active |
| Functions | `5001` | ⏳ Not yet needed |

### 💾 Emulator Persistence (New)
By default, emulators clear all data on restart. To make them "remember" your admin whitelist, exams, and users, use the persistence script:

```bash
# From the app/ directory
./scripts/start_emulators.sh
```

This script:
1. Imports data from `app/.firebase_emulator_data/`
2. Automatically saves (exports) all changes back to that folder when you stop the emulator (Ctrl+C).

**Project ID**: `edtech-3f6fe`
**Account**: `joelgoogfle@gmail.com`
**Region**: `asia-south1` (Mumbai)

---

## 🔴 Critical (Must-Do Before Release)

### 1. Enable Firebase Storage in Console
- Go to: Firebase Console → Storage → Get Started
- Select region: `asia-south1`
- Deploy rules: `firebase --project=edtech-3f6fe deploy --only storage`

### 2. Android SHA-1 Fingerprint (Google Sign-In)
```bash
cd android && ./gradlew signingReport
```
- Copy SHA-1 from `debug` variant
- Add in Firebase Console → Project Settings → Android App → SHA certificate fingerprints
- Download updated `google-services.json` and replace in `android/app/`

### 3. iOS Reversed Client ID
- Download latest `GoogleService-Info.plist` from Firebase Console
- Update URL Scheme in Xcode: `REVERSED_CLIENT_ID` value from the plist
- Replace `ios/Runner/GoogleService-Info.plist`

### 4. Deploy Firestore Security Rules
```bash
firebase --project=edtech-3f6fe deploy --only firestore:rules
```

### 5. Deploy Storage Security Rules
```bash
firebase --project=edtech-3f6fe deploy --only storage
```

### 6. Remove Emulator Connection
- In `main.dart`, remove or conditionally disable the emulator connection block:
```dart
// REMOVE FOR PRODUCTION:
// await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
// FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
// await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```
- Replace with environment-based toggle (e.g. `kDebugMode` or flavor-based config)

---

## 🟡 Important (Before Public Launch)

### 7. Firebase App Check
- Protects backend resources from abuse
- Enable in Console → App Check
- Android: Use Play Integrity provider
- iOS: Use DeviceCheck / App Attest provider
- Web: Use reCAPTCHA Enterprise
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

### 8. Firestore Composite Indexes
Create composite indexes for common queries:
```
Collection: exams
  - Fields: status (ASC), createdAt (DESC)
  
Collection: attempts  
  - Fields: userId (ASC), examId (ASC), startedAt (DESC)
  
Collection: exams/{examId}/questions
  - Fields: order (ASC)
```
Deploy via: `firebase --project=edtech-3f6fe deploy --only firestore:indexes`

### 9. Apple Sign-In Configuration
- Requires Apple Developer Program membership ($99/year)
- Enable "Sign in with Apple" capability in Xcode
- Configure Services ID in Apple Developer Console
- Add OAuth redirect URI in Firebase Console → Auth → Apple

### 10. Firebase Analytics
```bash
flutter pub add firebase_analytics
```
- Track screen views, exam completions, user engagement
- Enable in Console → Analytics

---

## 🟠 Nice-to-Have (Post-Launch)

### 11. Cloud Functions
- Move XP/coin reward logic server-side (prevent client-side manipulation)
- Automated notifications for new exams
- Scheduled cleanup of abandoned attempts
```bash
firebase init functions
```

### 12. Firebase Crashlytics
```bash
flutter pub add firebase_crashlytics
```
- Real-time crash reporting
- Enable in Console → Crashlytics

### 13. Firebase Remote Config
- A/B test UI changes
- Feature flags for gradual rollout
- Dynamic difficulty adjustments

### 14. Firebase Performance Monitoring
- Track app startup time, network latency
- Monitor Firestore query performance

### 15. Backup & Export
- Enable Firestore daily backups
- Configure export to BigQuery for analytics

---

## Firestore Collections Reference

| Collection | Sub-collections | Purpose |
|------------|-----------------|---------|
| `users` | — | User profiles, roles, XP, coins |
| `admin_whitelist` | — | Whitelisted admin emails |
| `exams` | `questions` | Exam metadata + MCQ questions |
| `attempts` | — | Student exam attempts & scores |
| `quests` | — | Gamification quest definitions |
| `skins` | — | Avatar store skins catalog |
| `system` | — | App config & feature flags |

---

*Last updated: April 22, 2026*
