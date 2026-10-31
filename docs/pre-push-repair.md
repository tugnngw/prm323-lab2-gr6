# Pre-Push Repair Report — Test Suite & Analyzer Restoration

**Date:** 2026-10-31  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Status:** READY TO COMMIT  
**Prior Audit Verdict:** BLOCKED (27 errors / 44 analyzer issues; 5/6 test suites failing)  
**Current Verification Verdict:** PASS (0 analyzer issues; 25/25 automated tests passing; debug APK build clean)  

---

## 1. Executive Summary

This repair pass resolved all compilation errors, missing member exceptions, stale imports, and contract mismatches across the test suite and test doubles that were blocking pre-push verification after commits `27b39a5`, `2116eaa`, `d1ca8c1`, and `89405be`.

All modifications were strictly constrained to `test/`, `pubspec.lock`, and documentation. Zero production code in `lib/` was modified, ensuring no unintended regressions in runtime behavior or business logic.

---

## 2. Root Cause Analysis & Problem Breakdown

| Issue ID | Area | Root Cause | Impact |
|---|---|---|---|
| **RC-01** | Test Imports | Commit `27b39a5` moved mock services from `lib/services/` to `test/helpers/`, but did not update import statements in `test/helpers/mock_*.dart`, `test/viewmodels/tasks_notes_test.dart`, and `test/widget_test.dart`. | `uri_does_not_exist`, `implements_non_class`, 17+ `override_on_non_overriding_member` warnings. |
| **RC-02** | Test Doubles (`FirestoreService`) | Commits `2116eaa` and `d1ca8c1` added 6 methods to `FirestoreService` (`getUserProfile`, `saveReportMetadata`, `getNotifications`, `saveNotification`, `markNotificationRead`, `registerToken`). Neither `FakeFirestoreService` nor `MockFirestoreService` implemented them. | `non_abstract_class_inherits_abstract_member` errors on both doubles. |
| **RC-03** | Test Doubles (`AnalyticsService`) | `MockAnalyticsService` declared `implements AnalyticsService`. Dart analyzer requires all members (including concrete base class methods) to be implemented when using `implements`. | `non_abstract_class_inherits_abstract_member` for the 11 concrete event helpers. |
| **RC-04** | Advisor Contract | Commit `89405be` deliberately removed `predictedCumulativeGpa` from `AdvisorViewModel` (the sandbox directly compares simulated term GPA against the honors threshold; real cumulative GPA requires a transcript). `advisor_viewmodel_test.dart` still asserted on the removed getter and old advice copy. | `undefined_getter` errors on `predictedCumulativeGpa`; test failure on advice text. |
| **RC-05** | ViewModels Fail-Loud Contract | Commit `2116eaa` removed hardcoded mock data fallbacks from `RoadmapViewModel`, `TasksViewModel`, and `NotesViewModel` in compliance with Lab 3 §1.4 ("fail loud, no mockdata fallbacks"). `roadmap_viewmodel_test.dart` and `tasks_notes_test.dart` instantiated ViewModels with null services in `setUp()`, receiving empty collections. | 5 unit tests failed on empty state expectations. |
| **RC-06** | Dependency Lockfile | Dependencies added to `pubspec.yaml` in commit `27b39a5` (pdf, printing, file_picker, firebase_messaging, etc.) were not fully reflected in `pubspec.lock`. | `pubspec.lock` stale diff (+241 lines pending). |

---

## 3. Implementation Details & Fixes Applied

### 3.1 Repair Test Imports & References (RC-01)
- `test/helpers/mock_auth_service.dart`: Replaced relative import `'auth_service.dart'` with `'package:prm323_lab3/services/auth_service.dart'`.
- `test/helpers/mock_firestore_service.dart`: Replaced relative import `'firestore_service.dart'` with `'package:prm323_lab3/services/firestore_service.dart'`.
- `test/helpers/mock_analytics_service.dart`: Replaced relative import `'analytics_service.dart'` with `'package:prm323_lab3/services/analytics_service.dart'`.
- `test/viewmodels/tasks_notes_test.dart`: Updated import from `'package:prm323_lab3/services/mock_auth_service.dart'` to `'../helpers/mock_auth_service.dart'` and added `'../helpers/mock_firestore_service.dart'`.
- `test/widget_test.dart`: Updated imports from `'package:prm323_lab3/services/mock_*.dart'` to `'helpers/mock_*.dart'`.

### 3.2 Repair `FakeFirestoreService` (RC-02)
Implemented all 6 missing `FirestoreService` contract methods with call-recording and failure injection:
- `getUserProfile(userId)`: returns `null`.
- `saveReportMetadata(userId, metadata)`: records `'$userId:${metadata['fileName']}'`, respects `shouldFailSaveReportMetadata`.
- `getNotifications(userId)`: returns `const []`.
- `saveNotification(userId, data)`: records `userId`, respects `shouldFailSaveNotification`.
- `markNotificationRead(userId, notificationId)`: records `'$userId:$notificationId'`.
- `registerToken(userId, token)`: records `'$userId:$token'`.

