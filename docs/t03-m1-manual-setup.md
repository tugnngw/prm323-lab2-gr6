# T03-M1 — Android Firebase Binding (Manual Setup)

**Status:** BLOCKED — real Firebase configuration required
**Date:** 2026-10-29
**Scope:** Manual, user-side, Firebase Console + filesystem only. No repo changes can complete M1.

---

## 1. Current state (this pass, checked without reading contents)

| Check | Result |
|---|---|
| `android/app/google-services.json` | **ABSENT** |
| Gitignore protection for the file | Active (`.gitignore:53`) — do not alter |
| Google Services Gradle Plugin | Applied (`android/app/build.gradle.kts:4`, v4.5.0 in `android/settings.gradle.kts`) — do not disable |
| Android `applicationId` | `com.example.prm323_lab3` (`android/app/build.gradle.kts:11`) |
| Firebase projectId in `lib/firebase_options.dart` | `prm323-lab2-gr6` |
| APK build without the JSON | Guaranteed to fail at `:app:processDebugGoogleServices` — not rerun this pass (latest recorded run: `t02_verification.log`, `BUILD_EXIT=1`) |

Latest Dart-side outcomes (from T03-AUDIT pass, retained — not re-executed here because the
build gate alone is blocked):
- `flutter pub get` exit 0
- `flutter analyze` exit 0 (0 issues)
- `flutter test` exit 0 (25/25)

These are real previously-executed results, not projections; the APK build remains
`BLOCKED — real Firebase configuration required`.

## 2. Manual action (the only thing standing in M1's way)

Done once, in this exact order, with the Firebase account that owns project `prm323-lab2-gr6`:

### 2.1 Register the Android app
1. Open <https://console.firebase.google.com> → select **prm323-lab2-gr6**.
   - If the project does not exist yet or is owned by someone else, stop and obtain the correct
     project first; a mismatched project produces a JSON the Gradle plugin rejects.
2. Project Settings (gear icon) → **General** → *Your apps* card → **Add app** → **Android**.
3. Package name: type **`com.example.prm323_lab3`** — must match `android/app/build.gradle.kts:11`
   byte-for-byte. App nickname: anything (e.g. `prm323-lab3`).
4. **Register app**.

### 2.2 Download and place the JSON
5. On the same screen, **Download google-services.json**.
6. Save it exactly at `<repo>/android/app/google-services.json` (create nothing else; do not
   rename; do not open/commit it).

Before going further, verify the downloaded file is for the right project and package — one of:
- **Without opening it (preferred):** the Gradle plugin itself validates consistency —
  proceeding to §2.3 and getting a green `processDebugGoogleServices` task is the check.
- **To pre-check (inspecting locally is fine; do not print/commit contents):** confirm the file
  contains `"project_info": {"project_id": "prm323-lab2-gr6", ...}` and at least one
  `client` entry with `"client_info": {"android_client_info": {"package_name":
  "com.example.prm323_lab3"}}`. Keys inside are not secrets and are already mirrored publicly in
  `lib/firebase_options.dart`, but the file is still treated as config, not source.

### 2.3 Build
7. From the project root:

```bash
flutter build apk --debug
```

Success criterion: exit 0 with `√ Built build\app\outputs\flutter-apk\app-debug.apk`.

## 3. Verification commands after the JSON lands in place

Run in this order; record every exit code.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

An APK build that exits 0 proves the **build-time binding** only. It does **not** prove any
runtime Firebase roundtrip works — that is M2/M3/V1-V16 territory
([t03-firebase-readiness.md](t03-firebase-readiness.md) §6). Do not report this task as
"Firebase connected" based on a green build.

## 4. Remaining blockers after M1 (unchanged)

1. **Rules deployment** — `firebase/firestore.rules` and `firebase/storage.rules` exist as
   files only; nothing is deployed. M2 territory.
2. **Google Sign-In SHA-1 / OAuth client** — debug keystore fingerprint must be registered in the
   Firebase console for `GoogleSignIn` on a debug-signed APK. M3 territory.
3. **Mock-fallback visibility** — no in-app indicator; the console/debugPrint layer is the only
   signal. M5 territory.
4. **Release builds** — `android/app/src/main/AndroidManifest.xml` has no `INTERNET` permission
   (only `src/debug` and `src/profile` variants do). Debug builds are unaffected; release builds
   need this added in a release-checklist pass.

## 5. What was NOT done (constraints honored)

