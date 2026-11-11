# PRM393 Lab 3 — Takeover Audit

> Scope: evidence-based audit of the repository at `main` (`c19635b`), against `LAB3_CHECKLIST.md` and `BAO_CAO_TIEN_DO_LAB3.md`. Both rubric documents live **outside** the repository, at `../BAO_CAO_TIEN_DO_LAB3/`. No application code was modified by this audit.
>
> Verification limits: no Android device, no `adb`, no `gh` CLI, no Firebase project credentials in this environment. Anything requiring a real device, Console access or a network Firebase project is marked `UNVERIFIED`. Nothing in this document is inferred from a class or button existing alone.

---

## 1. Executive summary

**Readiness: not submittable. The app cannot currently be built, and if built it would not talk to Firebase.**

Three independent blockers sit in front of every remaining rubric item:

1. `pubspec.yaml:17` requires Dart `^3.13.5`; the installed SDK is Dart **3.13.4**. `dart pub get` fails outright — no `.dart_tool/`, so `flutter analyze`, `flutter test` and `flutter build` all fail. Verified by running `dart pub get --dry-run`.
2. `lib/firebase_options.dart:23-27` contains a **placeholder** project (`AIzaSyPlaceholderAndroidKeyForLab3PRM323`, `1:123456789000:android:...`). There is no `android/app/google-services.json` (it is gitignored at `.gitignore:53`) and no `com.google.gms.google-services` Gradle plugin. `Firebase.initializeApp()` therefore throws, and `lib/main.dart:50` swallows that exception — after which `_hasFirebase` is false and the whole app silently runs on `MockAuthService` / `MockFirestoreService` (`lib/main.dart:75-96`). A green UI proves nothing.
3. `android/app/src/main/AndroidManifest.xml` has **no `INTERNET` permission** (only `src/debug` and `src/profile` declare it). A release APK cannot reach Firebase at all.

Behind those, the Firebase layer that *is* written is disconnected from the signed-in user: `'user_p02'` is hard-coded in six places across three ViewModels and one screen. Firestore/Storage rules key on `request.auth.uid`, so every real read/write for a real account is denied — and the ViewModels swallow those failures with `catch (_) {}` while the UI reports success.

What is genuinely good and must be preserved: MVVM boundaries are clean (no SDK import in `lib/screens/` or `lib/widgets/`), `AsyncViewState<T>` with loading/empty/error/retry is used on all three data screens, security rules are owner-scoped with a default-deny tail, theme tokens and reusable widgets exist, and 47 checklist items are legitimately done.

The progress report's list is broadly correct but understates the problem: it lists unfinished *features*, while the actual state is that Firebase is not wired to a real project and the user-identity plumbing is hard-coded. Fixing PDF or FCM before that is meaningless.

---

## 2. Checklist status table

Legend: `IMPLEMENTED` code exists and is traceable · `PARTIAL` exists but incomplete · `MISSING` absent · `UNVERIFIED` code exists, runtime/config cannot be confirmed here.

### 2.1 Definition of Done (§0)

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Runs on real Android device | `UNVERIFIED` | Build blocked: `pubspec.yaml:17` vs Dart 3.13.4. No `adb` in environment. |
| 2 | No mock/hard-coded data in main flow | `MISSING` | `lib/main.dart:84,89` fall back to mock services; `'user_p02'` at `notes_viewmodel.dart:66,139`, `tasks_viewmodel.dart:81,130,155`, `roadmap_viewmodel.dart:175`, `sync_vault_screen.dart:41,44`; `home_viewmodel.dart:12-19` is a TODO returning literal greeting. |
| 3 | ≥8 core Lab 2 screens + Sign-in + Profile/Settings | `IMPLEMENTED` | 11 files in `lib/screens/`; routes in `lib/main.dart:143-158`. |
| 4 | 3 user flows incl. error and recovery branches | `PARTIAL` | Flows 1–2 have loading/empty/error/retry (`roadmap_screen.dart:105-110`, `tasks_screen.dart:137-142`, `notes_screen.dart:56-61`). Flow 3 has **no** error branch: `AdvisorViewModel.askQuestion` cannot fail (`advisor_viewmodel.dart:104-152`), and no retry exists in `advisor_screen.dart`. |
| 5 | Auth, Firestore, Storage, FCM, Analytics, Crashlytics, Remote Config | `PARTIAL` | Six of seven have service classes; **FCM has none** (no `firebase_messaging` in `pubspec.yaml`). |
| 6 | Loading/Empty/Error/Data states | `IMPLEMENTED` | `lib/models/app_state.dart`, `lib/viewmodels/base_viewmodel.dart`; rendered at the three sites above. |
| 7 | View → ViewModel → Service → Firebase | `PARTIAL` | No SDK import under `lib/screens/` or `lib/widgets/` (verified by grep). But `sync_vault_screen.dart:113-115` reads services and calls them directly from the widget (`:38-46`, `:71-89`, `:94`), bypassing ViewModels. |
| 8 | ≥10 ARTEMIS tests × 3 runs | `MISSING` | No `e2e_test/`, no `docs/test-plan.md`, no `evidence/artemis/`. |
| 9 | ≥5 AI review findings, 3 fix commits | `MISSING` | No `docs/code-review.md`, no PR, no `fix(CR-*)` commits in `git log`. |
| 10 | Evidence in `evidence/` | `MISSING` | Directory does not exist. |
| 11 | Report PDF, slides PDF, video | `MISSING` | No `report/`, `slides/`. |
| 12 | Public repo, README with run/test/video | `PARTIAL` | Remote `github.com/tugnngw/prm323-lab2-gr6` exists. README describes Lab 2 as a *design* deliverable and states "Đây là bài thiết kế, không phải mã nguồn Flutter" — contradicts the app. |
| 13 | No secrets committed | `IMPLEMENTED` | `.gitignore:50-56` covers `google-services.json`, `*service-account*.json`, `*.jks`, `.env*`. Confirmed by `git check-ignore`. |

