# ApoBasi Flutter DevTools Optimization Guide

A step-by-step checklist for you and Claude to use together to find and fix
performance issues screen by screen.

---

## 1. Launch DevTools

```bash
# Run the app in PROFILE mode (not debug — debug is always slow)
flutter run --profile

# DevTools URL prints in the terminal, e.g.:
# http://127.0.0.1:9100/...
# Open it in Chrome
```

> **Profile mode** is essential. Debug mode adds overhead that makes everything
> look slow. Never benchmark in debug.

---

## 2. The Three Tools We Use

### A. Performance tab → Frame chart

Open **Performance** tab. Hit the record button, then do the action on the
device (open a screen, scroll, toggle dark mode). Stop recording.

**Read the chart:**
| Bar colour | Meaning |
|---|---|
| Green / short | Good frame (< 16ms) |
| Yellow | Borderline (16–32ms) |
| Red / tall | Jank — this is what we fix |

Click any red bar → it expands into a flame chart showing exactly which
function used the most time.

**What to screenshot and paste here:** The tall red bars + the flame chart
underneath showing the widest blocks.

---

### B. Performance tab → "Track widget rebuilds"

1. In DevTools Performance tab, enable **"Track widget rebuilds"**
2. Interact with the screen
3. Back in the app, the Flutter overlay shows rebuild counts as numbers in
   the top-left of each widget

**What to tell Claude:**
_"NotificationCard rebuilt 47 times during scroll"_
→ We add `const`, `ValueKey`, or `RepaintBoundary`

---

### C. Widget inspector → "Show repaint rainbow"

In **Widget Inspector** tab, enable **"Highlight repaints"** (the rainbow icon).

Widgets that repaint flash with a rainbow border. The more they flash, the
more expensive they are.

**What to tell Claude:**
_"The entire dashboard flashes on theme toggle"_
→ We wrap it in `RepaintBoundary`

---

## 3. Screen-by-Screen Checklist

Work through these in order — fix the worst offender first.

---

### Screen 1: parent_dashboard.dart  ⚠️ HIGHEST RISK
**Why:** Has real-time WebSocket updates, IndexedStack tabs, child status
cards, and activity feed — the busiest screen.

**Steps:**
1. Profile mode → navigate to dashboard → record 10 seconds of normal use
2. Check: does the bottom nav switching cause red frames?
3. Toggle dark mode while on dashboard — does it jank?
4. Scroll the activity feed — any dropped frames?

**Known patterns to check:**
- `Theme.of(context)` called more than 3× in `build()` → cache it
- `IndexedStack` children rebuilding when tab switches → add `RepaintBoundary`
  around each tab's root widget
- `ChildStatusCard` list → each item needs `RepaintBoundary` + `ValueKey`

---

### Screen 2: child_detail_screen.dart  ⚠️ HIGH RISK
**Why:** Has a live map (flutter_map + Mapbox tiles), real-time bus location
marker, and WebSocket stream.

**Steps:**
1. Open a child's detail page → record
2. Does the map tile loading cause jank?
3. When bus location updates, does the whole screen rebuild or just the marker?

**Known patterns to check:**
- The `StreamBuilder` for bus location should only rebuild the marker widget,
  not the whole map
- Map tiles are loaded asynchronously — check for `setState()` calls that
  trigger full rebuilds

---

### Screen 3: notifications_center.dart  ⚠️ MEDIUM RISK
**Why:** Can have many notification cards. Checked for known rebuild issues.

**Steps:**
1. Open notifications with 20+ items → scroll fast → record
2. Check if filter sheet causes jank when opening/closing

**Known patterns to check:**
- Each `NotificationCardWidget` needs `RepaintBoundary` + `ValueKey(notification.id)`
- Filter sheet animation — check if it rebuilds the whole list

---

### Screen 4: parent_profile_settings.dart  ⚠️ MEDIUM RISK
**Why:** Has dialogs that call `Theme.of(context)` many times.

**Steps:**
1. Open any dialog (edit name, change password) → record
2. Toggle dark mode while a dialog is open → does it crash or flash?

---

### Screen 5: parent_login_screen_v2.dart  LOW RISK
**Steps:**
1. Type in the email field → record
2. Check if each keystroke causes heavy rebuilds of the whole screen

---

### Screen 6: splash_screen.dart  LOW RISK
Already optimised (SVG logo, simple animation).

---

## 4. Dark Mode Toggle — Specific Test

```
Steps:
1. Profile mode, open Performance tab, start recording
2. Go to Profile screen
3. Toggle dark mode
4. Stop recording
5. Find the frame that corresponds to the toggle
```

**What good looks like:** 1–2 slightly tall frames (< 100ms), then smooth.
**What we have now:** Likely 1 large red spike during the transition.

**The fix pattern:**
```dart
// Wrap any expensive subtree that doesn't need to re-theme with:
RepaintBoundary(
  child: YourExpensiveWidget(),
)

// For widgets that DO need to re-theme, cache the theme:
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context); // ONE lookup, reuse everywhere
  final colors = theme.colorScheme;
  ...
}
```

---

## 5. What to Share With Claude After Each Session

For each screen profiled, tell me:

1. **Screen name**
2. **Action that caused jank** (scroll, tap, theme toggle, open)
3. **Worst frame time** (ms shown in DevTools)
4. **Top 3 widest blocks in the flame chart** (function names)
5. **Widget rebuild counts** for any widget > 10 rebuilds

Example report:
```
Screen: ParentDashboard
Action: Dark mode toggle
Worst frame: 312ms
Flame chart top: _ParentDashboardState.build (280ms),
                 Theme.of (45ms), ChildStatusCard.build (30ms)
Rebuild counts: ChildStatusCard ×28, ActivityFeed ×12
```

I'll then give you the exact lines to change.

---

## 6. Quick Wins to Do Right Now (Before DevTools)

These are safe to apply without profiling:

```dart
// 1. Add RepaintBoundary around each tab in IndexedStack
RepaintBoundary(child: HomeTab())
RepaintBoundary(child: NotificationsTab())
RepaintBoundary(child: ProfileTab())

// 2. Add RepaintBoundary around the map widget
RepaintBoundary(child: FlutterMap(...))

// 3. Cache theme in every build() that calls Theme.of > once
final theme = Theme.of(context);

// 4. Add const to all leaf widgets that never change
const Text('Home Location')
const Icon(Icons.location_on)
```

---

## 7. The "Lost Connection" / ANR Fix

The `Skipped 351 frames (5898ms)` you saw is an ANR (App Not Responding).
Most likely causes:
1. **Location permission crash** — fixed by adding permissions to manifest ✓
2. **Heavy work on main thread at startup** — check if any service is doing
   synchronous I/O in `initState()`
3. **WebSocket connection attempt blocking** — already deferred 500ms in main.dart ✓

If it happens again, run:
```bash
flutter run --profile 2>&1 | grep -E "Skipped|ERROR|Exception"
```
and paste the output here.
