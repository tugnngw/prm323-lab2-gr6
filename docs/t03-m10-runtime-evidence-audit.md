# T03-M10 — Runtime Evidence Audit Report

**Date:** 2026-11-01  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Safety Status:** READ-ONLY AUDIT — No documents created, modified, or deleted. No Firebase Console changes. No code mutations.  
**Final Verdict:** EVIDENCE ASSESSMENT — Several PASS claims in T03-M8 require downgrading; evidence gaps documented.

---

## 1. Audit Scope & Methodology

This audit reviews every PASS/FAIL/BLOCKED claim in T03-M8 (`docs/t03-m8-android-runtime-verification.md`) and evaluates whether each is genuinely supported by runtime evidence, static code inspection, or test framework output — and downgrades unsupported claims accordingly.

### 1.1 Audit Constraints (READ-ONLY)
- ❌ No Firestore document creation, modification, or deletion.
- ❌ No production code or Firebase Rules modifications.
- ❌ No catalog data seeding.
- ❌ No Git staging, commit, or push.
- ❌ No credential or token exposure.
- ❌ No inventing or extrapolating evidence.

### 1.2 Evidence Gap Summary
| Constraint | Impact on Audit |
|---|---|
| **ADB unavailable** (`adb: command not found`) | Cannot execute `adb shell` commands; no network toggle, no screen capture, no direct UI interaction beyond Flutter CLI. |
| **Flutter logs empty** (`flutter logs` timed out; output file empty) | No runtime log lines (debugPrint, error messages, stack traces) available from the emulator session for this audit. |
| **No direct UI automation** | No Appium, Waldo, or Flutter driver tests executed that could programmatically interact with the UI. |
| **Agent claimed manual runtime CRUD** | T03-M8 claimed Task/Note CRUD was verified on the live emulator, but the audit must verify if this claim is evidence-backed or unverified assertion. |

---

## 2. Per-Test Evidence Evaluation

### 2.1 Environment Verification

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---:|
| **emulator-5554 online** | ✅ PASS | ✅ **MAINTAINED PASS** | `flutter devices` output confirmed `emulator-5554` (mobile) • Android 15 (API 35) (emulator) as connected. This is objectively verifiable from CLI output. |
| **App process running** | ✅ PASS | ✅ **MAINTAINED PASS** | Flutter successfully installed and launched the debug APK on the emulator (`flutter run` completed, APK built and installed). |
| **Authenticated session** | ✅ PASS | ⚠️ **MAINTAINED with note** | The app was reported to display the authenticated `HomeScreen` per the task context ("Current emulator is displaying the authenticated Home screen"). However, no UID values or sign-in timestamps were printed or verified. This is a contextual report, not a directly observed runtime measurement. |

### 2.2 Authentication

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---|---|
| **FirebaseAuth.currentUser non-null** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | No code executed in this audit session could inspect `FirebaseAuth.currentUser` and verify the UID is non-null. The original T03-M8 claim was based on the task context stating the app shows an authenticated Home screen, but no actual inspection was possible in this read-only audit. |
| **UID propagation** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same constraint — no runtime inspection of `currentUserId` across ViewModels was possible. The original claim relied on task context, not audit-session evidence. |
| **Firebase ID token obtainable** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | No token retrieval or inspection possible without ADB or explicit auth UI interaction (both unavailable). |
| **Google Sign-In completed** | ✅ PASS | ➡️ **MAINTAINED as CONTEXTUAL** | The task context stated: "Google Sign-In has already been completed manually." This is a task-level fact, not an audit-session verification. The audit maintains this as a contextual report but marks it as unverified within this session. |

### 2.3 Firestore CRUD — Tasks

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---|---|
| **Create task** `T03_M8_TEST_task_001` | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | The original T03-M8 report claimed "Task successfully written to Firestore under `users/{uid}/tasks/T03_M8_TEST_task_001`" and "UI refreshed to show new task." However, the audit session had no means to: (a) actually interact with the emulator UI, (b) read back Firestore document paths, or (c) observe create operation logs. The `flutter test` suite (20/20 passing) exercises hermetic mocks, not live Firestore writes. |
| **Read task** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | No runtime read verification possible. The original claim of "Task list UI displays the created task" cannot be evidenced without UI automation or log capture. |
| **Update task** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same — no UI interaction or document path verification possible. |
| **Delete task** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same — no UI interaction or document path verification possible. |
| **Task CRUD Summary** | All ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | All four sub-tests downgraded. |

### 2.4 Firestore CRUD — Notes

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---|---|
| **Create note** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same constraint as Tasks — no UI interaction, no document path verification, no log capture possible in this audit session. |
| **Read note** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Update note** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Delete note** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Notes CRUD Summary** | All ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | All four sub-tests downgraded. |

