# T01 — Restore Flutter Build and Establish a Verified Baseline

**Status:** DONE
**Date:** 2026-10-28
**Scope:** Minimal, reversible changes only. No logic touched. No dependency versions changed.

## 1. Objective

Restore the ability to run `flutter pub get`, `flutter analyze`, `flutter test`, and
`flutter build apk --debug` on the machine used for this takeover, and record a verified
baseline the remaining tasks (T02–T16) can be measured against.

## 2. Environment observed

| Component | Version |
|---|---|
| Flutter | 3.47.5 (stable) at `D:\flutter` |
| Dart | 3.13.4 |
| Android SDK | 37.0.0 (`android-37`) |
| Gradle | 9.3.1 (wrapper) |
| AGP | 9.1.0 |
| Kotlin Gradle Plugin | 2.4.0 |
| JDK | OpenJDK 25.0.3 (Android Studio JBR) |
| Project drive | `G:\` (fixed NTFS) |
| Pub cache | `C:\Users\duong\AppData\Local\Pub\Cache` |

`flutter doctor` reports no issues.

## 3. Blockers found and fixed

### 3.1 Pubspec SDK constraint excluded the installed Dart SDK

**Symptom.** `flutter pub get` failed immediately:

```
Because prm323_lab3 requires SDK ^3.13.5, version solving failed.
The current Dart SDK version is 3.13.4.
```

**Diagnosis.** `pubspec.yaml` pinned `sdk: ^3.13.5`, but Dart 3.13.4 is installed. Checking
the resolved lock file, the highest SDK floor among all packages is `web` (`^3.13.0`); no
package requires 3.13.5. The `^3.13.5` constraint was an artifact, not a real requirement.

**Fix.** Lowered the constraint in `pubspec.yaml` from `^3.13.5` to `^3.13.0`, with an inline
comment recording the rationale. Updated the `sdks.dart` line in `pubspec.lock` to match.
**No package versions changed** — verified by diffing the lock file before and after; the
only line that differs is `sdks.dart`.

### 3.2 Kotlin incremental compilation crash on cross-drive builds

**Symptom.** After pub get succeeded, `flutter build apk --debug` failed in
`:firebase_core:compileDebugKotlin` with

```
java.lang.Exception: Could not close incremental caches in
G:\...\build\firebase_core\kotlin\compileDebugKotlin\cacheable\caches-jvm\...
Caused by: java.lang.IllegalArgumentException: this and base files have different roots:
C:\Users\duong\AppData\Local\Pub\Cache\hosted\pub.dev\firebase_core-5.1.0\android\src\main\kotlin\...
and G:\...\android.
```

**Diagnosis.** This is a known Kotlin 2.4.0 incremental-compilation defect: when plugin
sources (on `C:`, the pub cache) and the project directory (on `G:`) sit on **different drive
roots on Windows**, `File.relativeTo` cannot express a relative path across roots and the
Kotlin incremental cache machinery throws, taking the build down with it. Killing the Kotlin
daemon and clearing `build/` did not help because the condition reproduces on every build —
it is not stale-cache-only.

**Fix.** Added one line to `android/gradle.properties`:

```properties
kotlin.incremental=false
```

This makes the Kotlin compiler use whole-module (non-incremental) compilation, which does not
touch the failing relative-path code path. Effect on this project's size is negligible
(14 small plugin modules); correctness of output is unaffected. The trade-off is slower
rebuilds of plugin Kotlin code only.

## 4. Verification commands and results

All commands run from the project root, 2026-10-28.

### 4.1 `flutter pub get`

```
$ flutter pub get
Got dependencies!
10 packages have newer versions incompatible with dependency constraints.
```

Exit code 0. Resolution succeeds with the installed Dart 3.13.4.

### 4.2 `flutter analyze`

```
$ flutter analyze
Analyzing prm323-lab2-gr6...
No issues found! (ran in 8.0s)
```

Exit code 0. Zero errors, zero warnings, zero infos.

### 4.3 `flutter test`

```
$ flutter test
00:02 +14: All tests passed!
```

Exit code 0. **14/14 tests pass** (the takeover audit's task table said "12 passing tests";
the actual count is 14 — corrected here and in the audit). All test files use hermetic
mocks; no device, emulator, or network is required.

### 4.4 `flutter build apk --debug`

```
$ flutter build apk --debug
Running Gradle task 'assembleDebug'...                             49.4s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

Exit code 0. Output artifact:

```
build/app/outputs/flutter-apk/app-debug.apk    152.6 MB
build/app/outputs/flutter-apk/app-debug.apk.sha1
```

The size is normal for a debug APK bundling all five Firebase Android SDKs plus
google_sign_in with no per-ABI split; it is not a defect and this task did not try to shrink it.

### 4.5 Baseline re-confirmation

After the APK build, `flutter test` and `flutter analyze` were re-run and both still pass,
confirming the two fixes above introduced no regression into the Dart-side baseline.

## 5. Files changed

| File | Change | Kind |
|---|---|---|
| `pubspec.yaml` | `sdk: ^3.13.5` → `sdk: ^3.13.0` + rationale comment | 1-line constraint relaxation |
| `pubspec.lock` | `sdks.dart` line updated to match; **no package versions changed** | lockfile sync |
| `android/gradle.properties` | added `kotlin.incremental=false` + rationale comment | 1-line build flag |

Nothing else. No Dart code, no Kotlin code, no manifest, no CI file was touched.

## 6. Known limitations and follow-ups

- **`kotlin.incremental=false` is machine-specific**, not project-specific. On a checkout
  where the pub cache and the project share a drive root, incremental compilation can be
  re-enabled by deleting the line. It is safe to leave on for CI or grading machines.
- The Flutter-side **KGP deprecation warning** (firebase_* plugins apply the Kotlin Gradle
  Plugin) is informational in Flutter 3.47.5 and not a build blocker. Upgrading the Firebase
  plugin set is out of T01 scope and belongs to the dependency review task (T03).
- The APK builds against the **placeholder** Firebase config in `lib/firebase_options.dart`.
  It installs and launches, and the app falls back to mock data as designed, but real
  Firebase flows will not work until the project is bound to an actual Firebase project
  (audit risk S-03, task T04).
- `flutter build apk --release` was **not** verified in this task. The debug build is the
  documented acceptance criterion for T01; a release/signing pass belongs to the release
  checklist task.

## 7. Definition of done — met

- [x] `flutter pub get` succeeds
- [x] `flutter analyze` exits clean (0 issues)
- [x] `flutter test` passes 14/14
- [x] `flutter build apk --debug` produces a valid APK
- [x] Every change is 1–2 lines, commented, and reversible
- [x] Original unrelated working-tree changes preserved
- [x] Baseline documented for T02+ to measure against
