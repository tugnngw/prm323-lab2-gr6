# T03-M11E — Legacy Task Document Compatibility Fix

**Date:** 2026-11-01
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)
**Safety Status:** CODE MODIFICATION — Backward-compatible read/write only; no Firestore Rules changes, no document deletions, no catalog seeding, no git staging/commit/push.

---

## 1. Problem Summary

Two document formats coexist in Firestore after the T03-M11D `addTask` fix:

| Format | Created By | Firestore Document ID | `id` field in data |
|---|---|---|---|
| **Legacy** | Old `addTask` using `.add()` | Auto-generated random (e.g., `vZthvbmPGB6g6JfQLqyV`) | `task_1793537224663` (app-generated) |
| **New** | New `addTask` using `.doc(id).set(merge: true)` | App-generated `task_<timestamp>` (matches model) | `task_<timestamp>` (matches Firestore doc ID) |

### 1.1 Legacy read path issue

When `getTasks` reads a legacy document:

- `snapshot.id` = auto-ID (e.g., `vZthvbmPGB6g6JfQLqyV`)
- `doc.data()['id']` = `task_1793537224663` (app-generated)
- Dart map spread `...doc.data()` overwrites explicit `'id': doc.id` with `doc.data()['id']`
- **Result:** model `id` = `task_1793537224663`, but Firestore document ID = `vZthvbmPGB6g6JfQLqyV`
- **Consequence:** `updateTask`/`deleteTask` target wrong path → `FirebaseException(code: not-found)`

### 1.2 Notes comparison

Notes **do not** have this issue because `saveNote` always uses `.doc(noteId).set(..., SetOptions(merge: true))` when `noteId` is provided — same pattern as T03-M11D fix. Notes were already consistent; tasks were the problematic one.

---

## 2. Root Cause: `getTasks` Map Spread Overwrites Canonical ID

**Bug location:** `lib/services/firebase_firestore_service.dart:107`

Original code:
```dart
final result = <String, dynamic>{
  'id': taskId,
  if (dataId != null && dataId != firestoreId) 'legacyId': dataId,
}..addAll(data);
```

**Dart map semantics:** `addAll` later entries overwrite earlier ones. Since `data` contains `id: dataId`, the spread overwrites the explicitly set `'id': taskId` with `dataId`.

| Document type | `data['id']` | `doc.id` | `result['id']` after `addAll(data)` | Effect |
|---|---|---|---|---|
| **Legacy** (old `.add()`) | `task_1793537224663` | `vZthvbmPGB6g6JfQLqyV` | `task_1793537224663` ❌ | `updateTask` targets wrong path → `not-found` |
| **New** (`.doc(id).set()`) | `task_<ts>` | `task_<ts>` | `task_<ts>` ✅ (coincidentally same) | Appears to work |

**Failure chain:**
1. Create (legacy): `addTask` uses `.add()` → Firestore doc gets auto-ID; `TaskModel.toMap()` includes `'id': 'task_1793537224663'` — both coexist
2. Read: `getTasks()` maps `snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()})`; Dart map spread overwrites `id` with `data['id']` = `task_1793537224663`; model `id` = `task_1793537224663`, Firestore doc ID = `vZthvbmPGB6g6JfQLqyV`
3. Update/Delete: `editTask`/`deleteTask` uses model `id` = `task_1793537224663` as Firestore path → `users/{uid}/tasks/task_1793537224663` → document not found → `FirebaseException(code: not-found)`

---

## 3. Fix: Remove `data['id']` from the Map Spread

**Modified** `getTasks` at `lib/services/firebase_firestore_service.dart:108-111`:

```dart
final result = <String, dynamic>{
  'id': taskId,
  if (dataId != null && dataId != firestoreId) 'legacyId': dataId,
}..addAll(data..remove('id'));
```

`data..remove('id')` removes the `id` key from `data` before the spread, so `result['id']` can no longer be overwritten by `data['id']`.

**Behavior after fix:**

| Document type | `result['id']` | `result['legacyId']` | Interpretation |
|---|---|---|---|
| **New doc** | `task_<ts>` | `null` | IDs match; canonical = Firestore doc ID |
| **Legacy doc** | `task_<ts>` (Firestore doc ID) | `task_<ts>` (original) | `legacyId` signals old format; canonical = Firestore doc ID |
| **All operations** | updateTask/deleteTask target `result['id']` | Always correct Firestore doc path | ✅ Works for both formats |

---

## 4. Verification

| Check | Result |
|---|---:|
| `flutter analyze` | ✅ No issues |
| `flutter test test/viewmodels/tasks_notes_test.dart` | ✅ All 14 tests pass |
| `getTasks` `result['id']` = Firestore doc ID | ✅ Confirmed (both formats) |
| `updateTask` on new-format doc | ✅ Succeeds (path matches) |
| `updateTask` on legacy-format doc | ✅ Succeeds (merge into existing doc) |

---

## 5. Constraints Respected

| Constraint | Status |
|---|---|
| **No Firestore Rules modification** | ✅ Rules file left untouched |
| **No document deletions** | ✅ Legacy docs remain; merge writes only |
| **No catalog seeding** | ✅ Unrelated code path |
| **No git staging/commit/push** | ✅ Local changes only |
| **Backward compatible** | ✅ Both formats supported; `legacyId` field distinguishes them |

---

## 6. Files Changed

| File | Change |
|---|---|
| `lib/services/firebase_firestore_service.dart:108-111` | `getTasks`: `..addAll(data)` → `..addAll(data..remove('id'))` to prevent `data['id']` from overwriting canonical `id` |
| `docs/t03-m11e-legacy-task-compatibility.md` | This document (created in T03-M11E step) |

### 6.1 No ViewModel changes needed

The ViewModel already uses `result['id']` from `getTasks` output, which is now the canonical Firestore doc ID for both formats. No further changes required.

---

## 7. Summary

**Problem:** `getTasks` map spread `..addAll(data)` overwrote the canonical `id` field with `data['id']`, causing `updateTask`/`deleteTask` to target wrong Firestore document paths on legacy documents (old `.add()`-created tasks), resulting in `FirebaseException(code: not-found)`.

**Fix:** Remove `data['id']` from the map spread via `..remove('id')` before `addAll`. This ensures `result['id']` always = Firestore document ID (canonical), while `result['legacyId']` preserves the original app-generated ID for legacy document detection.

**All operations (getTasks, updateTask, deleteTask) now work correctly on both new and legacy documents** without requiring document deletions or Firestore Rules changes.

**No Firestore Rules changes, no document deletions/migrations, no git staging/commit/push.** The fix is minimal (one line equivalent change) and fully backward-compatible.