### 2.2 Integrate (§5)

| # | Item | Status | Evidence |
|---|---|---|---|
| 5.1 | Firebase project + FlutterFire CLI + `google-services.json` | `MISSING` | Placeholder options only. No google-services plugin in `android/app/build.gradle.kts` or `android/settings.gradle.kts`. |
| 5.1 | `Firebase.initializeApp()` verified | `PARTIAL` | Called at `main.dart:42`; failure swallowed at `:50`. |
| 5.1 | Clean Android build | `UNVERIFIED` | `dart pub get` fails (SDK constraint). |
| 5.2 | Google Sign-In implemented | `IMPLEMENTED` | `lib/services/firebase_auth_service.dart:41-84`. |
| 5.2 | Auth-state routing | `IMPLEMENTED` | `AuthViewModel._init` (`auth_viewmodel.dart:27-34`) → `AuthGate` (`main.dart:163-174`). |
| 5.2 | Cancel → clear message | `PARTIAL` | Cancellation returns silently with only `debugPrint` (`firebase_auth_service.dart:44-48`); nothing user-visible despite checklist wording. |
| 5.2 | Network loss → error, no crash | `IMPLEMENTED` (code) / `UNVERIFIED` (runtime) | `AuthException` mapping `firebase_auth_service.dart:59-80`; banner in `sign_in_screen.dart:60-84`. |
| 5.2 | Sign-out clears local data | `PARTIAL` | `AuthViewModel.signOut` (`:59-73`) only calls the service; no Firestore cache clear, no ViewModel reset. |
| 5.2 | `@fpt.edu.vn` restriction | `MISSING` | UI claims the domain (`sign_in_screen.dart:130`) but no domain check in code or rules. |
| 5.3 | `users/{uid}`, `courses`, `curriculums`, tasks, notes, **notifications**, **reports** collections | `PARTIAL` | Rules cover `users/{uid}/{tasks,notes,sync}`, `courses`, `curriculums` (`firebase/firestore.rules:19-50`). `notifications` and `reports` are absent from rules and code. `curriculums` exists in rules but is never read. |
| 5.3 | Firestore service | `PARTIAL` | Reads/writes implemented, but deletes are stubs (see §5). |
| 5.3 | Owner-only isolation by `uid` | `IMPLEMENTED` (rules) / **broken at call sites** | Rules correct (`firestore.rules:12-16`); caller passes a constant that is not the auth uid. |
| 5.4 | Storage service | `PARTIAL` | `lib/services/firebase_storage_service.dart` complete, but **never called** — `NotesViewModel.storageService` is injected (`notes_viewmodel.dart:12,19`) and unused; `uploadFile` has zero call sites. |
| 5.4 | `reports/{uid}/...` path | `MISSING` | Path referenced only in comments (`firebase_storage_service.dart:9`, `storage.rules:30`). |
| 5.4 | Storage rules owner-only, size-limited | `IMPLEMENTED` | `firebase/storage.rules:11-38`. Note: `notes/{userId}/{fileName}` is single-segment, so nested note attachments are denied. |

### 2.3 Features (§6)