### 3.3 Repair `MockAnalyticsService` (RC-03)
- Changed class declaration from `implements AnalyticsService` to `extends AnalyticsService`.
- Added `@override List<NavigatorObserver> get navigatorObservers => const [];`.
- The 11 concrete Lab 3 event helpers (`logLoginSuccess`, `logCourseView`, `logPrerequisiteCheck`, `logSearchCourse`, `logTaskCreate`, `logTaskComplete`, `logNoteCreate`, `logAdvisorQuery`, `logSyncTriggered`, `logExportReport`, `logNotificationReceived`) now cleanly inherit and funnel into the overridden `logEvent`.

### 3.4 Repair `MockFirestoreService` (RC-02, RC-05)
- Implemented the 6 missing interface methods matching `FirestoreService`.
- Populated `getUserProfile` to return Student P02's transcript (`'passedCourses': ['PRO192', 'CSD201', 'MAD101', 'OSG202', 'NWC203c', 'SSG104']`).
- Provided default course, task (`task_01`, PRM323), and note (`note_01`, PRM323) fixtures for hermetic test consumption.

### 3.5 Align `AdvisorViewModel` Tests with Production Contract (RC-04)
- Rewrote `Calculates semester and cumulative GPA accurately` to `Calculates simulated semester GPA accurately`, validating term GPA = 8.136.
- Rewrote `Evaluates Honors target (>= 8.0) when scores improve` to test both branches of `reachesHonorsTarget` using simulated term GPA:
  - Below threshold: PRM 8.0, SWP 7.5, SWR 7.5 -> Term GPA = 7.636 (< 8.0) -> `reachesHonorsTarget == false`.
  - At/above threshold: PRM 9.0, SWP 8.5, SWR 8.5 -> Term GPA = 8.636 (>= 8.0) -> `reachesHonorsTarget == true`.
- Updated advice assertion for SWP391 query to expect `'tín chỉ'` (matching rule-based response in `_replyFor`).

### 3.6 Wire Test Doubles in ViewModel Unit Tests (RC-05)
- `test/viewmodels/roadmap_viewmodel_test.dart`: Injected `MockAuthService` and `MockFirestoreService` into `RoadmapViewModel` in `setUp()`. All prerequisite evaluations (eligible PRM323, missing SWE201c for SWP391) now execute deterministically.
- `test/viewmodels/tasks_notes_test.dart`: Injected `MockAuthService` and `MockFirestoreService` into `TasksViewModel` and `NotesViewModel` in `setUp()`. Initial load assertions pass without requiring fake mock fallbacks in production ViewModels.

### 3.7 Refresh Dependency Lockfile (RC-06)
- Executed `flutter pub get`.
- Refreshed `pubspec.lock` (+241 lines, resolved 30 added transitive packages). `pubspec.yaml` remained completely untouched.

---

## 4. Verification Evidence & Exit Codes

All verification commands executed cleanly on Windows fixed NTFS (`G:\FPT\Semester8\PRM\Lab3\prm323-lab2-gr6`):

| Command | Target / Scope | Exit Code | Duration | Outcome |
|---|---|---|---|---|
| `flutter pub get` | Dependency resolution & lock refresh | **0** | ~4.2s | Clean lockfile sync; constraints satisfied. |
| `flutter analyze` | Static analysis across `lib/` and `test/` | **0** | 8.3s | **0 issues found** (down from 27 errors / 44 issues). |
| `flutter test` | Full unit and widget test suite | **0** | 4.8s | **25 of 25 tests passed** across all 4 suites. |
| `flutter build apk --debug` | Android Gradle build assembleDebug | **0** | 31.0s | Built `build\app\outputs\flutter-apk\app-debug.apk` (179 MB). |

### Detailed Test Execution Breakdown

