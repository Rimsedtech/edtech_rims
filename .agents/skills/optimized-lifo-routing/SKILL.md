---
name: optimized-lifo-routing
description: Implements standard chronological navigation with a double-tap-to-exit temporal safeguard explicitly isolated at the root destination.
---

# Optimized LIFO Navigation & Exit Safeguard

## Architectural Constraints

- The chronological back stack MUST be preserved. Do not override default back actions on deeply nested screens.
- The focus of this programmatic intervention is strictly on the **Start Destination** (Home Screen / `UserDashboardPage`).
- A **"Double-Tap to Exit"** mechanism must be implemented to prevent accidental app closures.

## Implementation Steps

1. Identify the root Home component (`UserDashboardPage` rendered at `RoutePaths.dashboard = '/'`).
2. Implement a back press interceptor that tracks the timestamp of the press.
3. If the back button is pressed on the Home screen:
   - Trigger a transient visual element (Snackbar) stating "Press back again to exit".
   - Start a 2000ms timer.
4. If a second back press occurs within 2000ms, exit the application gracefully.
5. Predictive back gestures on modern Android must NOT be permanently blocked — use `PopScope.canPop: false` with `onPopInvokedWithResult` only on the start destination, never on child routes.
6. Ensure complete async safety: cancel timers on widget dispose to prevent setState-after-dispose crashes.
