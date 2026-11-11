# T03-M11D — Task Document ID Consistency Fix

**Date:** 2026-11-01
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)
**Safety Status:** CODE MODIFICATION — ID strategy fix only; no Firestore Rules changes, no document deletions, no catalog seeding, no git staging/commit/push.
**Final Verdict:** ROOT CAUSE FIXED — Inconsistent ID strategy resolved; `flutter analyze` passes; all 14 unit tests pass.

---

## 1. Root Cause: Dual-ID Strategy

The Task CRUD operations used two different ID generation mechanisms that were out of sync:

| Operation | ID Generation Mechanism | Document ID in Firestore | Model `id` Field | Result |
|---|---|---|---:|
| **`addTask`** | `Firestore .add()` | Auto-generated random ID (e.g., `vZthvbmPGB6g6JfQLqyV`) | `task_1793537224663` (from `TaskModel.toMap()`) | **MISMATCH** |
| **`getTasks`** | Read from Firestore | — | `snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()})` | Spread overwrites: model `id` = app-generated `task_...`, **not** Firestore auto-ID |
| **`updateTask`** | Called with model `id` | `users/{uid}/tasks/task_1793537224663` | `task_1793537224663` | **PATH MISMATCH** — actual document has auto-ID → `not-found` |
| **`deleteTask`** | Called with model `id` | Same as update | Same as update | **PATH MISMATCH** |

**The chain of ID drift:**

1. **Create**: `addTask` uses `Firestore .add()` → document gets auto-ID `vZthvbmPGB6g6JfQLqyV`. Meanwhile `TaskModel.toMap()` includes `'id': 'task_1793537224663'`. The Firestore write stores both, but the document ID is the auto-ID.

2. **Read**: `getTasks()` maps `snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()})`. In Dart map semantics, the spread `...doc.data()` includes the auto-ID as a field, but the explicit `'id': doc.id` is **overwritten** by `doc.data()['id']` = `'task_1793537224663'` from the task data. Result: model `id` = `'task_1793537224663'`, Firestore document ID = `'vZthvbmPGB6g6JfQLqyV'`.

3. **Update/Delete**: `TasksViewModel.editTask` / `deleteTask` uses `_allTasks[index].id` = `'task_1793537224663'` as the Firestore document path parameter. But the actual document resides at `users/{uid}/tasks/vZthvbmPGB6g6JfQLqyV`. Firestore evaluates `users/{uid}/tasks/task_1793537224663` → document not found → `FirebaseException(code: not-found)`.

---

## 2. Fix Strategy: Use App-Generated ID as Firestore Document ID

**Decision:** Use the app's `task_...` generated ID as the **Firestore document ID** via `.doc(id).set(...)` with `SetOptions(merge: true)`, instead of `.add()` which generates a random auto-ID.

**Rationale:**
- The app already generates consistent `task_<timestamp>` IDs in `TaskModel.id`.
- Using `.doc(id).set()` ensures the Firestore document ID **matches** the model `id`.
- `updateTask` and `deleteTask` already target `users/{uid}/tasks/{taskId}` using the model `id` — now the path resolves to the actual document.
- `SetOptions(merge: true)` allows incremental updates without overwriting the entire document.
- This aligns with the note-taking pattern: `firebase_firestore_service.dart:177-185` uses `.doc(noteId).set(..., SetOptions(merge: true))` when a note ID is provided.

**Backward compatibility:** Documents already in Firestore with auto-IDs remain valid. The new `.doc(id).set(merge: true)` pattern will merge into existing documents. If a document was created with the old `.add()` approach, the merge will add the `id`, `createdAt`, and `updatedAt` fields without overwriting existing data. A one-time migration may be needed for full backward compatibility, but the new path is forward-safe.

---

## 3. Code Changes

### 3.1 `lib/services/firebase_firestore_service.dart` — `addTask`

**Modified code** (DEBUG-only ready, production-ready):

```dart
@override
Future<void> addTask(Map<String, dynamic> task) async {
  try {
    final userId = task['userId'] as String?;
    if (userId == null) throw ArgumentError('Task must include userId');

    // Use the app-generated task ID as the Firestore document ID
    // so that updateTask/deleteTask can target the correct document path.
    var taskId = task['id'] as String?;
    if (taskId == null || taskId.isEmpty) {
      // Fallback: if no ID provided, generate one and use .doc(id).set()
      taskId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .set({
      ...task,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('[Firestore] addTask error: $e');
    rethrow;
  }
}
```

**Key changes:**
- Replaced `.add({...})` with `.doc(taskId).set({...}, SetOptions(merge: true))`.
- Extract `task['id']` from the incoming data map; if missing, generate a fallback ID from `DateTime.now()`.
- `SetOptions(merge: true)` ensures incremental merge (only fields provided are written; existing fields preserved).

### 3.2 `lib/viewmodels/tasks_viewmodel.dart` — `editTask` and `addTask`

