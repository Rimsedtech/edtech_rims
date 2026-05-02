import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:bitwise_academy/app.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/firebase_options.dart';

/// Set to true to use the Firebase Local Emulator Suite (Sandbox).
/// Disabled manually as we now use the real Firebase on the Blaze plan.
const bool useFirebaseEmulator = false;

/// Application entry point.
///
/// Initialization sequence:
/// 1. Ensure Flutter bindings
/// 2. Initialize Firebase
/// 3. Connect to Emulators (if sandbox enabled)
/// 4. Configure DI container
/// 5. Run the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics
  // Enable collection in both debug and release for testing purposes.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  AppLogger.instance.i(
    'Firebase and Crashlytics initialized for project: edtech-3f6fe',
  );

  // Setup Firebase Sandbox / Emulators
  // IMPORTANT: Emulator connections MUST be established BEFORE any other
  // Firestore operations (including setting Settings), otherwise the SDK
  // may initialize against production and cache writes locally.
  if (useFirebaseEmulator) {
    try {
      final String host = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : '127.0.0.1';

      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);

      AppLogger.instance.w(
        '⚠️ RUNNING IN FIREBASE SANDBOX MODE (EMULATORS ENABLED) ⚠️',
      );
    } catch (e) {
      AppLogger.instance.e('Failed to connect to Firebase emulators: $e');
    }
  }

  // Configure Firestore settings AFTER emulator setup.
  // Disable persistence in emulator mode so writes go directly to the
  // emulator and failures are surfaced immediately instead of being cached.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: !useFirebaseEmulator,
    cacheSizeBytes: useFirebaseEmulator ? null : Settings.CACHE_SIZE_UNLIMITED,
  );

  // Configure dependency injection
  await configureDependencies();
  AppLogger.instance.i('Dependency injection configured');

  runApp(const RimsApp());
}