| # | Item | Status | Evidence |
|---|---|---|---|
| 6.1 | All 11 screens | `IMPLEMENTED` | `lib/screens/*.dart`; routes `main.dart:143-158`. |
| 6.2 | Curriculum list, search, empty, prerequisite check, detail, states | `IMPLEMENTED` | `roadmap_screen.dart`, `course_detail_screen.dart:41-42`, `roadmap_viewmodel.dart:212-243`. |
| 6.2 | Analytics "search" + "view detail" events | `PARTIAL` | `course_view` fires from a **getter invoked during `build`** (`roadmap_viewmodel.dart:227-241` ← `course_detail_screen.dart:18`). No search event exists in `firebase_analytics_service.dart`. |
| 6.3 | Tasks create / **edit** / complete / delete | `PARTIAL` | Create + toggle exist (`tasks_viewmodel.dart:110-165`). No edit UI (`tasks_screen.dart` has only `_showAddTaskSheet` at `:17`). Delete does not persist (see §5). |
| 6.3 | Notes create / edit / delete | `PARTIAL` | Create/edit path present (`note_editor_screen.dart:54-96`); delete does not persist. |
| 6.3 | Attachment upload | `MISSING` | `_simulateAttachFile` fabricates a filename (`note_editor_screen.dart:94-98`) and `_saveNote` writes a literal `'https://storage/sample.pdf'` (`:81`). No file picker, no bytes, no upload. |
| 6.4 | Advisor Q&A, GPA strategy, levels | `PARTIAL` | Deterministic keyword replies in `advisor_viewmodel.dart:118-152`; level parameter exists but UI always passes default. |
| 6.4 | Advisor error branch + retry | `MISSING` | `askQuestion` has no failure path. |
| 6.4 | Share-consent dialog (DLG-04.1) | `MISSING` | No consent UI anywhere; `AppConfirmDialog` is used only for sign-out (`home_screen.dart:17`). Checklist §6.4 marks this `[x]` — that tick is wrong. |
| 6.5 | PDF export/upload (12 sub-items) | `MISSING` | No `pdf` / `printing` dependency (`pubspec.yaml`), no generation code. |
| 6.6 | Notification Center | `MISSING` | No screen, no route, no repository. |
| 6.6 | Remote Config display + refresh | `IMPLEMENTED` | `sync_vault_screen.dart:236-252`. |
| 6.6 | Crashlytics non-fatal button | `IMPLEMENTED` | `sync_vault_screen.dart:71-89`. |
| 6.6 | Firestore roundtrip test | `PARTIAL` | `sync_vault_screen.dart:38-59` — writes with `'user_p02'`, so it will fail under real rules. |

### 2.4 Instrument (§7)

| # | Item | Status | Evidence |
|---|---|---|---|
| 7.1 | ≥7 events defined | `IMPLEMENTED` | 8 typed methods, `firebase_analytics_service.dart:98-136`. |
| 7.1 | Events actually logged | `PARTIAL` | 6 of 8 wired: `course_view`, `prerequisite_check`, `task_create`, `task_complete`, `note_create`, `advisor_query`, `sync_triggered`. `logLoginSuccess` has **zero call sites**. No search event. |
| 7.1 | PII filtering | `IMPLEMENTED` | Key blacklist `firebase_analytics_service.dart:22-47`. |
| 7.1 | `setUserId(uid)` after login | `MISSING` | `setUserId` defined (`:67-78`), never called. |
| 7.1 | Screen tracking | `MISSING` | `navigationObserver` getter (`:18-19`) is never passed to `MaterialApp`; no `navigatorObservers` in `main.dart:139-158`. |
| 7.1 | `docs/analytics-plan.md` | `MISSING` | Not present. |
| 7.1 | DebugView evidence | `MISSING` | No `evidence/`. |
| 7.2 | Crashlytics global handlers | `IMPLEMENTED` | `crashlytics_service.dart:24-33`. |
| 7.2 | `setUserIdentifier` called | `MISSING` | Defined (`:82-95`), never called. |
| 7.2 | ≥1 custom key | `MISSING` | No `setCustomKey` in the repository. |
| 7.2 | Evidence | `MISSING` | — |
| 7.3 | ≥2 RC params + defaults | `IMPLEMENTED` | 4 params with defaults, `remote_config_service.dart:20-30`. |
| 7.3 | `firebase/remote-config-defaults.json` | `MISSING` | Only `firestore.rules`, `storage.rules`, `seed_data.json` in `firebase/`. |
| 7.3 | RC consumed by behaviour | `PARTIAL` | Only `feature_ai_advisor_enabled` gates UI (`advisor_screen.dart:59`). `maintenance_mode`, `min_app_version`, `vault_sync_interval_mins` are displayed but never enforced. |
| 7.4 | FCM: permission, token, foreground/background/terminated, tap-routing, notification store | `MISSING` | No dependency, no service, no `POST_NOTIFICATIONS` permission, no `notifications` collection. |

### 2.5 Test / Review / Report (§8–§12)

| # | Item | Status | Evidence |
|---|---|---|---|
| 8.x | ARTEMIS environment, plan, 10–14 tests, 3 runs, traces, exploratory session | `MISSING` | Nothing exists. `adb` and Python are not available in this environment either. |
| 9.x | PR, reviewer tool, 5 findings, decisions, 3 fix commits | `MISSING` | `git log` has no `fix(CR-*)`; no PR tooling (`gh`) installed. |
| 10.x | Evidence tree | `MISSING` | — |
| 11.x | Report / slides / video | `MISSING` | — |
| 12.x | README Lab 3 | `PARTIAL` | `README.md` is the Lab 2 design brief; no run/test/Firebase/ARTEMIS instructions. |
| — | Unit/widget tests | `PARTIAL` | 4 files, 12 cases, **all hermetic mocks**, none exercise Firestore/Auth/Storage analytics paths (`test/viewmodels/*`, `test/widget_test.dart`). |

