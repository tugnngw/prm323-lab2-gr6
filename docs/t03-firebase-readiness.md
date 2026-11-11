# T03-AUDIT — Firebase Integration Readiness

**Status:** AUDIT COMPLETE (audit only — no code, Gradle, rules or dependency changes)
**Date:** 2026-10-29
**Predecessors:** [t01-build-recovery.md](t01-build-recovery.md), [t02-persistence-hardening.md](t02-persistence-hardening.md), [lab3-takeover-audit.md](lab3-takeover-audit.md)

---

## 1. Method and verification limits

Every statement below is backed by a file/line citation (code evidence) or explicitly marked
**UNVERIFIED-RUNTIME** (behavior requiring a device, Console access, or network Firebase project —
neither is available in this environment). Nothing is claimed to run that has not been observed running.

---

## 2. Current integration status (code evidence vs runtime)

### 2.1 Initialization (`lib/main.dart:39-55`)

| Aspect | Code evidence | Runtime status |
|---|---|---|
| `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` inside try/catch | `main.dart:42-45` | **UNVERIFIED-RUNTIME** — will only succeed once `google-services.json` is present (plugin requires it at build time, then the JSON values are compiled in) |
| Crashlytics + RemoteConfig initialized right after | `main.dart:47-49` | **UNVERIFIED-RUNTIME** |
| Initialization failure is caught and logged, app continues | `main.dart:50-53` | Verified by code inspection: `_hasFirebase => Firebase.apps.isNotEmpty` (`main.dart:75`) then routes to mock services — but note: **no user-visible signal exists** (see §2.5) |
| Fallback wiring all six interfaces to mock implementations | `main.dart:84-108` | Reads correctly; `FirebaseApps` check is a documented heuristic, not a health check |

**Findings — none blocking, recorded as defensible simplifications:**
- `Provider<StorageService>` branch is mislabeled: `(_hasFirebase ? FirebaseStorageService() : FirebaseStorageService())` at `main.dart:94` — both arms identical (the run-time mock fallback lives *inside* `FirebaseStorageService`). Harmless but misleading. `ponytail:` cleanup candidate — left as-is (audit-only).
- `HomeViewModel` gets no `authService`/`firestoreService` (`main.dart:121`) — reads local seeded data only, so it is unaffected by either mode.
- `sync_vault_screen.dart:38-67` reads Firestore directly (bypasses ViewModel) — a known architecture smell already tagged in the audit; not re-flagged here as a blocker.

### 2.2 Platform configuration (`lib/firebase_options.dart`)

| Aspect | Evidence |
|---|---|
| Real project identifiers registered | `projectId: 'prm323-lab2-gr6'`, android `appId: '1:510519082861:android:4cf5b64c4e2e4487c46464'`, `messagingSenderId: '510519082861'`, `storageBucket: 'prm323-lab2-gr6.firebasestorage.app'` (`firebase_options.dart:23-29`) |
| Whether these values are valid/live in the console | **UNVERIFIED-RUNTIME** — can only be confirmed after the app runs with a real `google-services.json`, which their values must match (§4.2) |
| Only `android` case implemented in switch | `firebase_options.dart:13-15` — appropriate for this lab scope; a `default:` throw covers other targets |

### 2.3 Android Gradle / applicationId

| Aspect | Evidence |
|---|---|
| `applicationId = "com.example.prm323_lab3"` | `android/app/build.gradle.kts:11` |
| `com.google.gms.google-services` v4.5.0 declared in settings and applied in app build | `android/settings.gradle.kts`, `android/app/build.gradle.kts:4` |
| `google-services.json` absent + gitignored | `.gitignore:53`; absence re-confirmed without reading contents |
| Consistency requirement | The downloaded JSON must contain `package_name: com.example.prm323_lab3` and matching project id/api key — else plugin rejects the build |

### 2.4 Auth & DI wiring

