# T03-M11B — Task UPDATE Failure Analysis Report

**Date:** 2026-11-01
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)
**Safety Status:** READ-ONLY ANALYSIS — No code modifications, no Firestore changes, no document mutations.
**Final Verdict:** EVIDENCE ASSESSMENT — Root cause requires runtime exception evidence; code-path analysis complete.

---

## 1. Update Call Chain (Exact Method and Flow)

### 1.1 UI Trigger
**File:** `lib/screens/tasks_screen.dart:109-135`
- User taps "Cập nhật việc cần làm" in the bottom sheet (after selecting a task via `PopupMenuButton` → `value == 'edit'`)
- Controllers populated with existing task values: `titleController`, `courseController`, `dateController`
- `vm.editTask(existing.id, title, courseCode, dueDate)` called

### 1.2 ViewModel `editTask`
**File:** `lib/viewmodels/tasks_viewmodel.dart:165-206`
```dart
Future<bool> editTask(
  String taskId, {
  required String title,
  required String courseCode,
  required String dueDate,
}) async {
  final uid = currentUserId;                                                 // ← from AuthService
  if (firestoreService != null && uid == null) {                            // auth check
    setLastError('Bạn chưa đăng nhập — không thể sửa việc cần làm.');
    return false;
  }

  final index = _allTasks.indexWhere((t) => t.id == taskId);                // find local task
  if (index == -1) return false;
  final oldTask = _allTasks[index];
  final updated = oldTask.copyWith(
    title: title,
    courseCode: courseCode,
    dueDate: dueDate,
  );
  _allTasks[index] = updated;                                                 // optimistic UI update
  setState(AsyncViewState.data(filteredTasks));

  final firestore = firestoreService;
  if (firestore != null) {
    try {
      await firestore.updateTask(taskId, {                                    // ← Firestore call
        'title': updated.title,
        'courseCode': updated.courseCode,
        'dueDate': updated.dueDate,
        'userId': uid!,                                                         // ← always included
      });
    } catch (e) {                                                             // ← error handling
      _allTasks[index] = oldTask;                                             // ← revert optimistic UI
      setState(AsyncViewState.data(filteredTasks));
      setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.'); // ← generic message
      return false;
    }
  }
  clearLastError();
  return true;
}
```

### 1.3 FirestoreService `updateTask`
**File:** `lib/services/firebase_firestore_service.dart:116-134`
```dart
Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
  try {
    final userId = data['userId'] as String?;                               // ← extract from data
    if (userId == null) throw ArgumentError('Update data must include userId');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({                                                             // ← Firestore document update
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  } catch (e) {
    debugPrint('[Firestore] updateTask error: $e');                         // ← internal log only
    rethrow;                                                                // ← propagates to ViewModel
  }
}
```

### 1.4 Firestore Security Rules
**File:** `firebase/firestore.rules:1-71`
```
match /users/{userId} {
  match /tasks/{taskId} {
    allow read, write: if isOwner(userId);
  }
}

function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}
```
- **Path:** `users/{userId}/tasks/{taskId}` where `userId` = authenticated user's UID
- **Condition:** `isAuthenticated() && request.auth.uid == userId`
- **Effect:** Write allowed only when the authenticated user's UID matches the path parameter `userId`

### 1.5 Expected Document Path
`users/{authenticatedUid}/tasks/{taskDocumentId}` — the authenticated user's task subcollection.

---

## 2. Expected vs. Actual Behavior

| Step | Expected | Actual (from code analysis) |
|---|---|---|
| **Auth check** | `currentUserId` non-null if user signed in via Google | `currentUserId` = `_auth.currentUser?.uid` from `FirebaseAuthService` (verified in T03-M8) |
| **Local optimistic update** | UI reflects new values immediately | `_allTasks[index] = updated` then `setState` — confirmed code path |
| **Firestore `update()` call** | Document fields updated: title, courseCode, dueDate, userId, updatedAt | `firestore.updateTask(taskId, {title, courseCode, dueDate, userId, updatedAt})` — confirmed code path |
| **Rules evaluation** | Write allowed if `request.auth.uid == userId` (path param) | Rules match; code passes `userId = currentUserId` which should match `request.auth.uid` |
| **Error on failure** | Revert local state + surface specific error | Local revert confirmed; error message is **generic** — original exception swallowed |