### 2.5 Security Verification

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---|---|
| **UID-scoped queries** | ✅ PASS | ➡️ **MAINTAINED as CODE AUDIT** | This claim is properly supported by static code inspection: the deployed `firebase/firestore.rules` (71 lines, `isOwner(userId)` on all `users/{uid}/subcollections`) and the code in `firebase_firestore_service.dart` all pass the authenticated `uid` as the parent subcollection key. This is a **code audit result**, not a runtime test result — but it is genuinely supported by evidence (the rules file and source code). The audit maintains this as PASS but reclassified as "Code Audit" not "Runtime Verification." |
| **Unauthenticated write rejection** | ⚠️ BLOCKED | ✅ **MAINTAINED BLOCKED** | Per audit constraints: "Do not sign out the current user or alter existing account data." This is correctly blocked. No runtime test was executed, and the audit correctly maintains BLOCKED status. |
| **Cross-account UID isolation** | ⚠️ BLOCKED | ✅ **MAINTAINED BLOCKED** | Only one Google Account available on the emulator; second account unavailable. The audit correctly maintains BLOCKED status. |

### 2.5 Offline Persistence

| Claim | Original T03-M8 Status | Audit Assessment | Evidence |
|---|---|---|---|
| **Offline read behavior** | ⚠️ LIMITED | ⬇️ **DOWNGRADED to NOT TESTED** | No network toggle capability (no `adb`, no system settings access). The original T03-M8 report marked this ⚠️ LIMITED; the audit correctly downgrades to NOT TESTED since the enabling conditions cannot be met. |
| **Reconnect synchronization** | ⚠️ LIMITED | ⬇️ **DOWNGRADED to NOT TESTED** | Same constraint. |
| **Local cache integrity** | ✅ CONFIRMED | ➡️ **MAINTAINED as CODE AUDIT** | The app's fail-loud architecture (no mock fallbacks, `FirebaseConfigErrorApp` blocking error, `FirebaseStorageService` throwing `StateError` if uninitialized) is supported by code inspection. This is maintained as CONFIRMED but reclassified as "Code Audit" not "Runtime Verification." |

---

## 3. UID Isolation Assessment

### 3.1 Cross-User Isolation — How Was It Verified?
**Answer: It was not verified through runtime two-account testing.**

The original T03-M8 report stated: "Cross-account UID isolation is a separate test if a second account is unavailable" and marked it ⚠️ BLOCKED. The audit confirms this was the correct assessment.

**Evidence available:**
- Only one Google Account was on the emulator.
- No second account could be added or switched within this session.
- No `adb` or UI automation to simulate multiple users.
- The static rules audit (T03-M7) confirmed that `firebase/firestore.rules` enforces `isOwner(userId)` on all `users/{uid}/subcollections`, which would isolate users at the rules level — but this is a **static rules audit**, not a runtime two-account test.

**Conclusion:** Cross-account UID isolation has **NOT been runtime-confirmed**. It is supported at the **rules code level** (deployed `firebase/firestore.rules` enforce `isOwner(userId)`), but the audit correctly marks runtime isolation as BLOCKED.

---

## 4. Reconciliation of Inconsistencies

| Inconsistency | Resolution |
|---|---|
| **ADB unavailable** | The audit cannot execute `adb shell` commands for network toggles, screen capture, or direct UI interaction. All tests that depend on ADB are marked NOT TESTED. |
| **Flutter logs empty** | `flutter logs` timed out; the output file was empty. No debugPrint output, error messages, or runtime logs are available for this audit session. Tests that depend on log evidence are downgraded. |
| **No direct UI automation** | No Flutter driver tests, Appium, or Waldo tests were executed. All CRUD claims that require UI interaction are marked NOT TESTED. |
| **Agent claimed manual runtime CRUD verification** | The original T03-M8 report claimed manual CRUD was executed on the live emulator, but the audit session had no means to verify this. The claim is **not supported by evidence from this audit session**. The appropriate downgrade is NOT TESTED for all individual CRUD sub-tests. |

---

## 5. Downgraded Final Status Matrix

| Test Category | Original T03-M8 Status | Audit (T03-M10) Status | Reason for Downgrade |
|---|---|---:|
| **Environment: Device online** | ✅ PASS | ✅ **MAINTAINED PASS** | CLI `flutter devices` output is objectively verifiable. |
| **Environment: App running** | ✅ PASS | ✅ **MAINTAINED PASS** | `flutter run` completed; APK built and installed. |
| **Environment: Authenticated session** | ✅ PASS | ⚠️ **MAINTAINED as CONTEXTUAL** | Task context reported authenticated Home screen; not audit-session verified. |
| **Authentication: UID non-null** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | No runtime inspection possible in this audit session. |
| **Authentication: UID propagation** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Authentication: Sign-In validity** | ✅ PASS | ➡️ **MAINTAINED as CONTEXTUAL** | Task context: "Google Sign-In has already been completed manually." |
| **Task CRUD: Create** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | No UI interaction or Firestore document verification possible. |
| **Task CRUD: Read** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Task CRUD: Update** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Task CRUD: Delete** | ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Note CRUD: Create/Read/Update/Delete** | All ✅ PASS | ⬇️ **DOWNGRADED to NOT TESTED** | Same. |
| **Security: UID-scoped queries** | ✅ PASS | ➡️ **MAINTAINED as CODE AUDIT** | Supported by static inspection of deployed rules + source code. Reclassified from "Runtime" to "Code Audit." |
| **Security: Unauthenticated write rejection** | ⚠️ BLOCKED | ✅ **MAINTAINED BLOCKED** | Correctly blocked by constraints. |
| **Security: Cross-account isolation** | ⚠️ BLOCKED | ✅ **MAINTAINED BLOCKED** | Only one account on emulator. |
| **Offline Persistence: Local cache** | ✅ CONFIRMED | ➡️ **MAINTAINED as CODE AUDIT** | Supported by code inspection (fail-loud architecture, no mock fallbacks). |
| **Offline Persistence: Full cycle** | ⚠️ LIMITED | ⬇️ **DOWNGRADED to NOT TESTED** | No network toggle capability. |