Checklist arithmetic: **47 `[x]`, 366 `[ ]`, 0 `[-]`, 0 `[!]`**.

### 2.6 Incorrect `[x]` ticks found

These are marked complete but are not implemented — they must be re-opened before the report is written honest:

| Checklist line | Claim | Reality |
|---|---|---|
| §6.2 "Ghi Analytics event tìm kiếm" | search event logged | No search event defined or called. |
| §6.3 "Sửa task" | task editing | Add + toggle + delete only. |
| §6.4 "Cho phép Retry/phục hồi" | advisor retry | No error path to retry. |
| §6.4 "Hiển thị dialog xin quyền chia sẻ dữ liệu" | consent dialog | Does not exist. |
| §6.4 "Phân tích học đi/học lại" | pass/retake analysis | Only GPA arithmetic, no course-failure analysis. |
| §6.2 "Hiển thị danh sách môn từ Firestore/API" | Firestore-backed | Falls back to `_defaultCourses` whenever the query returns empty or throws; with real rules it always throws. |

---

## 3. Existing implementations worth preserving

Do not rewrite these; they already satisfy their rubric lines.

- **MVVM boundary**: zero `firebase_*` imports under `lib/screens/` or `lib/widgets/`. Verified by grep. Keep it that way.
- **`AsyncViewState<T>` + `BaseViewModel<T>`** (`lib/models/app_state.dart`, `lib/viewmodels/base_viewmodel.dart:9-22`) — four-state model, already rendered by three screens.
- **Theme tokens and reusable widgets**: `lib/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart`; `AppButton`, `AppOutlinedButton`, `AppCard`, `CustomAppBar`, `AppConfirmDialog`, `AppBottomNav`, `AppTextField`, `AppSearchBar`, `AppLoadingState`, `AppEmptyState`, `AppErrorState`.
- **`FirebaseAuthService`** (`firebase_auth_service.dart:41-105`): correct Google credential exchange, cancel-safe, mapped exception messages, service/interface split with `MockAuthService` behind the same interface.
- **`FirebaseFirestoreService` read/write paths** (`firebase_firestore_service.dart:36-120,140-181`): correct `users/{uid}/…` subcollection layout, `FieldValue.serverTimestamp()`, `Source.serverAndCache`, merge-on-save.
- **Security rules** — the strongest artefact in the repo:
  - `firestore.rules:12-16` owner helper; `:19-41` per-subcollection owner rules; `:44-54` authenticated read-only catalog with `write: if false`; `:57-61` append-only audit log scoped to `request.auth.uid`; `:64-66` explicit default deny. No `if true` anywhere (verified).
  - `storage.rules:11-20` size + MIME helpers; `:22-38` owner-only `notes/` and `reports/`; `:41-43` default deny.
- **`FirebaseStorageService`** (`firebase_storage_service.dart`): complete, size-capped download, typed metadata. It only lacks a caller.
- **`FirebaseAnalyticsService`** event facade and `_sanitizeParameters` PII guard (`:22-47`) — good shape, needs wiring.
- **`CrashlyticsService.initialize`** global handlers (`:24-33`) — correct pattern.
- **`RemoteConfigService`** defaults + settings (`:20-56`) — correct pattern; needs a single instance and externalised defaults file.
- **`MockAuthService` / `MockFirestoreService` / `MockAnalyticsService`** — keep, but confine to `test/`.
- **Docs**: `docs/architecture.md`, `docs/design-traceability.md` (screen→route→widget→ViewModel→source→TC mapping), plus `design/`, `ux/`, `ai/`, `handoff/`, `assets/{figma,stitch}/` (43 files).

---

## 4. Missing, partial and unverified requirements

### 4.1 Blocking (must fix before anything else can be graded)

| ID | Requirement | Status | What is needed |
|---|---|---|---|
| B-01 | Dependency resolution / build | `MISSING` | `pubspec.yaml:17` `sdk: ^3.13.5` vs Dart 3.13.4. Either upgrade the SDK or relax to `^3.13.0`. `pubspec.lock:497` records `dart: ">=3.13.5 <4.0.0"` — the lock was written on a different machine. |
| B-02 | Real Firebase project binding | `MISSING` | Replace `lib/firebase_options.dart` via `flutterfire configure`; add `google-services.json` out-of-band (gitignored); add `com.google.gms.google-services` plugin; change `applicationId` from `com.example.prm323_lab3` (`android/app/build.gradle.kts:19`) to the registered ID; register SHA-1/SHA-256. |
| B-03 | Release `INTERNET` permission | `MISSING` | `android/app/src/main/AndroidManifest.xml` declares no permissions; needs `<uses-permission android:name="android.permission.INTERNET"/>`. |
| B-04 | Silent mock fallback hides config failure | `PARTIAL` | `lib/main.dart:50` catches all init errors and continues; `:75-96` then substitutes mocks. A release build must fail loudly (or show a blocking error screen) instead of silently mocking. |
| B-05 | Signed-in identity plumbing | `MISSING` | Six `'user_p02'` literals (§2.1 row 2) must come from `AuthService.currentUserId`, with a fail-closed path when null. |

