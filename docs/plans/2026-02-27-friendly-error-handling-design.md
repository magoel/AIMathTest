# Design: Friendly Test Generation Error Handling

> Date: 2026-02-27
> Status: Approved

## Problem

When test generation fails, users see raw exception text in a SnackBar (e.g., "Failed to generate test: [firebase_functions/deadline-exceeded] ..."). This is cryptic and unhelpful for kids and parents. Users also have no way to report the issue when it happens.

## Solution

### Error Mapping

Add a helper function that maps raw exceptions to friendly messages with appropriate icons:

| Error Pattern | Friendly Message | Icon |
|--------------|-----------------|------|
| `SocketException`, `network`, `ClientException` | "No internet connection. Please check your WiFi and try again." | `wifi_off` |
| `resource-exhausted`, `429` | "Our math engine is busy right now. Please try again in a minute." | `hourglass_top` |
| `deadline-exceeded`, `timeout` | "This is taking too long. Please try again with fewer questions." | `timer_off` |
| `unauthenticated`, `permission-denied` | "Your session has expired. Please sign out and sign back in." | `lock_outline` |
| `failed-precondition` | "Something went wrong on our end. Please try again shortly." | `error_outline` |
| Everything else | "Something went wrong. Please try again." | `error_outline` |

### Error Dialog (replaces SnackBar)

Show an AlertDialog instead of a SnackBar — more visible and appropriate for this audience.

```
+-------------------------------------+
|  Warning icon  Oops!                |
|-------------------------------------|
|                                     |
|  [icon]                             |
|  Our math engine is busy right now. |
|  Please try again in a minute.      |
|                                     |
|  [Report Issue]            [OK]     |
+-------------------------------------+
```

- "OK" (primary) — dismisses dialog
- "Report Issue" (text button) — opens feedback dialog pre-filled with error context

### Feedback Pre-fill

Open existing `_FeedbackDialog` with `initialMessage` param set to `"[Error during test generation] <error type>"`. User can edit and add notes. Screen auto-set to `"test_config"`.

### Files

- `lib/screens/test_config/test_config_screen.dart` — replace SnackBar catch block with error mapping + AlertDialog
- `lib/widgets/feedback_button.dart` — add optional `initialMessage` parameter to `_FeedbackDialog`

No new files or models. Reuses existing feedback infrastructure.