| Aspect | Evidence |
|---|---|
| `FirebaseAuthService` implements full Google Sign-In flows | `firebase_auth_service.dart:38-88` — user-visible error banner surfaced through `AuthException` codes (network/user-disabled/account-exists/fallback) at `sign_in_screen.dart:59-84`; cancel path returns silently (debugPrint only, matches lab checklist wording) |
| DI is real and complete | `main.dart:78-77` reads `AuthService` per mode; `TasksViewModel`, `NotesViewModel`, `RoadmapViewModel`, `AuthViewModel`, `AdvisorViewModel` all receive `authService` + `analyticsService` (and Notes also `storageService`) via `ctx.read` around `main.dart:110-140` |
| `currentUserId` propagation | T02 verified; zero `user_p02` in lib/test — confirmed by grep in this pass |
| Google Sign-In server-client / SHA-1 needs | **UNVERIFIED-RUNTIME** — plain Google Sign-In with `scopes:['email','profile']` needs the app's debug SHA-1 registered in Firebase console for Android credential exchange; listed in §4 |

### 2.5 Mock fallback signaling

**This is the weakest ready-state dimension.** Code runs in whichever mode `Firebase.apps.isNotEmpty`
decides, and the difference is invisible to a grader/user:

| What exists | Where | What is missing |
|---|---|---|
| debugPrint only | `main.dart:47-53` `[Firebase] Initialized successfully.` vs `[Firebase] Initialization caught (running with fallback):` | No widget/badge/developer console surface (no `Banner`, no `bool get isMockMode` exposed to UI) |
| Per-service debugPrints | each `Mock*Service` method | Same — only visible in `flutter logs`, easy to miss |
| `FirebaseStorageService`'s internal null-client fallback returns a fabricated `storage.googleapis.com/mock-bucket/` URL | `firebase_storage_service.dart:31-34, 55-58, 72-75, 87-90` | No differentiation between a *real failed upload* and a *never-attached Firebase Storage client* — output URL can be mistaken for success downstream |

**Evidencing rule for verification (see §6 matrix):** runtime claims of "real mode" must come from
either (a) `Firebase.apps.isNotEmpty == true` plus a successful hard assertion against REAL data
flows, or (b) visible console output naming the concrete service invoked. Silent UI success is
explicitly not evidence. Until a widget-level mock/status indicator is added (§7, item 3), every
runtime verification must quote the `debugPrint` lines.

### 2.6 Analytics / Crashlytics / Remote Config

| Service | Evidence | Runtime |
|---|---|---|
| Analytics | `firebase_analytics_service.dart:22-47` PII key blacklist strips named email/name/phone fields before send; 8 typed events exist at `:98-136` | **UNVERIFIED-RUNTIME** |
| Crashlytics | `crashlytics_service.dart:14-45` — collection disabled in debug, `FlutterError.onError` + `PlatformDispatcher.instance.onError` wired | **UNVERIFIED-RUNTIME** |
| Remote Config | 4 parameters with defaults (`remote_config_service.dart:11-22`); safe fetch/activate, fallback getters | **UNVERIFIED-RUNTIME** |

### 2.7 Security rules as currently written (`firebase/firestore.rules`, `firebase/storage.rules`)

Firestore: `users/{uid}/{profile,tasks,notes,sync}` owner-only, `courses`/`curriculums`
authenticated-read + admin-write, append-only `audit_logs`, catch-all deny — consistent with the
client contract T02 enforces. Storage: owner-only `notes/{uid}/*` (10 MB cap, image/pdf/txt) and
`reports/{uid}/**` catch-all deny, with one noted rule nit: `notes/{userId}/{fileName}` is a
single-segment wildcard, so strictly nested note attachment paths would be denied — irrelevant
while the app writes single-level paths, not a blocker.

**Deployment state: rules exist as files only — they are NOT deployed** (no `firebase.json`, no CLI
config in the repo, no evidence of console deployment). Treating rules as active would be false.

### 2.8 Firebase-related tests

`test/viewmodels/tasks_notes_test.dart` (16), `test/widget_test.dart` (4), `advisor/roadmap` tests —
25 total, all passing, all hermetic against `MockAuthService`/`FakeFirestoreService`. **No test
exercises a real Firebase layer** (impossible hermetically); the runtime matrix below is manual.

---

## 3. Go-live gaps in ranked order