### 4.2 Feature gaps

| ID | Requirement | Status | Notes |
|---|---|---|---|
| F-01 | PDF export + Storage upload | `MISSING` | No `pdf`/`printing` dependency, no generation, no upload, no metadata doc, no `export_report` event, no consent dialog. |
| F-02 | FCM + Notification Center | `MISSING` | No `firebase_messaging`, no token store, no handlers, no `notifications` collection/rule, no tap routing, no `POST_NOTIFICATIONS`. |
| F-03 | Storage actually used | `MISSING` | `FirebaseStorageService` unreferenced from app code. |
| F-04 | Real attachments | `MISSING` | `note_editor_screen.dart:81,94-98` fabricate URL and filename. |
| F-05 | Advisor error branch + retry | `MISSING` | `advisor_viewmodel.dart:104-152` always succeeds. |
| F-06 | Share-consent dialog | `MISSING` | Required by §6.4 and §6.5. |
| F-07 | Task edit | `MISSING` | Only add/toggle/delete. |
| F-08 | Analytics wiring | `PARTIAL` | See §2.4 rows 2, 4, 5. |
| F-09 | Crashlytics custom key + user id | `MISSING` | `setUserId`/`setCustomKey` never invoked. |
| F-10 | `docs/analytics-plan.md`, `docs/test-plan.md`, `docs/code-review.md`, `firebase/remote-config-defaults.json`, `lib/utils/` | `MISSING` | Required paths absent. |

### 4.3 Unverifiable in this environment

| Item | Why | What would verify it |
|---|---|---|
| Physical-device run, release build | No `adb`, and `pub get` fails | Device + `flutter build apk --release` |
| Auth/Firestore/Storage against real project | Placeholder options, no credentials | Firebase Console project, registered app, SHA-1 |
| Analytics DebugView, Crashlytics dashboard, RC before/after | Console-only | Console access + debug device |
| FCM three states | Not implemented | Implementation first |
| ARTEMIS runs | No Python/`uv`/`adb`/API key | Toolkit + device + API key via env |
| AI review findings | No PR tooling (`gh` absent) | GitHub PR + reviewer bot |

---

## 5. Critical security, data-integrity and architecture risks

Ranked. Each is a real defect with a concrete failure.

**S-01 — Identity is hard-coded, not derived from auth (critical).**
`notes_viewmodel.dart:66,139`, `tasks_viewmodel.dart:81,130,155`, `roadmap_viewmodel.dart:175`, `sync_vault_screen.dart:41,44` all use `'user_p02'`. Rules require `request.auth.uid == userId` (`firestore.rules:12-16`). Consequence: once a real project is configured, every task/note read and write is `permission-denied`. If it ever "works", it works because the account's real uid happens to be spelled `user_p02` — i.e. isolation is accidental. This also invalidates the two claims that matter most in the report (user-specific isolation, and "dữ liệu thật thay cho mock").

**S-02 — Deletes are no-ops that look like success (critical, data integrity).**
`FirebaseFirestoreService.deleteTask` (`:122-125`) and `deleteNote` (`:183-185`) only `debugPrint`. The real implementations exist but are unused: `deleteTaskForUser` (`:127`) and `deleteNoteForUser` (`:187`). UI path: `tasks_screen.dart:191,238` and `notes_screen.dart:112,149` call `vm.deleteTask`/`vm.deleteNote`, which remove the row from `_allTasks`/`_allNotes` (`tasks_viewmodel.dart:168-176`, `notes_viewmodel.dart:153-161`) and repaint. The item reappears on next load. Silent data resurrection.

**S-03 — Write failures are swallowed while the UI reports success (critical).**
`catch (_) {}` at `notes_viewmodel.dart:95,141,160` and `tasks_viewmodel.dart:132,157,174`. The note editor then shows "Đã lưu ghi chú vào Vault thành công!" unconditionally (`note_editor_screen.dart:84-90`) and pops. Users believe data is saved and synced when it may not be. This also means `AsyncViewState.error` is never reached from a write — only from the initial read.

**S-04 — Firebase failure is masked at startup (high).**
`main.dart:50` catches every init exception and continues; `:75-96` then wires mocks for Auth and Firestore. Result: the app is fully usable with zero Firebase, so nothing in manual testing distinguishes broken config from working config. Also note `lib/main.dart:94` has a no-op ternary (`_hasFirebase ? FirebaseStorageService() : FirebaseStorageService()`), and `FirebaseStorageService` already self-nulls (`:17-19`) into mock-URL behaviour — so "upload succeeded" messages are fabricated URLs.