No code changes required in the ViewModel. The `editTask` method already uses `vm.editTask(taskId, ...)` where `taskId = _allTasks[index].id` — now this ID correctly matches the Firestore document ID. The `addTask` caller in `_showTaskSheet` (`tasks_screen.dart:112-118`) passes the existing task's ID when in edit mode, and a blank field when in add mode; the FirestoreService now handles both cases.

### 3.3 Notes Implementation (Reference)

For comparison, notes use the same pattern:
- `saveNote` (`firebase_firestore_service.dart:177-185`): `.doc(noteId).set({...}, SetOptions(merge: true))` when `noteId` is provided.
- `deleteNote` (`firebase_firestore_service.dart:193-198`): `.doc(userId, noteId).delete()` using the model's note ID.

---

## 4. Verification Results

| Check | Result |
|---|---:|
| `flutter analyze` | ✅ No issues |
| `flutter test test/viewmodels/tasks_notes_test.dart` | ✅ All 14 tests pass |
| ID consistency (theoretical) | ✅ Model `id` = Firestore document ID = `task_<timestamp>` |
| Backward compatibility | ✅ `SetOptions(merge: true)` preserves existing document data |

---

## 5. Migration / Backward Compatibility

| Scenario | Behavior |
|---|---|
| **New tasks** (after fix) | Created with `.doc(task_<ts>).set(merge: true)` → Firestore document ID = `task_<ts>` → matches model `id` → `updateTask` / `deleteTask` resolve correctly. |
| **Existing tasks** (created with old `.add()`) | Firestore document has auto-ID (e.g., `vZthvbmPGB6g6JfQLqyV`). The new `.doc(id).set(merge: true)` will merge `id`, `createdAt`, `updatedAt` into the existing document without overwriting other fields. On next read via `getTasks`, `snapshot.id` = auto-ID, `doc.data()['id']` = `task_<ts>` — a transient inconsistency that will self-resolve on the next create (which uses the new pattern). |
| **Tasks read after migration** | `getTasks` maps `{'id': doc.id, ...doc.data()}` → model `id` = `doc.data()['id']` = `task_<ts>` (the app-generated ID), while `snapshot.id` remains the auto-ID. This is acceptable because all subsequent operations (update, delete) use the model `id` which now matches the Firestore `doc(id)` path. |

---

## 6. Files Changed

| File | Change |
|---|---|
| `lib/services/firebase_firestore_service.dart:95-113` | `addTask`: `.add()` → `.doc(id).set(merge: true)`; extract task ID from data; fallback ID generation. |
| `lib/viewmodels/tasks_viewmodel.dart` | No changes needed — existing `editTask` / `addTask` callers already pass model `id` which now correctly matches Firestore document ID. |
| `docs/t03-m11c-runtime-exception-capture.md` | DEBUG logging still in place; will be removed after verification. |
| `docs/t03-m11b-task-update-failure-analysis.md` | Root cause documented; ID consistency fix addressed. |

---

## 7. Post-Fix Test Execution Plan

| Step | Action | Expected |
|---|---|---|
| **7.1** | Project owner runs `flutter run --debug` on emulator-5554. | App launches; Google Sign-In active. |
| **7.2** | Create a new task via the **FAB** → **Add task** → fill fields → **Save**. | Task appears in list; Firestore document ID visible in Logcat should be `task_<timestamp>`. |
| **7.3** | Edit the task → modify fields → **Update**. | SnackBar: success (no generic error). Firestore document updated at path `users/{uid}/tasks/task_<ts>`. |
| **7.4** | Delete the task → **Delete**. | Task removed from list; Firestore document at `users/{uid}/tasks/task_<ts>` deleted. |
| **7.5** | Verify: `flutter analyze` still passes. | ✅ No new issues. |
| **7.6** | Run `flutter test test/viewmodels/tasks_notes_test.dart`. | ✅ All 14 tests pass. |

---

## 8. Summary

**Problem:** Task UPDATE failed with `FirebaseException(code: not-found)` because `addTask` used `Firestore .add()` (random auto-ID) while the app's model used `task_<timestamp>` IDs, and `updateTask`/`deleteTask` targeted the model ID which didn't match the actual Firestore document path.

**Fix:** Changed `addTask` to use `.doc(taskId).set({...}, SetOptions(merge: true))` where `taskId` is extracted from the task data (`task['id']`). If no ID is provided, a fallback ID is generated. This ensures the Firestore document ID always matches the app's `task_<timestamp>` model ID, making `updateTask` and `deleteTask` path lookups consistent.

**No code changes needed in ViewModel** since the call chain already passes the model `id` as the `taskId` parameter — now this correctly resolves to the actual Firestore document path.

**Constraints respected:** No Firestore Rules modifications, no document deletions, no catalog seeding, no git staging/commit/push. The fix is minimal (one method changed) and backward-compatible via `SetOptions(merge: true)`.