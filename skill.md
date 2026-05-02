# skill.md — Bitwise Academy: Neo-Arcade Ed-Tech Platform
# Authors: Agent Alpha (System Architect) · Agent Epsilon (QA Specialist)
# Last Updated: 2026-04-21

---

## 1. Dart Language Constraints

### 1.1 Strict Typing & Sound Null Safety
- Sound null safety is MANDATORY. No `// @dart=2.x` opt-outs.
- Explicit types everywhere. Prefer `final` over `var`.
- Type annotations on all public APIs (return types + parameter types).
- No implicit casts. Enforce in `analysis_options.yaml`:
  ```yaml
  analyzer:
    language:
      strict-casts: true
      strict-inference: true
      strict-raw-types: true
  ```
- Typedef all complex function types.

### 1.2 Immutability First
- All model/entity classes must use `@immutable` or `freezed`.
- Never expose raw mutable collections in public APIs.

### 1.3 Naming Conventions
| Element               | Convention             | Example                    |
| --------------------- | ---------------------- | -------------------------- |
| Files                 | `snake_case`           | `exam_repository.dart`     |
| Classes               | `PascalCase`           | `ExamRepository`           |
| Variables / functions | `camelCase`            | `fetchExams()`             |
| Constants             | `camelCase`            | `kDefaultPadding`          |
| Enums                 | `PascalCase.camelCase` | `DifficultyTier.ultraHard` |
| Private members       | `_camelCase`           | `_examCache`               |
| Feature folders       | `snake_case`           | `exam_library/`            |

---

## 2. State Management Guidelines

### 2.1 Architecture: BLoC + Cubit (via `flutter_bloc`)
- **BLoC** for complex event-driven logic (auth, exam sessions, scoring).
- **Cubit** for simpler stateful widgets (toggles, filters, forms).
- No other state management (Provider, GetX, Riverpod) without approval.

### 2.2 State Class Rules
- All states must be `sealed` (Dart 3+) or use `freezed` unions.
- Never store UI-specific data (scroll positions, animations) in BLoC state.

### 2.3 Event Class Rules
- Events must be `sealed` with `const` constructors.
- Never pass BuildContext or widget references to a BLoC.

### 2.4 Dependency Injection
- Use `get_it` + `injectable` for service location.
- BLoCs receive repositories via constructor injection.
- Register all deps in `lib/core/di/injection.dart`.

---

## 3. Firebase & Cloud Infrastructure

### 3.1 Authentication
- Firebase Auth only. Methods: Email/Password, Google Sign-In.
- On sign-up, create `users/{uid}` doc with role defaulting to `student`.
- Admin role assigned ONLY via Admin Dashboard by existing admin.

### 3.2 Firestore Schema

```
users/{uid}
  displayName, email, role("student"|"admin"), xp, level,
  streakDays, avatarUrl, createdAt, lastLoginAt

exams/{examId}
  title, description, subject, difficultyTier("easy"|"medium"|"hard"|"ultra_hard"),
  durationMinutes, createdBy, status("draft"|"published"|"archived"),
  xpReward, questionCount, createdAt, updatedAt
  └── questions/{questionId}
      questionText, questionType("mcq"|"true_false"|"short_answer"),
      options[], correctAnswer, explanation, points, order

attempts/{attemptId}
  userId, examId, startedAt, completedAt, score, totalPoints,
  xpEarned, status("in_progress"|"completed"|"abandoned"), answers{}

quests/{questId}
  title, description, type("daily"|"weekly"|"achievement"),
  targetValue, xpReward, iconName, isActive

system/config
  maintenanceMode, appVersion, featureFlags{}
```

### 3.3 Security Rules Summary
- Users: read if signed in; create own profile (role=student only); update own non-role fields; admin can change roles.
- Exams: read published if signed in (admin reads all); write only admin.
- Attempts: read own or admin; create own; update own if in_progress; never delete.
- Quests/System: read if signed in; write only admin.

### 3.4 Storage Rules
- `/avatars/{uid}/` — user uploads own, <5MB images only.
- `/exam_assets/{examId}/` — admin uploads only, <50MB.

---

## 4. UI/UX Constraints: Neo-Arcade Editorial Design

### 4.1 Core Philosophy
- Zero rounded corners (`BorderRadius.zero` everywhere).
- Pixel-perfect brutalist geometry.
- Premium 8-bit nostalgia — not toy-like.
- Dramatic editorial typographic contrast.

### 4.2 Color Palette
```dart
class AppColors {
  static const primary            = Color(0xFF242E48);
  static const primaryContainer   = Color(0xFF3A4460);
  static const onPrimary          = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFA7B1D3);
  static const secondary            = Color(0xFF3E6A00);
  static const secondaryContainer   = Color(0xFFB2F26A);
  static const secondaryFixed       = Color(0xFFB5F56C);
  static const onSecondary          = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF416E00);
  static const tertiary            = Color(0xFF64000F);
  static const tertiaryContainer   = Color(0xFF8B0C1C);
  static const onTertiaryContainer = Color(0xFFFF9491);
  static const surface                 = Color(0xFFFBF8FB);
  static const surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const surfaceContainerLow     = Color(0xFFF6F3F5);
  static const surfaceContainer        = Color(0xFFF0EDF0);
  static const surfaceContainerHigh    = Color(0xFFEAE7EA);
  static const surfaceContainerHighest = Color(0xFFE4E2E4);
  static const surfaceDim             = Color(0xFFDCD9DC);
  static const onSurface        = Color(0xFF1B1B1D);
  static const onSurfaceVariant  = Color(0xFF45464D);
  static const outline           = Color(0xFF76777E);
  static const outlineVariant    = Color(0xFFC6C6CE);
  static const error           = Color(0xFFBA1A1A);
  static const errorContainer  = Color(0xFFFFDAD6);
  static const onError         = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF93000A);
}
```