**S-05 — Release build has no network permission (high).**
`android/app/src/main/AndroidManifest.xml` declares no `INTERNET` permission (only debug/profile manifests do). A release APK silently cannot reach Firebase, Play Integrity or Storage. Translates to an unexplained all-offline demo on the graded device.

**S-06 — Analytics duplicates and lies about volume (medium-high).**
Events fire from getters called during `build`: `isEligibleForCourse` (`roadmap_viewmodel.dart:212-224`) is called on every rebuild of `roadmap_screen.dart:150` and `course_detail_screen.dart:41`; `findCourseById` (`:227-241`) logs `course_view` from `course_detail_screen.dart:18`, inside `build`. DebugView counts will be wrong and inflated; `prerequisite_check.is_eligible` embeds PII-free but wrong telemetry. Any report claiming "7 events verified in DebugView" would be misleading.

**S-07 — `is FirebaseAnalyticsService` type checks make instrumentation fragile (medium).**
`notes_viewmodel.dart:144`, `tasks_viewmodel.dart:136,160`, `roadmap_viewmodel.dart:217,231`, `advisor_viewmodel.dart:108`, `sync_vault_screen.dart:93`. A decorator, a wrapper, or `MockAnalyticsService` silently drops all events — no compile error. This is the same class of bug the rubric wants an AI review to catch; either way, it must call the `AnalyticsService` interface.

**S-08 — Remote Config instance mismatch (medium).**
`main.dart:49` initialises a throwaway `RemoteConfigService()`; `main.dart:106` provides a *different* instance to the tree. It happens to work because `FirebaseRemoteConfig.instance` is a singleton, but the injected object's `initialize()` was never awaited, and any future per-instance state (or a test double) breaks silently. Same pattern for `CrashlyticsService` (`:48` vs `:102`).

**S-09 — Storage rules deny nested note attachments (medium).**
`storage.rules:22` matches exactly `notes/{userId}/{fileName}` — one segment. `reports/{userId}/{allPaths=**}` (`:30`) is recursive but does **not** validate `contentType`, only size. When attachments are implemented, uploaded files under `notes/{uid}/2026/…` will be rejected. Fix the pattern and decide whether `reports/` should be PDF-only.

**S-10 — Email-domain claim is not enforced (medium, compliance).**
`sign_in_screen.dart:130` says "@fpt.edu.vn", and `architecture.md` claims the domain is enforced. Nothing checks it: no `FirebaseAuthException` handling for domain, no rules check, no client gate. Any Google account can sign in.

**S-11 — Test suite cannot catch any of the above (medium).**
All 12 tests construct ViewModels with `null` services (`advisor_viewmodel_test.dart:9`, `roadmap_viewmodel_test.dart:8`, `tasks_notes_test.dart:8,55`) or pass mocks that ignore uid (`widget_test.dart:10-12`). `widget_test` uses `'user_123'` while the ViewModels hard-code `'user_p02'` — the discrepancy is untested. Several tests sleep on wall-clock delays (`Future.delayed(200ms)`) instead of `pumpAndSettle`/fake async, so they are latency-flaky. No test touches `FirebaseFirestoreService`, `FirebaseStorageService`, rules, or the analytics facade.

**S-12 — Repository identity mismatch with rubric (low, but blocks grading).**
Checklist requires repo `PRM393_Lab03_<StudentID>`, package/app name to be chosen and pinned; current repo is `prm323-lab2-gr6`, `applicationId = com.example.prm323_lab3` (with a `TODO:` at `android/app/build.gradle.kts:18`), `pubspec.yaml name: prm323_lab3`. Firebase app registration depends on the final application ID — fix before B-02.

---

## 6. Dependency-ordered implementation roadmap

Each task is the smallest change that unblocks the next. Order is strict where a dependency is noted.

