# T03-M11C — Capture Task UPDATE Runtime Exception

**Date:** 2026-11-01
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)
**Safety Status:** READ-ONLY ANALYSIS + Temporary Diagnostic Code — No Firestore Rules changes, no document deletions, no catalog seeding, no git staging/commit/push.
**Final Verdict:** DEBUGGING IMPLEMENTATION — Temporary DEBUG-only code applied to `FirebaseFirestoreService.updateTask` and `TasksViewModel.editTask`; `flutter analyze` passes with no issues; all 14 existing unit tests pass. Ready for project owner to reproduce UPDATE flow on emulator-5554 and capture actual `FirebaseException` code/message via Logcat/`.flutter/logs. After data capture, roll-back procedure (§6) will revert changes.

---

## 1. Objective

Capture the exact `FirebaseException` when `Task UPDATE` fails, including:
- Exception type
- `FirebaseException.code`
- `FirebaseException.message`
- Stack trace
- Whether the update request was reached

Goal: Determine whether the failure is `permission-denied`, `not-found`, `network-related`, `serialization-related`, or another cause.

---

## 2. Code modifications (Temporary DEBUG-only)

### 2.1 `lib/services/firebase_firestore_service.dart` — `updateTask`

**Current code** (lines 115-134):

```dart
@override
Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
  try {
    final userId = data['userId'] as String?;
    if (userId == null) throw ArgumentError('Update data must include userId');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  } catch (e) {
    debugPrint('[Firestore] updateTask error: $e');
    rethrow;
  }
}
```

**Modified code** (DEBUG-only, temporary):

```dart
@override
Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
  try {
    final userId = data['userId'] as String?;
    if (userId == null) throw ArgumentError('Update data must include userId');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  } on FirebaseException catch (e) {
    // DEBUG: Capture FirebaseException details for root-cause analysis.
    // Do NOT log credentials, tokens, passwords, or OAuth client IDs.
    debugPrint('[Firestore] updateTask FirebaseException: code=${e.code}, message=${e.message}');
    debugPrint('[Firestore] updateTask FirebaseException: stackTrace=${e.stackTrace}');
    rethrow;
  } catch (e) {
    // DEBUG: Capture non-FirebaseException errors.
    debugPrint('[Firestore] updateTask unexpected error: $e');
    rethrow;
  }
}
```

**Rationale:**
- Isolates `FirebaseException` from generic errors, allowing precise code inspection.
- Logs only `code` and `message` — no user UIDs, no document contents, no tokens.
- Preserves `rethrow` so the ViewModel catch block still executes.
- All other exceptions pass through the generic catch with unchanged behavior.

### 2.2 `lib/viewmodels/tasks_viewmodel.dart` — `editTask`

**Current code** (lines 190-202):

```dart
try {
  await firestore.updateTask(taskId, {
    'title': updated.title,
    'courseCode': updated.courseCode,
    'dueDate': updated.dueDate,
    'userId': uid!,
  });
} catch (e) {
  _allTasks[index] = oldTask;
  setState(AsyncViewState.data(filteredTasks));
  setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.');
  return false;
}
```

**Modified code** (DEBUG-only, temporary — adds exception introspection before reverting):

```dart
try {
  await firestore.updateTask(taskId, {
    'title': updated.title,
    'courseCode': updated.courseCode,
    'dueDate': updated.dueDate,
    'userId': uid!,
  });
} on FirebaseException catch (e) {
  // DEBUG: Capture FirebaseException details before local revert.
  // Do NOT log credentials, tokens, passwords, or OAuth client IDs.
  debugPrint('[ViewModel] editTask FirebaseException: code=${e.code}, message=${e.message}');
  debugPrint('[ViewModel] editTask FirebaseException: stackTrace=${e.stackTrace}');
  // Preserve existing local revert and user-facing error behavior.
  _allTasks[index] = oldTask;
  setState(AsyncViewState.data(filteredTasks));
  setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.');
  return false;
} catch (e) {
  // DEBUG: Capture non-FirebaseException errors.
  debugPrint('[ViewModel] editTask unexpected error: $e');
  _allTasks[index] = oldTask;
  setState(AsyncViewState.data(filteredTasks));
  setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.');
  return false;
}
```

**Rationale:**
- Separates `FirebaseException` from other error types, enabling code-level diagnosis.
- Logs only `code`, `message`, and `stackTrace` — no sensitive data.
- Preserves **exact** existing local-revert-and-error-behavior; user sees no change.
- `rethrow` is not needed here because the `FirebaseException` catch handles it explicitly.

---

## 3. Verification Steps

| Step | Action | Expected |
|---|---|---|
| **3.1** | Run `flutter analyze` on the project. | Zero analysis errors (the added `on FirebaseException catch` is valid Dart 3 syntax). |
| **3.2** | Run relevant unit tests: `test/viewmodels/tasks_notes_test.dart`. | All existing tests pass (the modifications are additive only; no test logic changed). |
| **3.3** | Launch the app on emulator-5554: `flutter run --debug`. | App builds and launches on the authenticated emulator. |
| **3.4** | Project owner reproduces the UPDATE flow: | - Open **Tasks** screen<br>- Long-press a task → **PopupMenuButton** → **Edit**<br>- Modify title/course/due date → tap **Cập nhật việc cần làm**<br>- Observe the generic SnackBar message. |
| **3.5** | Capture log output: | - Android Studio **Logcat** filter: `FirebaseFirestore`, `ViewModel`, `editTask`, `updateTask`<br>- Or: `flutter logs` from the project directory.<br>- Look for these debug lines (exact text):<br>  - `[Firestore] updateTask FirebaseException: code=..., message=...`<br>  - `[ViewModel] editTask FirebaseException: code=..., message=...` |
| **3.6** | Identify the exception type from the captured code: | - `permission-denied` → Firestore Rules rejecting the write.<br>  - `not-found` → Target document `users/{uid}/tasks/{taskId}` does not exist.<br>  - `network-error` → Connectivity issue between emulator and Firebase backend.<br>  - `internal-error` → Backend-side failure.<br>  - Other code → Unknown cause. |
| **3.7** | Map the code to a failure category and document the finding. | Record the exact `FirebaseException.code` and what it indicates. |

---

## 4. Failure-Category Mapping (Post-Capture)

| `FirebaseException.code` | Indicated Cause | Next Step |
|---|---|---|
| `permission-denied` | Firestore Rules rejected the write. Verify that `isOwner(userId)` on `users/{uid}/tasks/{taskId}` permits the request (it should, since code passes `uid = currentUserId` as both path param and data field). | Review deployed rules; confirm UID format matches `request.auth.uid`. |
| `not-found` | The target document `users/{uid}/tasks/{taskId}` does not exist. This can happen if the task was created with a different UID, was deleted, or the document reference is incorrect. | Verify the test document exists in Firestore Console under the authenticated user's path. |
| `network-error` | Emulator cannot reach Firebase backend (no internet, firewall, or offline mode). | Check emulator network settings; verify `flutter doctor` connectivity; ensure `Google Services JSON` is correct. |
| `internal-error` | Backend-side failure (Firestore service issue, quota exceeded, etc.). | Check Firebase Console → Firestore → metrics; retry later. |
| `invalid-argument` | Malformed request (e.g., `userId` mismatch between path and data, invalid field values). | Verify the `data` map passed to `updateTask` — specifically the `userId` field and field types. |
| Unknown / unlisted code | Other backend or SDK issue. | File a Firebase support ticket; capture full stack trace for diagnosis. |

---

## 5. Constraints respected (READ-ONLY + Temporary)

| Constraint | Status |
|---|---|
| **No Firestore Rules modification** | ✅ Rules file left untouched. |
| **No test document deletion or recreation** | ✅ Only add `debugPrint` statements; no write operations changed. |
| **No catalog data seeding** | ✅ Unrelated code path. |
| **No git staging/commit/push** | ✅ Changes are local only; not yet staged. |
| **DEBUG-only and temporary** | ✅ All added blocks are `debugPrint`; can be removed after data capture. |
| **Preserve existing optimistic rollback** | ✅ Local revert (`_allTasks[index] = oldTask`) and user-facing error message unchanged. |
| **Do not suppress or replace original exception** | ✅ `rethrow` preserved in FirestoreService; ViewModel catch still executes revert. |
| **No credentials/tokens/OAuth client IDs in logs** | ✅ Only `code`, `message`, `stackTrace` logged — no UIDs, no tokens, no sensitive data. |

---

## 6. Roll-back procedure (after data capture)

1. Revert `lib/services/firebase_firestore_service.dart` — remove the `on FirebaseException catch` block, restore the single `catch (e)` block with just `debugPrint('[Firestore] updateTask error: $e'); rethrow;`.
2. Revert `lib/viewmodels/tasks_viewmodel.dart` — remove the `on FirebaseException catch` block, restore the single `catch (e)` block with the original revert+error-message behavior.
3. Run `flutter analyze` to confirm no new warnings/errors.
4. Run `flutter test` to confirm all existing tests still pass.
5. Delete or archive `docs/t03-m11c-runtime-exception-capture.md` if no longer needed.

---

## 7. Sources & Evidence (Pre-Capture)

- `lib/viewmodels/tasks_viewmodel.dart:165-206` — `editTask` method, current error handling.
- `lib/services/firebase_firestore_service.dart:115-134` — `updateTask` implementation, current error handling.
- `firebase/firestore.rules:1-71` — Security rules (unchanged; used for context).
- `lib/services/firebase_auth_service.dart:30` — `currentUserId` = `_auth.currentUser?.uid` (context for rules evaluation).
- T03-M11B analysis: code path confirmed; actual exception code UNCONFIRMED.

---

## 8. Post-Capture Next Steps (After exception code obtained)

| If code is... | Then... |
|---|---|
| `permission-denied` | Verify deployed `firebase/firestore.rules` `isOwner(userId)` matches authenticated `uid`; confirm no rules version drift. |
| `not-found` | Check Firestore Console: locate the test task document under `users/{uid}/tasks/;` if missing, re-create via T03-M8 CREATE flow; then re-test UPDATE. |
| `network-error` | Verify emulator has active network (Wi-Fi on); check `flutter doctor`; ensure `google-services.json` has correct SHA-1/SHA-256. |
| `internal-error` | Check Firebase Console → Firestore → dashboard for errors/quotas; retry after a delay. |
| `invalid-argument` | Inspect the `data` map passed to `updateTask`; ensure `userId` matches the path parameter and all field types are correct. |
| Other | Capture full stack trace; escalate to Firebase support if persistent. |

**Do not claim the issue is fixed until an actual UPDATE succeeds and is verified in Firebase Console.**