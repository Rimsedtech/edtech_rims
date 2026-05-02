---
name: flutter-navigation-rules
description: Mandatory architectural rules for custom Flutter navigation and back-button interception.
---

# Flutter Navigation Rules

These architectural constraints are mandatory for all UI and routing development within the application. You must strictly adhere to these rules when implementing new screens, handling hardware back presses, or modifying the navigation shell.

## 1. No PopScope
**Never use `PopScope` or `WillPopScope` for back navigation interception.** 
Native Flutter pop scopes fail silently and swallow events when paired with `go_router`'s `StatefulShellRoute` on Android. Do not attempt to use them to intercept hardware back presses.

## 2. Interceptor Package
**Always rely on the `back_button_interceptor` package.**
Hardware back presses must be caught imperatively bypassing the router's element tree. Register the listener using `BackButtonInterceptor.add()` in `initState` and deregister it using `BackButtonInterceptor.remove()` in `dispose`.

## 3. Tab History
**Maintain chronological reverse navigation.**
All new bottom navigation tabs must integrate with the custom `_tabHistory` list managed inside the `ShellScaffold`. When a user navigates between tabs, the new route must be pushed to this list so that back presses can accurately rewind the history.

## 4. Deep Link Check
**Prioritize internal routing.**
Inside your custom interceptor, you must always check `GoRouter.of(context).canPop()` first. If `true`, you must execute `context.pop()` and return `true` to indicate the event was handled. This ensures nested routes pop cleanly without triggering the shell's exit logic.

## 5. Android Manifest Override
**Preserve imperative interception.**
The `android:enableOnBackInvokedCallback="false"` attribute must remain explicitly set in `android/app/src/main/AndroidManifest.xml`. If predictive back gestures are accidentally re-enabled (Android 13+), the OS will bypass our Dart-level interceptors completely, causing the app to freeze or exit unexpectedly.

## 6. Root Exit Safeguard
**Isolate the double-tap-to-exit logic.**
The 2000ms "Press back again to exit" safeguard must only trigger when the user is at the absolute root of the history stack (`_tabHistory.length == 1`). If the tab history has more than one entry, the back press should always pop the history, never initialize the exit timer.