| # | Task | Depends on | Why here |
|---|---|---|---|
| T01 | Restore a resolvable build (`sdk` constraint; `flutter pub get`; `flutter analyze`; `flutter test`) | — | Nothing can be verified, reviewed or tested until this passes. |
| T02 | Rename app identity (`applicationId`, package, repo/README naming) | T01 | Firebase registration binds to the application ID; renaming after registering invalidates SHA-1 and the client. |
| T03 | Bind a real Firebase project (`flutterfire configure`, `google-services.json` out-of-band, google-services plugin, SHA-1/SHA-256) | T02 | Everything in §7 is unverifiable without it. |
| T04 | Fail loud, not silent: remove mock fallback on init failure; add blocking error screen | T03 | Prevents T05–T12 from being "verified" against mocks. |
| T05 | Release `INTERNET` permission + `POST_NOTIFICATIONS` (Android 13+) | T03 | One-line manifest changes; needed by every network feature and by FCM. |
| T06 | Thread authenticated uid through all ViewModels/screens; fail closed when null | T04 | Fixes S-01; without it every Firestore write in T07–T11 fails. |
| T07 | Make deletes persist; remove `catch (_) {}`; surface write errors in state + snackbar; roll back optimistic updates | T06 | Fixes S-02/S-03. Highest data-integrity risk in the app. |
| T08 | Analytics wiring: `setUserId` on login, `logLoginSuccess`, `navigatorObservers`, move events out of `build`/getters, call the interface not the concrete class, add `search_course` | T06 | Fixes S-06/S-07; produces the DebugView evidence the report needs. |
| T09 | Crashlytics: `setUserIdentifier` + ≥1 `setCustomKey` on login; verify release collection | T08 | Reuses the same login hook as T08. |
| T10 | Remote Config: single instance, `firebase/remote-config-defaults.json`, enforce `maintenance_mode` + `min_app_version` | T08 | Fixes S-08; enforcement is what makes before/after Console evidence meaningful. |
| T11 | PDF export: `pdf`/`printing` generation from live data → consent dialog → `reports/{uid}/study_report_<ts>.pdf` upload with progress → download URL → Firestore metadata → `export_report` event | T06, T07, T10 | Largest remaining feature; also feeds T12 evidence. |
| T12 | FCM + Notification Center: token storage, foreground/background/terminated handlers, `notifications` collection + rules, tap routing | T05, T06, T07 | Second-largest feature; needs the manifest permission and uid plumbing. |
| T13 | Storage rules hardening (recursive `notes/` path, PDF-only for `reports/`) | T11 | Rule changes must follow the path shape actually used. |
| T14 | ARTEMIS: `e2e_test/` harness + `docs/test-plan.md` + 10–14 cases + 3 runs each + traces | T07–T13 | Tests can only assert features that exist on a real project. |
| T15 | AI Code Review: open PR, run reviewer, `docs/code-review.md` with 5 findings, 3 separate `fix(CR-0x)` commits | T14 | Review must target near-final code. |
| T16 | `evidence/` matrix + README Lab 3 + checklist re-tick + report/slides/video | T15 | Packaging last; every claim needs prior evidence. |

Blocker to not skip: T04. If the mock fallback survives, T14's ARTEMIS suite can pass on a device with no Firebase at all, producing evidence for a feature that does not exist.

---

## 7. Acceptance criteria and required evidence per task

| Task | Acceptance criteria | Required evidence |
|---|---|---|
| T01 | `dart pub get` exits 0; `flutter analyze` reports 0 errors; `flutter test` passes all existing cases | Terminal output of the three commands, committed as `evidence/app/T01-*.txt` |
| T02 | `applicationId` matches the registered Firebase app; no `TODO: Specify your own unique Application ID`; README pins Flutter 3.47.5 / Dart version | `android/app/build.gradle.kts` diff; `flutter --version` output |
| T03 | `Firebase.initializeApp()` succeeds on device; `Firebase.apps.isNotEmpty` true in a release build | Sign-in screenshot; `flutter run` log line; Console project screenshot (no secrets) |
| T04 | Removing `google-services.json` produces an explicit error screen, never a mock-backed UI | Two screenshots: configured success, unconfigured failure |
| T05 | Release APK has `INTERNET` and `POST_NOTIFICATIONS`; `aapt dump permissions` lists both | Command output |
| T06 | Zero occurrences of `user_p02` / `test_p02` / `user_123` in `lib/`; all ViewModels read uid from `AuthService`; null uid yields a signed-out state, not a write | `grep -rn "user_p02" lib` returns nothing; unit test asserting the path uses the mock uid |
| T07 | Delete persists across a cold restart; a forced write failure shows an error and rolls back the row | Screen recording of delete → restart → still gone; test with a throwing fake service |
| T08 | DebugView shows each of the 8 events with expected parameters; each event fires once per user action; no event fires from `build` | DebugView screenshots per event; count assertions in a widget test |
| T09 | Crashlytics report shows User ID + the custom key; non-fatal and forced crash both appear | Dashboard screenshots with uid and key visible |
| T10 | Changing `maintenance_mode` / `min_app_version` in Console changes the app without rebuild | Before/after screenshots; `remote-config-defaults.json` committed |
| T11 | PDF contains the data currently displayed; upload lands at `reports/{uid}/study_report_<ts>.pdf`; progress shown; URL displayed and openable; Firestore metadata doc exists; `export_report` event logged | PDF file; in-app progress + URL screenshot; Console Storage path; Firestore doc screenshot; DebugView event |
| T12 | Notification received in foreground, background and terminated; each lands in Notification Center; tapping opens the target screen | Six screenshots (3 states × banner + center) + Firestore `notifications` doc |
| T13 | Uploading to `notes/{uid}/a/b.pdf` succeeds; uploading a non-PDF `.exe` to `reports/` is denied; anonymous read denied | Rules Playground or emulator test output |
| T14 | ≥10 cases; each run 3×; pass rate table; average duration; flaky investigation; trace IDs; exploratory session notes | `evidence/artemis/` traces, `docs/test-plan.md` |
| T15 | 5 findings with `file:line`; ≥2 categories; each Accepted/Modified/Rejected with reason; 3 independent `fix(CR-0x)` commits linked | `docs/code-review.md`; reviewer output; `git log --oneline` |
| T16 | Every rubric row has an evidence pointer; checklist ticks match code reality (§2.6 corrected); report 8–12 pp., slides 12–15 pp., video 5–10 min | `evidence/README.md` matrix; PDFs; video link in README |