### 4.3 Typography
| Token        | Font             | Size     | Usage                        |
| ------------ | ---------------- | -------- | ---------------------------- |
| displayLg    | Press Start 2P   | 3.5rem   | Hero banners, splash         |
| headlineMd   | Press Start 2P   | 1.75rem  | Section headers              |
| headlineSm   | Press Start 2P   | 0.75rem  | Card titles                  |
| bodyLg       | VT323            | 1.125rem | Body text                    |
| bodyMd       | VT323            | 1rem     | Standard content             |
| labelLg      | VT323            | 1rem     | Button labels                |
| labelMd      | VT323            | 0.875rem | Metadata                     |
| labelSm      | Space Grotesk    | 0.75rem  | Data tables, admin text      |

### 4.4 Spacing (4px base unit)
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### 4.5 Component Standards
- **Buttons:** 4px bottom shadow, active reduces to 1px + translateY(3px).
- **Cards:** Inner shadow with surfaceDim. No divider lines.
- **Progress Bars:** Segmented HP-pip style with gradient fills.
- **Inputs:** 2px solid primary border, 0px radius. Focus = secondary + glow.
- **Bottom Nav:** primaryContainer background, VT323 labels.

### 4.6 Forbidden Patterns
- ❌ `BorderRadius.circular(>0)` — breaks aesthetic
- ❌ `Colors.*` from Material — use `AppColors.*` only
- ❌ Default Material widgets without full custom override
- ❌ Hardcoded width/height on layout containers
- ❌ 1px solid borders for section dividers
- ❌ Generic icons without pixel treatment

---

## 5. Error Handling Protocols

### 5.1 Exception Hierarchy
```dart
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;
  const AppException({required this.message, this.code, this.stackTrace});
}
// Subtypes: NetworkException, AuthException, FirestoreException,
//           ValidationException, StorageException
```

### 5.2 Result Type Pattern
```dart
sealed class Result<T> { const Result(); }
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}
final class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}
```
- NEVER throw raw exceptions from repositories.
- BLoCs handle Failure by emitting error states.

### 5.3 Firebase Error Mapping
- Wrap all Firebase calls in try/catch.
- Map `FirebaseException` → `AppException` subtypes.
- Log before transforming.

### 5.4 Logging
- Use `logger` package. Debug in dev, warning+ in prod.
- Never log passwords, tokens, or full emails.

### 5.5 UI Error Display
- Network → retryable "CONNECTION LOST" pixel banner.
- Auth → inline field validation in VT323.
- Unknown → "SYSTEM MALFUNCTION" overlay with error code.

---

## 6. Project Architecture (Feature-First)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/ (app_colors, app_spacing, app_typography)
│   ├── di/ (injection.dart)
│   ├── errors/ (app_exception, result)
│   ├── router/ (app_router.dart)
│   ├── theme/ (app_theme.dart)
│   ├── utils/ (logger, validators)
│   └── widgets/ (pixel_button, pixel_card, pixel_input, etc.)
├── features/
│   ├── auth/ (data/, domain/, presentation/)
│   ├── dashboard/ (data/, domain/, presentation/)
│   ├── exam_library/ (data/, domain/, presentation/)
│   ├── quest/ (data/, domain/, presentation/)
│   └── admin/ (data/, domain/, presentation/)
└── shared/
    ├── models/ (exam, question, attempt, quest)
    └── services/ (firestore_service)
```

---

## 7. Testing Requirements

| Layer             | Min Coverage |
| ----------------- | ------------ |
| BLoC / Cubit      | 90%          |
| Repositories      | 85%          |
| Models / Entities | 100%         |
| Widgets           | 70%          |

Stack: `flutter_test`, `bloc_test`, `mocktail`, `golden_toolkit`.

---

## 8. Approved Packages

| Package                | Purpose                  |
| ---------------------- | ------------------------ |
| flutter_bloc           | State management         |
| equatable              | Value equality           |
| get_it                 | DI / Service locator     |
| injectable             | Annotation-driven DI     |
| go_router              | Declarative routing      |
| firebase_core          | Firebase init            |
| firebase_auth          | Authentication           |
| cloud_firestore        | Database                 |
| firebase_storage       | File uploads             |
| google_sign_in         | Google auth              |
| google_fonts           | Typography               |
| logger                 | Logging                  |
| cached_network_image   | Image caching            |
| json_annotation        | JSON annotations         |
| json_serializable      | JSON codegen             |
| build_runner           | Code generation          |
| mocktail               | Testing mocks            |
| bloc_test              | BLoC testing             |
| golden_toolkit         | Snapshot testing          |

---

---

## 9. Infrastructure & Build Maintenance

### 9.1 Gradle Plugin Version Constraints
- **google-services:** Stick to `4.4.1` to avoid classpath conflicts with existing dependencies.
- **firebase-crashlytics:** Stick to `2.9.9` to maintain compatibility with the current build setup.
- **AGP (com.android.application):** Configured at `8.9.1`.
- **Reason for Downgrade:** These versions are pinned to resolve "already on the classpath with a different version" errors caused by transitive dependency locks.
- **Upgrade Path:** Upgrades can be attempted after significant Flutter SDK updates or when bumping the Android Gradle Plugin version. Always run `flutter clean` before testing new plugin versions.