---

## 3. Evidence Gaps (Read-Only Constraints)

### 3.1 Actual Exception Code/Message — **UNCONFIRMED**
- The ViewModel catch (`tasks_viewmodel.dart:197-201`) catches the exception as `e` but **does not inspect** `e.code` or `e.message` for the user.
- The FirestoreService catch (`firebase_firestore_service.dart:130-133`) logs `debugPrint('[Firestore] updateTask error: $e')` but only rethrows; the audit session had no way to capture this output from the running emulator.
- **Result:** The actual `FirebaseException` code and message are **not available** in this read-only audit. Marked **UNCONFIRMED**.

### 3.2 Rules Rejection vs. Pre-Runtime Failure — **UNCONFIRMED**
- **Rules rejection possibility:** The `isOwner(userId)` check requires `request.auth.uid == userId`. Since code passes `uid = currentUserId` (authenticated user's UID) as both the path parameter and the data field `userId`, rules should **allow** the write for the authenticated user. However, without runtime evidence, cannot definitively rule out a rules mismatch (e.g., stale deployed rules, UID format issue).
- **Pre-runtime failure possibility:** The `update()` Firestore operation fails if the target document does not exist. If the test task document was somehow removed or the path is incorrect, the update would fail before rules are even evaluated.
- **Result:** Cannot distinguish between rules rejection and pre-runtime failure without capturing the actual exception. Marked **UNCONFIRMED**.

### 3.2.1 Rules Rejection — What Would It Look Like?
If `request.auth.uid != userId` (path parameter), the rules would reject the write, and the Firestore SDK would throw a `FirebaseException` with code `permission-denied`. The error message shown to the user ("Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.") is **not** specific enough to confirm this.

### 3.2.2 Pre-Runtime Failure — What Would It Look Like?
If the document `users/{uid}/tasks/{taskId}` does not exist, Firestore `update()` returns a `FirebaseException` with code `not-found`. Again, the generic user message does not distinguish this.

---

## 4. Does the Existing Document Remain Unchanged?

**Verdict:** **YES — confirmed by code analysis.**

In `tasks_viewmodel.dart:197-199`:
```dart
catch (e) {
  _allTasks[index] = oldTask;     // ← revert to previous value
  setState(AsyncViewState.data(filteredTasks));
  setLastError('...');
  return false;
}
```

The ViewModel explicitly reverts the optimistic UI update (`_allTasks[index] = oldTask`) before returning `false`. This means:
- The local task list always reflects the **pre-edit** state on failure.
- The SnackBar shown in `tasks_screen.dart:126-134` displays `vm.lastError` (the generic message).
- The Firestore document is **never** updated if the write fails, because the `firestore.updateTask()` call never completes successfully.

**Additional confirmation:** The `FirebaseFirestoreService.updateTask()` also has error handling (`catch (e) { debugPrint; rethrow; }`), but since the ViewModel catches the rethrow and reverts local state, the net effect is that no persistent change occurs.

---

## 5. Reconciliation: CREATE Passes but UPDATE Fails

Both `addTask` and `editTask` target the same Firestore path `users/{uid}/tasks/{docId}`. The key differences:

| Operation | `addTask` | `editTask` |
|---|---|---|
| **Firestore method** | `.add()` on collection | `.update()` on specific document |
| **Document existence** | Creates new document (auto-ID) | Requires document to already exist |
| **Included fields** | `createdAt`, `updatedAt`, all task fields | All task fields + `userId` + `updatedAt` |
| **Rules path** | `users/{uid}/tasks/{autoId}` | `users/{uid}/tasks/{specificTaskId}` |

**Possible reason CREATE works but UPDATE fails:**
- `addTask` creates a new document — always succeeds (if rules allow write to `tasks` subcollection).
- `editTask` performs `.update()` on an **existing** document — fails if the document doesn't exist at the expected path.

**However**, T03-M8 confirmed that Task CREATE persisted to Firestore under `users/{uid}/tasks/T03_M8_TEST_task_001`, and the task list UI displayed it. So the document should still exist when UPDATE is attempted later in the same session.

**Alternative reason:** The actual FirebaseException could be caused by:
- Network connectivity interruption between the emulator and Firebase backend.
- Firestore SDK version incompatibility with the backend.
- Rules evaluation edge case not caught in code review.

But **all of these are UNCONFIRMED** without runtime exception evidence.

---

## 6. Key Findings Summary

| Finding | Status | Evidence |
|---|---:|
| **Update call chain identified** | ✅ CONFIRMED | Full trace: UI → `TasksViewModel.editTask` → `FirebaseFirestoreService.updateTask` → Firestore Rules |
| **Expected document path** | ✅ CONFIRMED | `users/{authenticatedUid}/tasks/{taskDocumentId}` |
| **Local state revert on failure** | ✅ CONFIRMED | `_allTasks[index] = oldTask` in ViewModel catch; document unchanged |
| **Error message is generic** | ✅ CONFIRMED | `setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.')` — original exception not exposed |
| **Actual exception code/message** | ❌ UNCONFIRMED | Not available in read-only audit; swallowed by generic message |
| **Rules rejection vs. pre-runtime failure** | ❌ UNCONFIRMED | Cannot distinguish without exception code |
| **Document persists after failed UPDATE** | ✅ CONFIRMED | Local revert ensures task list shows pre-edit state; Firestore write never committed |

---

## 7. Recommendations (Read-Only Documentation Only)

| Recommendation | Priority |
|---|---:|
| **Add exception details to user-visible error** — modify `TasksViewModel.editTask` catch block to include `e.toString()` or `e.message` in `lastError` (or a more specific message) so operators can diagnose failures. | HIGH |
| **Add pre-write document existence check** — optionally verify the task document exists before calling `firestore.updateTask()`, or handle `not-found` code specifically. | MEDIUM |
| **Add rules violation debugging** — temporarily add a `debugPrint` in the catch block to log the FirebaseException code/message, then remove before production. | MEDIUM |
| **Re-run T03-M8 UPDATE flow with ADB access** — capture actual Flutter/log output to identify the specific exception. | HIGH |
| **Do not modify Firestore Rules** — the `isOwner(userId)` logic is correct for authenticated writes; any failure is likely not rules-related. | N/A (constraint) |

---

## 8. Sources & Evidence

- `lib/viewmodels/tasks_viewmodel.dart:165-206` — `editTask` method, call chain, error handling.
- `lib/services/firebase_firestore_service.dart:116-134` — `updateTask` implementation, exception propagation.
- `lib/screens/tasks_screen.dart:109-135` — UI bottom sheet trigger, SnackBar error display.
- `firebase/firestore.rules:1-71` — Security rules, `isOwner(userId)` function, path-based access control.
- `lib/services/firebase_auth_service.dart:30` — `currentUserId` = `_auth.currentUser?.uid`.
- `test/viewmodels/tasks_notes_test.dart` — Unit tests for `addTask`, `toggleTask`, `deleteTask` (Mock/Fake services); **no test for `editTask`**.
- T03-M8 runtime confirmation: Task CREATE confirmed PASS; Task UPDATE failure reported but no exception evidence captured in this audit session.

**Conclusion:** The Task UPDATE failure root cause **cannot be determined** from code analysis alone without runtime exception evidence. The code path is well-defined, the local state revert works correctly, and the error message is intentionally generic. The actual `FirebaseException` code/message is unavailable in this read-only audit session. Known failure modes include: document-not-found (if the task was removed), permission-denied (if rules mismatch), or network error — but none can be confirmed without capturing the actual exception.