1. `google-services.json` missing (build-level hard blocker)
2. Rules not deployed (data-level)
3. Google Sign-In SHA-1 / OAuth client unverified in console (auth-level)
4. Mock-fallback invisible to graders (evidence-level)
5. Android release manifest lacks `INTERNET` (`android/app/src/main/AndroidManifest.xml` —
   only `src/debug` and `src/profile` declare it): **debug builds run fine; release builds
   silently cannot reach Firebase**. Not in this task's code-freeze scope; flagged for the
   release checklist task.

---

## 4. Required Firebase Console setup (manual, user-side)

All steps are Console actions; nothing in the repo can provide them.

### 4.1 Project binding
Assuming project **prm323-lab2-gr6** exists (its `google-services.json`-equivalent identifiers are
already in `firebase_options.dart`):

1. Firebase Console → Project Settings → Your apps → **Add Android app**
   — package name must be exactly **`com.example.prm323_lab3`**; nickname optional.
2. Download `google-services.json` → place at `android/app/google-services.json`.
   **Do not commit it** (`.gitignore:53` already prevents this).
3. Re-run `flutter build apk --debug`. If `processDebugGoogleServices` still fails, the JSON is
   for the wrong package/project — do not patch code to work around it.

### 4.2 Authentication
4. Build → Authentication → Sign-in method → enable **Google**.
5. Authentication → Settings → Authorized domains: add `localhost` if testing `flutter run` from IDE (usually pre-added).
6. **Debug SHA-1**: obtain from the debug keystore
   (`keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android`)
   → Project Settings → Your apps → com.example.prm323_lab3 → Add fingerprint. This is what makes
   Google Sign-In issue an idToken to a debug-signed APK.

### 4.3 Firestore + Storage data-plane
7. Build → Firestore Database → Create database (production mode) → deploy rules (§5).
8. Build → Storage → Get started (creates `prm323-lab2-gr6.firebasestorage.app` matching
   `firebase_options.dart:29`) → deploy rules (§5).
9. Optional seed: `firebase/seed_data.json` is in-repo if catalog data must be preloaded.

### 4.4 Other SDKs
10. Enable Analytics (auto-on when project created), Crashlytics, Remote Config — all inside the
    same project; no extra console work beyond clicking "Enable" per card once the app first runs.

---

## 5. Rules deployment steps (CLI, from project root)

```bash
# one-time machine setup (or use console paste-in alternative below)
npm install -g firebase-tools
firebase login
firebase init firestore storage --project prm323-lab2-gr6   # point rules at firebase/firestore.rules and firebase/storage.rules
```

```bash
firebase deploy --only firestore:rules,storage --project prm323-lab2-gr6
```

Verify in Console → Firestore → Rules / Storage → Rules that the deployed content matches the
in-repo files and the "deployed" timestamp advances. **Console paste-in alternative** (no CLI):
Firestore → Rules → paste content of `firebase/firestore.rules` → Publish; same for Storage.

Evidence needed: screenshot or CLI `firebase deploy` output showing deployment succeeded, plus the
Rules tab showing the exact content above.

---

## 6. Verification matrix (once §4 + §5 are done)

Run each row against a **debug-signed APK installed on a real Android device or emulator**.

