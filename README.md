# 🎮 RIMS — Root Institute of Mathematics

> **Neo-Arcade Editorial** — 8-bit nostalgia reimagined for high-end ed-tech.

A gamified exam platform built with Flutter, Firebase, and BLoC state management for **Root Institute of Mathematics (RIMS) — Mathematics Learning Centre**. Students level up through quests and exams, earning XP and climbing the leaderboard.

---

## 📋 Current Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Done | Planning, Design System, Firebase Schema |
| Phase 2 | ✅ Done | App Scaffolding, Theme, Router, Models |
| Phase 3 | ✅ Done | Backend Integration (Firebase + Repositories) |
| Phase 4 | ✅ Done | Full UI Implementation |
| Phase 5 | ✅ Done | Testing & QA |
| Phase 6 | ✅ Done | Data Integration & Live Logic |
| Phase 7 | ✅ Done | Economy & Avatar System |
| Phase 8 | ✅ Done | Rebranding (RIMS), Upload Features, Documentation |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.7.1`
- Dart SDK `>=3.7.0`
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### Setup
```bash
cd app/
flutter pub get
flutter run
```

### Firebase Project
- **Project ID:** `edtech-3f6fe`
- **Account:** `joelgoogfle@gmail.com`
- **Firestore Region:** `asia-south1` (Mumbai, India)

---

## 🛠️ Future Config

### OAuth Configuration
To enable production authentication, the following configurations are required in the Firebase Console and Developer Portals:

#### Google Sign-In
- **iOS:** Add `REVERSED_CLIENT_ID` to `Info.plist`.
- **Android:** Ensure SHA-1 and SHA-256 fingerprints are added to the Firebase project settings.
- **Web:** Add the authorized redirect URI to the Google Cloud Console.

#### Apple Sign-In
- **App ID:** Create an App ID with the "Sign In with Apple" capability in the [Apple Developer Portal](https://developer.apple.com/).
- **Service ID:** Configure a Service ID for web/Android if needed.
- **Private Key:** Generate a `.p8` key for server-side validation and upload it to Firebase Console.
- **Entitlements:** Ensure `com.apple.developer.applesignin` is added to the iOS target's entitlements.
- **Production Handshake:** Ensure the Firebase Auth handler is correctly configured with the Team ID and Key ID.

### iStar (Future Integration)
- **iStar** is our planned internal asset repository and local cache system.
- **Internal Storage:** Optimized for low-latency retrieval of high-resolution educational assets.
- **Asset Repository:** Version-controlled storage for exam textures, pixel art, and media.
- **Isar Integration:** Leverages the `isar` local database for offline-first performance and reduced Firestore costs.
- **Global CDN:** Plans to integrate with a CDN for fast global delivery of educational content.


---

## 🏗️ Architecture

### Feature-First Structure
```
lib/
├── main.dart                          # Entry point (Firebase init → DI → runApp)
├── app.dart                           # MaterialApp.router + AuthBloc provider
├── firebase_options.dart              # Generated Firebase config
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # 68 color tokens (Neo-Arcade palette)
│   │   ├── app_spacing.dart           # 4px base unit system
│   │   └── app_typography.dart        # Press Start 2P / VT323 / Space Grotesk
│   ├── di/injection.dart              # GetIt DI container (fully wired)
│   ├── errors/
│   │   ├── app_exception.dart         # 7 sealed exception subtypes
│   │   └── result.dart                # Success/Failure sealed type
│   ├── router/app_router.dart         # GoRouter + auth redirect guards
│   ├── theme/app_theme.dart           # Full ThemeData (0px radius everywhere)
│   ├── utils/
│   │   ├── logger.dart                # Structured logging
│   │   └── validators.dart            # Form validation helpers
│   └── widgets/
│       ├── placeholder_page.dart      # Phase 4 placeholder
│       └── shell_scaffold.dart        # Bottom nav shell
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_remote_datasource.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   ├── domain/repositories/auth_repository.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart     # Full auth lifecycle BLoC
│   │       └── pages/
│   │           ├── login_page.dart     # Functional login UI
│   │           └── register_page.dart
│   ├── dashboard/presentation/pages/user_dashboard_page.dart
│   ├── exam_library/
│   │   ├── data/repositories/
│   │   │   ├── exam_repository.dart    # Full CRUD + file upload
│   │   │   └── attempt_repository.dart # Start/complete/stats
│   │   └── presentation/pages/
│   │       ├── exam_list_page.dart
│   │       └── exam_detail_page.dart
│   ├── quest/
│   │   ├── data/repositories/quest_repository.dart
│   │   └── presentation/pages/quest_page.dart
│   ├── store/
│   │   ├── data/
│   │   │   ├── models/skin_model.dart
│   │   │   └── repositories/store_repository.dart  # Skin upload
│   │   └── presentation/pages/avatar_store_page.dart
│   └── admin/presentation/pages/
│       ├── admin_dashboard_page.dart
│       ├── create_exam_page.dart       # Full form + file upload
│       ├── exam_management_page.dart
│       └── admin_upload_skin_page.dart # Pixel skin upload
│
└── shared/
    ├── models/
    │   ├── user_entity.dart           # UserRole enum
    │   ├── exam_model.dart            # DifficultyTier, ExamStatus enums
    │   ├── question_model.dart        # QuestionType enum
    │   ├── attempt_model.dart         # AttemptStatus enum
    │   └── quest_model.dart           # QuestType enum
    └── services/
        └── user_repository.dart       # XP, levels, streaks, profile