```
00:00 +0: AdvisorViewModel & GPA Strategy Simulator Tests: Initializes with default Semester 5 assumptions
00:00 +1: AdvisorViewModel & GPA Strategy Simulator Tests: Calculates simulated semester GPA accurately
00:00 +2: AdvisorViewModel & GPA Strategy Simulator Tests: Evaluates Honors target (>= 8.0) from simulated term GPA
00:00 +3: AdvisorViewModel & GPA Strategy Simulator Tests: Generates specialized advice for SWP391 keyword queries
00:00 +4: RoadmapViewModel Tests: Loads default semester 5 courses on initialization
00:00 +5: RoadmapViewModel Tests: Correctly evaluates prerequisite eligibility for Student P02
00:00 +6: RoadmapViewModel Tests: Calculates course slot progress correctly
00:00 +7: TasksViewModel Tests: Initializes default study tasks
00:00 +8: TasksViewModel Tests: Toggles task completion state
00:00 +9: TasksViewModel Tests: Adds a new task and applies course filter
00:00 +10: TasksViewModel Tests: Passes authenticated UID to user-owned task operations
00:00 +11: TasksViewModel Tests: Unauthenticated task write is rejected safely without persisting
00:00 +12: TasksViewModel Tests: Successful task deletion removes item from list and calls remote service
00:00 +13: TasksViewModel Tests: Failed task deletion restores item and surfaces error
00:00 +14: NotesViewModel Tests: Initializes with default study notes
00:01 +15: NotesViewModel Tests: Saves new note to Vault and searches by keyword
00:01 +16: NotesViewModel Tests: Passes authenticated UID to user-owned note operations
00:01 +17: NotesViewModel Tests: Unauthenticated note write is rejected safely without persisting
00:01 +18: NotesViewModel Tests: Successful note deletion removes item from list and calls remote service
00:01 +19: NotesViewModel Tests: Failed note deletion restores item and surfaces error
00:01 +20: NotesViewModel Tests: Failed note save restores previous state and returns false
00:01 +21: widget_test: Authenticated user sees AppShell with bottom navigation
00:03 +22: widget_test: Unauthenticated user sees SignInScreen with Google sign-in button
00:03 +23: widget_test: Successful note save shows success snackbar
00:03 +24: widget_test: Failed note save does not show success and displays error snackbar
00:04 +25: All tests passed!
```

---

## 5. Regression Review

- **UID Propagation:** Fully verified. `TasksViewModel` and `NotesViewModel` correctly scope all Firestore operations (`addTask`, `toggleTask`, `deleteTask`, `saveNote`, `deleteNote`) by the authenticated user ID (`user_sec_01`, `user_sec_02`).
- **Unauthenticated Write Rejection:** Fully verified. Operations initiated while unauthenticated return `false`, set descriptive Vietnamese error messages in `lastError`, and perform zero remote persistence.
- **Optimistic State & Rollback:** Fully verified. Remote failure on task deletion, note deletion, or note creation immediately restores local ViewModel state and surfaces user-friendly error banners.
- **Fail-Loud Architecture (Lab 3 §1.4):** Preserved intact. Production ViewModels never fall back to fake mock data when disconnected or unauthenticated; `FirebaseConfigErrorApp` handles fatal initialization errors.
- **Advisor GPA Semantics:** Aligned with approved design. Direct term GPA comparison is maintained.
- **Storage & Cloud Messaging Security:** Gated by authenticated UID, file size limits (<10 MB), and MIME type allowlisting.

---

## 6. Remaining Observations & Product Notes

1. **Finding F6 (UI Copy Mismatch):** In `lib/screens/advisor_screen.dart:101`, static text displays `"Mốc Sinh viên Giỏi: GPA tích lũy ≥ 8.0"` (cumulative wording), whereas `AdvisorViewModel` computes the 11-credit semester term GPA (`"GPA kỳ 5"` in `strategy_sim_screen.dart`). Per task instructions, production UI copy was left untouched and is flagged here for product alignment.
2. **KGP Deprecation Notice:** Flutter build tools emit a warning regarding Kotlin Gradle Plugin usage in Firebase dependencies (`firebase_core`, `firebase_auth`, etc.). This is an upstream ecosystem migration notice for future Flutter versions and does not impact current build integrity or runtime stability.

---

## 7. Modified Files Inventory

| File Path | Nature of Change |
|---|---|
| `pubspec.lock` | Updated dependency tree (+241 lines) via `flutter pub get` |
| `test/helpers/fake_firestore_service.dart` | Added 6 missing interface methods, call recording, and failure flags |
| `test/helpers/mock_analytics_service.dart` | Fixed import, switched to `extends`, implemented `navigatorObservers` |
| `test/helpers/mock_auth_service.dart` | Fixed relative import to package import |
| `test/helpers/mock_firestore_service.dart` | Fixed import, implemented 6 missing interface methods, added test fixtures |
| `test/viewmodels/advisor_viewmodel_test.dart` | Aligned GPA assertions with term-GPA contract and updated advice assertion |
| `test/viewmodels/roadmap_viewmodel_test.dart` | Injected mock services into `setUp()` |
| `test/viewmodels/tasks_notes_test.dart` | Fixed imports, injected mock services into `setUp()` |
| `test/widget_test.dart` | Fixed stale import paths |
| `docs/pre-push-repair.md` | Comprehensive post-repair audit documentation |

---

## 8. Final Verdict

**VERDICT: READY TO COMMIT**

All pre-push audit blockers have been cleared. Static analysis and automated test suites are 100% green. Build verification passed cleanly. Absolute constraints (no commits, no pushes, no Firebase deployment, no credential leakage, no weakened tests) were strictly observed.