| # | Area | Manual action | Passing evidence (what to write down) | Failing evidence = mock/alert |
|---|---|---|---|---|
| V1 | Build | `flutter build apk --debug`, install, launch | exit 0; `[Firebase] Initialized successfully.` in adb logcat | `Initialization caught (running with fallback)` line present |
| V2 | Mode check | As soon as app loads | both branches of §2.5 console text absent/present correctly; **no silent display of a mock-only URL** | Any `mock-bucket` URL surfaced in app copy |
| V3 | Auth sign-in | Tap Google Sign-In button | `[Auth] Google Sign-In succeeded for uid: <real-uid>`; UI reaches AppShell | `AuthException` text shown; or stuck on SignInScreen |
| V4 | Auth cancel | Tap Sign-In, cancel chooser | `[Auth] Google Sign-In was cancelled by user.`; no crash, no error snackbar | an error thrown |
| V5 | Auth sign-out | Sign out | `[Auth] Successfully signed out.`; SignInScreen returns | hang/crash |
| V6 | Firestore create | Notes screen → new note → save | `[Firestore] saveNote ...` no error; console: document in `users/<real-uid>/notes` | `lastError` visible in app (per T02); Console: no doc |
| V7 | Firestore read | Open notes list, roadmap, tasks | Console shows reads for current UID only; app shows same docs | app shows only seeded defaults despite console having docs |
| V8 | Firestore update | Toggle a task, edit a note | `[Firestore] updateTask` no error; doc field flips in console | lastError + rollback (T02 behavior) |
| V9 | Firestore delete | Delete a task, delete a note | `[Firestore] deleteTask`/`deleteNote` no error; doc gone in console | lastError + item restored |
| V10 | Rules enforcement (negative) | With a second signed-in Google account, attempt to read the first account's `users/<first-uid>/notes` (via console rules playground or short script) | Playwright/rules-tab simulator with `auth.uid = second` returns DENIED for `users/<first-uid>` **and** is ALLOWED for `users/<second-uid>` | rule missing → data cross-readable = security failure |
| V11 | Storage upload | Use note attachment flow (or a future dedicated screen) | `[Storage] Uploaded successfully to <path>`; console shows object under `notes/<real-uid>/`; download URL opens | `mock-bucket` URL in output = mock fallback, NOT success |
| V12 | Storage size/type limits | Upload >10 MB or disallowed MIME | denied by `isValidSize()`/`isValidImageOrPdf()` | upload succeeds = rule gap |
| V13 | Analytics | Trigger 2-3 events (task create, note create, course_view — note `course_view` currently fires from a build-time getter, see §2.6 note in audit) | Firebase Console → Analytics → DebugView shows events within seconds with sanitized params | DebugView empty = not live |
| V14 | PII filtering (negative) | Pass a fake `user_name` param through a test event before it ships | key absent from DebugView payload | key present = filter broken |
| V15 | Crashlytics | Deliberate synchronous `throw` in debug or use `CrashlyticsService().recordError(...)` manually | Console → Crashlytics shows event within minutes | Console empty after 15 min |
| V16 | Remote Config | Console → Remote Config → set `maintenance_mode = true` → fetch/activate from app | next `isMaintenanceMode` getter returns true; log shows `fetchAndActivate: updated = true` | stale defaults = not live |

---

## 7. Minimal implementation tasks, ordered by dependency

Ordered so nothing depends on an unfinished upstream step. T03+ implementation only; nothing below is done in this audit.

| # | Task | Depends on | Acceptance criteria | Evidence required |
|---|---|---|---|---|
| M1 | User drops real `google-services.json` at `android/app/google-services.json` | §4.1 steps 1-2 | Plugin accepts it; `flutter build apk --debug` exits 0 | CLI copy-paste of `√ Built build\app\outputs\flutter-apk\app-debug.apk` and exit code |
| M2 | Deploy rules (§5 CLI or Console paste-in) | M1 | Rules visible deployed in Console, matching repo files | screenshot or `firebase deploy` log |
| M3 | Register debug SHA-1 + enable Google auth (§4.2) | M1 | Sign-in flow V3/V4/V5 pass on device | logcat lines + device recording |
| M4 | Seed Firestore (seed catalogs) | M2 | Roadmap screen shows data not identical to hardcoded defaults | screenshot + console doc listing |
| M5 | Instrument **mock-vs-real mode visibility** | M1 | One of: a developer-facing banner/`bool isMockMode` surfaced in the tree, **or** a `debugPrint` at the confluence in `main.dart` bubbling mode up to `App` so any screenshot shows it; **must be recordable in a single frame** | code diff + one screenshot showing the indicator; a passing unit assertion guarding it |
| M6 | Walk V1-V16 verification matrix device-side | M1-M4 | Every row above has evidence written into this doc or a verification log | verification log file |

Not in scope for T03 (explicitly deferred): PDF export, FCM/push `notifications` collection
& rules, ARTEMIS AI review task, `sync_vault_screen` View-direct-call refactor, release-build
`INTERNET` manifest fix (belongs to a release checklist task).

---

## 8. Verdict

Code-level readiness: **the Firebase layer is structurally complete and testable in mock mode**;
auth/DI, rules content, service implementations, and tests all line up. Runtime readiness: **0%
verified** — every row in §6 awaits the single external manual action (`google-services.json`
delivery, §4.1) plus one deployment step (§5) and one device session (§6). The audit does not
retroactively upgrade any of these claims; the acceptance evidence column is what will, when
filled.