```

### Design System: Neo-Arcade Editorial
- **Typography:** Press Start 2P (hero), VT323 (body), Space Grotesk (admin)
- **Layout:** 0px border-radius everywhere, brutalist geometry
- **Colors:** Deep navy primary, arcade green accents, tinted shadows
- **Components:** Chunky buttons, 4px borders, retro bottom nav

### Branding
- **App Name:** RIMS (Root Institute of Mathematics — Mathematics Learning Centre)
- **Logo:** Custom RIMS logo (`logo/logo.png`)
- **App Icon:** Generated from logo via `flutter_launcher_icons` for Android, iOS, and Web
- **Dart Package Name:** `bitwise_academy` (retained for import stability)

### State Management
- **BLoC** (`flutter_bloc` + `equatable`) for all feature states
- Sealed events/states with Dart 3 pattern matching
- `Result<T>` type (Success/Failure) — no raw exceptions from repositories

### Error Handling
All repositories return `Result<T>` — BLoCs pattern-match:
```dart
final result = await examRepo.fetchPublishedExams();
switch (result) {
  case Success(:final data): emit(ExamListLoaded(exams: data));
  case Failure(:final exception): emit(ExamListError(message: exception.message));
}
```

---

## 🔥 Firebase Setup (What's Done)

### ✅ Completed
- [x] Firebase project `edtech-3f6fe` linked via FlutterFire CLI
- [x] `firebase_options.dart` generated (Android, iOS, Web)
- [x] `google-services.json` generated for Android
- [x] `GoogleService-Info.plist` generated for iOS
- [x] Firestore database created in **asia-south1** (Mumbai)
- [x] Firestore security rules deployed
- [x] Firebase Auth enabled (Email/Password + Google)
- [x] Android `build.gradle.kts` configured (minSdk 23, multiDex)
- [x] Android `AndroidManifest.xml` updated (INTERNET permission, app label)
- [x] iOS `Podfile` set to platform 13.0
- [x] iOS `Info.plist` updated (Google Sign-In URL scheme)
- [x] Firebase Storage rules configured for avatars, exam_assets, and skins

### ⏳ To Implement Later
- [ ] **Firebase Storage** — Enable in Firebase Console: https://console.firebase.google.com/project/edtech-3f6fe/storage → Click "Get Started" → Choose `asia-south1`
- [ ] **Deploy Storage Rules** — Run: `firebase --project=edtech-3f6fe deploy --only storage`
- [ ] **Android SHA-1 Fingerprint** — Required for Google Sign-In on Android:
  ```bash
  cd android && ./gradlew signingReport
  # Copy the SHA-1 from the debug variant
  # Add it in Firebase Console → Project Settings → Your Apps → Android → Add Fingerprint
  ```
- [ ] **iOS Reversed Client ID** — After enabling Google Sign-In on iOS:
  1. Download the updated `GoogleService-Info.plist` from Firebase Console
  2. Copy the `REVERSED_CLIENT_ID` value
  3. Replace the URL scheme in `ios/Runner/Info.plist`
- [ ] **Firebase App Check** — Enable for production security
- [ ] **Firestore Indexes** — Create composite indexes as needed:
  ```
  exams: [status ASC, createdAt DESC]
  attempts: [userId ASC, startedAt DESC]
  attempts: [examId ASC, startedAt DESC]
  ```
- [ ] **Apple Sign-In Configuration** — After enabling Apple Sign-In in Firebase Console:
  1. Create a **Service ID** and **Private Key** in the Apple Developer Portal.
  2. Configure the **Key ID** and **Team ID** in Firebase Console → Authentication → Sign-in method → Apple.
  3. Note: The current implementation handles nonces and tokens, but full production flow requires this backend handshake.

---

## 👑 Admin Whitelisting

Admin access is **automatically assigned** during registration if the user's email is present in the `admin_whitelist` collection in Firestore.

### How to Grant Admin Access

#### For Production
1. Go to [Firestore Console](https://console.firebase.google.com/project/edtech-3f6fe/firestore/databases/-default-/data)
2. Navigate to the `admin_whitelist` collection (create it if it doesn't exist).
3. Create a new document where the **Document ID** is the exact email address you want to whitelist (e.g., `admin@rims.edu`).
4. You do not need to add any fields to the document. The system only checks for the existence of the document ID.
5. When the user creates an account with that email, they will automatically be assigned the `admin` role.

#### For Local Development (Emulator)
Since the app uses the Local Emulator by default, you need to add your email to the emulator's database:
1. Open the Firebase Emulator UI in your browser: [http://localhost:4000/firestore](http://localhost:4000/firestore)
2. Click **Start collection**.
3. Collection ID: `admin_whitelist`
4. Document ID: `your_email@gmail.com` (e.g., `rimsedtech@gmail.com`)
5. Save the document.
6. Now, sign up in the app with that email, and you'll instantly get Admin privileges!

### Security Guarantees
- Firestore rules block any client-side role change to `admin` unless the email explicitly exists in the `admin_whitelist` collection.
- The `admin_whitelist` collection is locked down (`allow write: if false;`), meaning it can only be modified securely from the Firebase Console or via the Firebase Admin SDK.
- Admin routes in the app are guarded client-side AND server-side.

---

## 🎯 Completed Phases

### Phase 4: UI Development
- [x] Build shared Neo-Arcade widget library (chunky buttons, pixel cards, progress bars)
- [x] Implement full login/register screens matching design mockups
- [x] Build Hero Dashboard (avatar, XP bar, level, daily quest, stats)
- [x] Build Admin Dashboard (exam cards, system status, recent activity)
- [x] Build Exam Library (filterable exam cards, difficulty tiers)
- [x] Build Test Configuration screen (Easy/Medium/Hard selector, timer)
- [x] Build exam-taking interface (question display, answer selection, timer)
- [x] Build results/score screen with XP earned animation
- [x] Build Quest page (daily/weekly objectives, achievement badges)
- [x] Responsive layout testing (mobile + tablet)

### Phase 5: Testing & QA
- [x] Unit tests for all repositories (mock Firestore)
- [x] BLoC tests for auth, exam, quest flows
- [x] Widget tests for key components
- [ ] Golden tests for design system compliance (Deferred)
- [ ] Integration tests for critical paths (login → exam → score) (Deferred)
- [x] Error-path validation (network failures, permission denied)
- [ ] Performance profiling (build times, frame rates) (Deferred)

### Phase 6: Data Integration & Live Logic (Completed)
- [x] Implement `ExamBloc` to fetch live exams from Firestore
- [x] Connect User Dashboard to `AuthBloc` (live XP, level, streak)
- [x] Implement `AttemptBloc` to save exam attempts and calculate scores
- [x] Connect Admin Dashboard to live Firestore statistics
- [x] Wire up Quest system to live data

> **⚠️ Firebase Sandbox / Implementation Note:** 
> For the current development phase, the app is configured to connect to the **Firebase Local Emulator Suite** by default. 
> 
> **How to Run the Sandbox:**
> 1. Install Firebase CLI: `npm install -g firebase-tools`
> 2. Start emulators with **persistence**: `./scripts/start_emulators.sh` inside the `app` folder.
>    *   This ensures your `admin_whitelist`, exams, and users are saved across restarts.
>    *   Data is stored in `app/.firebase_emulator_data/`.
> 
> **Preparing for Production (What to Delete/Change):**
> 1. Open `lib/main.dart` and change `const bool useFirebaseEmulator = true;` (or the environment flag) to `false`.
> 2. Remove the emulator connection logic in `main.dart` inside the `if (useFirebaseEmulator)` block if you no longer need it.
> 3. Some logic (such as calculating XP rewards, creating user accounts, scoring exams, and **awarding coins/purchasing skins**) is currently handled **client-side** to work smoothly with the Local Emulator Suite. In a true production environment, **these must be moved to Firebase Cloud Functions** or protected by strict Firestore/Storage Security Rules to prevent client-side manipulation and exploits.
> 4. Admin whitelisting is handled manually in the database for now.

### Phase 7: Economy & Avatar System (Completed)
- [x] Implement virtual currency/coins awarded upon completing exams and quests
- [x] Build Avatar Store UI for users to purchase pixel character skins/cosmetics
- [x] Add Admin Dashboard module to upload new pixel character skins and set prices
- [x] Connect Store to Firestore (update user inventory and deduct coins)
- [x] Add reactive UI logic to immediately update the equipped avatar/skin on-screen when changed

### Phase 8: Rebranding, Upload Features & Documentation (Completed)
- [x] **Rebranded** from "Bitwise Academy" to **RIMS** (Root Institute of Mathematics) across all platforms
- [x] **App launcher icon** generated from RIMS logo for Android, iOS, and Web
- [x] **Exam file upload** — Create Exam page now fully wired with form validation, difficulty selector, optional file attachment, and Firestore integration
- [x] **Pixel skin upload** — Already functional from Phase 7
- [x] **Storage rules** — Added rules for `skins/` path alongside existing `exam_assets/` and `avatars/`
- [x] **README updated** with new branding, architecture docs, and completed phases

### Future Enhancements
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] Offline mode with Firestore persistence
- [ ] Leaderboard system
- [ ] Analytics dashboard (Firebase Analytics)
- [ ] In-app achievements and badges
- [ ] Dark mode support
- [ ] Accessibility (a11y) audit
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Production signing keys (Android + iOS)
- [ ] **Isar Local Database** — Implement `isar` for offline-first exam storage to reduce latency and Firestore read costs when handling large exam datasets.

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` + `equatable` | State management |
| `go_router` | Declarative routing with auth guards |
| `firebase_core/auth/cloud_firestore` | Firebase backend |
| `firebase_storage` | File uploads (exams, skins) |
| `google_sign_in` | Google authentication |
| `get_it` | Dependency injection |
| `google_fonts` | Press Start 2P, VT323, Space Grotesk |
| `image_picker` | File selection for uploads |
| `cached_network_image` | Network image caching |
| `logger` | Structured logging |
| `flutter_launcher_icons` | App icon generation (dev) |

---

## 🛠️ Commands

```bash
# Run the app
flutter run

# Analyze code
flutter analyze

# Generate app icons from logo
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

# Deploy Firestore rules
firebase --project=edtech-3f6fe deploy --only firestore:rules

# Deploy Storage rules (after enabling Storage)
firebase --project=edtech-3f6fe deploy --only storage

# Re-configure FlutterFire
flutterfire configure --project=edtech-3f6fe

# Build release APK
flutter build apk --release
```

---

**Built with 🎮 by the RIMS Team**