- No credential file created, faked, or modified.
- `.gitignore` untouched.
- Google Services Gradle Plugin untouched.
- No Firebase Console change attempted on the user's behalf.
- No M2/M3/rule deployment started.
- Nothing committed.

---

## 6. T03-M1-R re-verification pass (2026-10-29)

Attempted to verify the binding after "manual setup". Result: **the JSON is still absent.**

| Check | Result |
|---|---|
| `android/app/google-services.json` | **ABSENT** — confirmed fresh (also searched nearby paths / Downloads; not found anywhere) |
| Gitignore | untouched, still active |
| Gradle plugin | untouched, still applied |

Because the file is missing, none of `flutter pub get` / `analyze` / `test` / `build apk --debug`
were executed in this pass — the brief forbids rerunning the guaranteed-failing build, and the
other three were not requested for a no-change no-config state. Accurate status continues to be:

- `flutter pub get` / `flutter analyze` / `flutter test` — exit 0, **T03-AUDIT pass results retained**
- `flutter build apk --debug` — **`BLOCKED — real Firebase configuration required`**
- JSON vs project `prm323-lab2-gr6` / package `com.example.prm323_lab3` — **validatable only once present**

**Exact remaining manual action (unchanged from §2):** download the real
`google-services.json` from Firebase console for project `prm323-lab2-gr6` (Android app must be
registered with package `com.example.prm323_lab3`) and save it to
`android/app/google-services.json`. Then rerun the four commands and report their exit codes.

**Nothing about M1's state improved between the previous pass and this one; this file §1-§5
remains the source of truth for the blocked state.** *(superseded by §7 — see below)*

---

## 7. T03-M1-FINAL verification pass (2026-10-29) — **M1 PASS**

The real `google-services.json` now exists at `android/app/google-services.json`. Parsed locally
with Node (`JSON.parse`); nothing printed except booleans.

### 7.1 Configuration validation

| Validation | Result |
|---|---|
| File present at expected path | **PASS** |
| `project_info.project_id == prm323-lab2-gr6` | **PASS** |
| ≥1 `client[].client_info.android_client_info.package_name == com.example.prm323_lab3` | **PASS** |
| JSON parses cleanly | **PASS** |

### 7.2 Verification commands (this pass, all newly executed)

| Command | Exit code | Result |
|---|---|---|
| `flutter pub get` | 0 | Resolved ("Got dependencies"; 10 packages have newer versions incompatible with constraints — informational) |
| `flutter analyze` | 0 | No issues found |
| `flutter test` | 0 | 25/25 passed |
| `flutter build apk --debug` | 0 | `√ Built build\app\outputs\flutter-apk\app-debug.apk` (171.5s) |

The APK artifact now contains the real Firebase project binding (values compiled in from
`google-services.json` + `firebase_options.dart`).

### 7.3 Scope of what a green build proves

**Build-time configuration only.** A successful `flutter build apk --debug` with the real JSON
proves the Gradle plugin accepted the file and compiled its values into the APK. It does **not**
prove any of:

- Firebase Authentication / Google Sign-In works at runtime (needs debug SHA-1 registration —
  still a pending Console action, [t03-firebase-readiness.md](t03-firebase-readiness.md) §4.2)
- Firestore read/write actually succeeds against the deployed rules — **the rules in
  `firebase/` are still not deployed** (M2)
- Storage uploads work (M2 + M3 territory)
- Analytics/Crashlytics/Remote Config are actually active (V13-V16, device-side verification)

Runtime roundtrip verification is the M2/M3 + V1–V16 scope, not M1.

### 7.4 M1 acceptance criteria

| Criterion | Status | Evidence |
|---|---|---|
| Real JSON exists at expected path | ✅ | §7.1 |
| Project ID matches | ✅ | §7.1 |
| Android package matches | ✅ | §7.1 |
| All four commands pass | ✅ | §7.2 exit codes |

**Overall M1 status: PASS.**

### 7.5 Remaining blockers (carried forward, all outside M1)

1. **Rules deployment** — `firebase/firestore.rules` / `firebase/storage.rules` as files only (M2)
2. **Debug SHA-1 / Google Sign-In** registration in Console (M3) — needed before V3–V5
3. **Mock-fallback visibility** indicator (M5)
4. Release-build `INTERNET` permission (`android/app/src/main/AndroidManifest.xml`) — release checklist task

Nothing committed in this pass. Git status unchanged except this doc.