---

## 8. Suggested commit sequence

Conventional commits, one concern each, in roadmap order. Prefixes map to the checklist's phase names so the git history satisfies "Plan → Architect → Integrate → Features → Instrument → Test → Review → Report".

```text
fix(build): relax Dart SDK constraint and restore flutter pub get      # T01
chore(app): rename application id and package to PRM393 Lab 3 app      # T02
feat(integrate): bind real Firebase project and add google-services    # T03
fix(integrate): fail loudly when Firebase initialization fails         # T04
fix(android): declare INTERNET and POST_NOTIFICATIONS permissions      # T05
fix(integrate): derive user id from auth instead of hard-coded literal # T06
fix(firestore): persist task and note deletes and surface write errors # T07
feat(instrument): wire analytics user id, screen tracking and events   # T08
feat(instrument): set Crashlytics user identifier and custom keys      # T09
feat(instrument): externalise Remote Config defaults and enforce them  # T10
feat(features): generate, consent and upload study report PDF          # T11
feat(instrument): add FCM handlers and Notification Center             # T12
fix(security): harden storage rules for nested and report uploads      # T13
test(e2e): add ARTEMIS test plan and ten flow tests                    # T14
docs(review): record five AI review findings                          # T15
fix(CR-01): <finding one>                                              # T15
fix(CR-02): <finding two>                                              # T15
fix(CR-03): <finding three>                                            # T15
docs(report): add evidence matrix, Lab 3 README and rubric updates     # T16
```

Notes:
- `T15`'s three `fix(CR-0x)` commits are rubric-mandated as *separate* commits; do not squash them.
- Do not amend or rebase `c19635b`…`0cad041`; the history is already phased and grading may inspect it.
- `.gitignore:53` keeps `google-services.json` out of git. That is correct per §0 ("không commit secret"), so the file must be supplied to the grader out-of-band (report appendix, not repository).

---

## 9. Environment prerequisites and manual blockers

Everything below needs access this audit does not have. Each is a hard stop for the task that follows it.

| Blocker | Needed for | Detail |
|---|---|---|
| Dart SDK ≥ 3.13.5 (or a decision to relax the constraint) | T01 onward | Installed is 3.13.4; `pubspec.lock:497` already assumes ≥3.13.5. |
| Firebase project + Console access (Spark) | T03, T08–T12, all evidence | Must create project, register Android app, enable Google provider, upload SHA-1/SHA-256, create `courses`/`curriculums` docs, publish `firestore.rules` + `storage.rules`, set RC values. |
| `google-services.json` | T03 | Gitignored by design. Supply out-of-band; never print its contents in logs or screenshots. |
| Android device or emulator with Google Play Services | T03, T09, T12, T14 | No `adb` on this machine. Emulators without Play Services cannot complete Google Sign-In. |
| Test Google account restricted to the organisation | T14 | Must be a separate account; credentials must not enter the repo, and must not be typed into terminals that log commands. |
| ARTEMIS toolkit: Python ≥3.12, `uv`, `adb`, model API key via env var | T14 | Nothing installed. Pin the ARTEMIS commit in README. |
| GitHub PR + AI reviewer (CodeRabbit / Copilot / SonarCloud / Kodus) | T15 | `gh` is not installed; the remote is `github.com/tugnngw/prm323-lab2-gr6`. |
| Video hosting (public or link-accessible) | T16 | README must link it. |
| Image/screenshot tooling that redacts secrets | all evidence | Screenshots of Console, DebugView and Crashlytics must not expose API keys, project credentials or account email beyond what the rubric requires. |

---

## 10. Correction list for the progress report

`BAO_CAO_TIEN_DO_LAB3.md` is directionally right but should be amended in three places so the final report is defensible:

1. §3.1 and §3.2 describe the flows as complete and Firestore-backed. They are UI-complete but data-path-broken (S-01, S-03). Add that read/write currently targets a constant uid and that write failures are swallowed.
2. §3.4 says rules "hướng tới giới hạn theo uid" — accurate, but it should state plainly that the rules are correct and the **callers are not**, since that is the actionable gap.
3. §5 priority list starts with README and PDF. Build resolution (T01), Firebase binding (T03) and uid plumbing (T06) must come first; PDF and FCM cannot be demonstrated, tested or evidenced otherwise.