---

## 5. Final Audit Conclusions

| Assertion | Supported by | Verdict |
|---|---|---|
| **Device online** | `flutter devices` CLI output | ✅ CONFIRMED |
| **App running on emulator** | `flutter run` completion + APK install | ✅ CONFIRMED |
| **Google Sign-In completed (task context)** | Task-level contextual report | ⚠️ CONFIRMED at task level, NOT verified in this audit session |
| **Firestore Rules enforce uid-scoping** | Static inspection of `firebase/firestore.rules` + `firebase_firestore_service.dart` | ✅ CONFIRMED (code audit) |
| **Task CRUD executed on live emulator** | ❌ No evidence from this audit session | ❌ NOT TESTED (no UI automation, no ADB, no log capture) |
| **Note CRUD executed on live emulator** | ❌ No evidence from this audit session | ❌ NOT TESTED |
| **Cross-account UID isolation** | ❌ No two-account runtime test | ❌ BLOCKED (one account only, cannot sign out) |
| **Offline persistence full cycle** | ❌ No network toggle capability | ❌ NOT TESTED |
| **Flutter debug log evidence** | ❌ Empty/logless session | ❌ NOT TESTED |

---

## 6. Recommendations

| Recommendation | Priority |
|---|---:|
| **Re-run T03-M8 with ADB access** | HIGH — enables network toggle, UI inspection, genuine runtime CRUD verification. |
| **Re-run T03-M8 with second Google Account** | HIGH — enables cross-account UID isolation testing. |
| **Retain code-audit-confirmed findings** | MEDIUM — the rules code audit (UID scoping, fail-loud architecture) is genuinely supported and should be preserved in project documentation. |
| **Update T03-M8 report with audit findings** | HIGH — this T03-M10 report should be referenced alongside T03-M8 for honest evidence assessment. |
| **Proceed to catalog seeding** | MEDIUM — after code audits and contextual reports are documented, the project can proceed to manual Firebase Console seeding of the 3 course documents. |

---

## 7. Evidence Hierarchy (What This Audit Can vs. Cannot Support)

| Evidence Type | Status |
|---|---:|
| **CLI output** (`flutter devices`, `flutter run`) | ✅ Supported — objectively verifiable. |
| **Code inspection** (rules file, source) | ✅ Supported — static analysis of deployed rules and implementation. |
| **Task-level contextual reports** | ⚠️ Conditional — reports from the task context are noted but not audit-session verified. |
| **Runtime UI interaction** | ❌ Not supported — no UI automation, no ADB, no screen capture in this session. |
| **Firestore document verification** | ❌ Not supported — no document path reading or create/update/delete observation possible. |
| **Debug log capture** | ❌ Not supported — Flutter logs empty/unavailable in this session. |
| **Two-account runtime testing** | ❌ Not supported — only one Google Account on emulator; cannot sign out. |
| **Offline persistence cycling** | ❌ Not supported — no network toggle capability. |

---

## 8. Final Audit Statement

**T03-M10 does not confirm any runtime CRUD operations, authentication state inspections, or offline persistence tests. The audit can only maintain claims that are objectively verifiable from CLI output (`flutter devices`, `flutter run`) or supported by static code inspection (deployed Firestore rules, fail-loud architecture code). All other claims in the original T03-M8 report are downgraded to NOT TESTED or BLOCKED with explicit justification.

The genuinely supported findings are:
- Device `emulator-5554` is online (API 35, Google Play).
- The app launched and is running on the emulator.
- The deployed Firestore rules (`firebase/firestore.rules`, 71 lines) enforce `isOwner(userId)` on all `users/{uid}/subcollections` — this is a **code audit confirmation**, not a runtime verification.
- The app's fail-loud architecture (no mock fallbacks, `FirebaseConfigErrorApp`, `FirebaseStorageService` throw `StateError`) is supported by code inspection.

All other PASS claims in the original T03-M8 report are downgraded per this evidence assessment. No new evidence was invented; limitations are explicitly documented.

**Sources:**
- `flutter devices` output (emulator-5554 online).
- `flutter run` completion + APK install.
- Static inspection of `firebase/firestore.rules` (71 lines).
- Static inspection of `firebase_firestore_service.dart` (fail-loud architecture).
- Task context reports (Google Sign-In completed manually per task brief).
- `flutter test` results (20/20 passing, hermertic mocks).
- T03-M7 code audit (post-deployment rules verification).
- T03-M8 original report (now audited and findings reconciled).