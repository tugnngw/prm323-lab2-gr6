# T03-M5B — Firestore Database Provisioning Preparation

**Date:** 2026-11-01  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Android Package:** `com.example.prm323_lab3`  
**Firestore Database Region:** `asia-southeast1` (Singapore) — approved, but database creation separate task.  
**Safety Status:** READ-ONLY AUDIT COMPLETE — Zero Cloud Resources Mutated  

---

## 1. Executive Summary & Verdict

| Checklist Item | Verdict | Evidence |
|---|:---:|---|
| **Firestore Database Uninitialized** | TRUE | `firebaserules.googleapis.com` returns 0 releases; `firestore.googleapis.com` HTTP 403 `SERVICE_DISABLED` |
| **Local Rules File Valid** | TRUE | `firebase/firestore.rules` 71 lines, syntax-valid, complete owner isolation |
| **Catalog Data Seeding Required** | TRUE | `roadmap_viewmodel.dart` requires `courses` collection (`PRM323`, `SWP391`, `SWR302`) for startup |
| **Firestore Rules Compatible** | TRUE | All read/write paths in code (`users/{uid}/tasks`, `users/{uid}/notes`, `courses`) match `firestore.rules` scope |
| **Region Decision Immutable** | TRUE | `asia-southeast1` (Singapore) approved — location locked after creation |
| **Billing: Spark Confirmed** | TRUE | `cloudbilling.googleapis.com` reports `billingEnabled: false` |
| **Storage Provisioning** | DEFERRED | Not in scope for this task |

**Final Status:** **READY FOR MANUAL FIRESTORE CREATION**  
**VERDICT:** Do not claim Firestore is connected until a real runtime read/write succeeds.

---

## 2. Pre-Provisioning Audit Results

### 2.1 Current Infrastructure State (Authoritative)

| Component | Local State | Cloud State | Classification |
|---|---|---|:---:|
| **`firebase.json`** | `firestore.rules -> firebase/firestore.rules` (line 3) | Rules release registry empty (`/releases/` → `{}`) | Config valid, rules not deployed |
| **`firebase/firestore.rules`** | 71 lines, syntax-valid, complete | 0 deployed releases; no release binding in Cloud | Rules audited, ready for deployment |
| **`firebase/storage.rules`** | 49 lines, syntax-valid | 0 buckets; bucket count = 0 on GCS | Rules audited, Storage unprovisioned |
| **`firebase/seed_data.json`** | 3 courses, 2 sample tasks, 1 sample note | N/A (JSON data file only) | Catalog data awaiting Firestore seed |
| **`firestore.googleapis.com`** | N/A | HTTP 403 `SERVICE_DISABLED` | Cloud Firestore API disabled / no database created |
| **`cloudbilling.googleapis.com`** | N/A | `billingEnabled: false` | Spark free plan confirmed |

### 2.2 Codebase Collection Path Inventory (From Grep across `lib/`)

All Firestore operations target **default database** (`(default)`) with paths relative to user UID:

| Code Reference | Collection Path | Subcollection Pattern | Purpose |
|---|---|---|---|
| `firebase_firestore_service.dart:33` | `collection('courses')` | — | Academic catalog read by all authenticated students |
| `firebase_firestore_service.dart:65` | `collection('users').doc(userId)` | — | User profile document |
| `firebase_firestore_service.dart:82-84` | `collection('users').doc(userId).collection('tasks')` | Single-level | Student task management |
| `firebase_firestore_service.dart:157-161` | `collection('users').doc(userId).collection('notes')` | Single-level | Student notes store |
| `firebase_firestore_service.dart:216-217` | `collection('users').doc(userId).collection('sync')` | Single-level | Report metadata / PDF export storage |
| `firebase_firestore_service.dart:237-238` | `collection('users').doc(userId).collection('notifications')` | Single-level | Push notification center |
| `firebase_firestore_service.dart:43` | `collection('users').doc(userId).collection('tokens')` | Single-level | FCM device tokens (T12) |

---

## 3. Firestore Collection & Index Requirements

### 3.1 Query Index Analysis (from `orderBy` calls in `firebase_firestore_service.dart`)

| Query Path | `orderBy` Field | Index Type |
|---|---|---|
| `collection('courses').orderBy('semester')` | `semester` | Single-field index (automatic, always available) |
| `collection('users/{uid}/tasks').orderBy('dueDate', descending: false)` | `dueDate` | Single-field subcollection index (automatic) |
| `collection('users/{uid}/notes').orderBy('updatedAt', descending: true)` | `updatedAt` | Single-field subcollection index (automatic) |
| `collection('users/{uid}/notifications').orderBy('receivedAt', descending: true).limit(50)` | `receivedAt` | Single-field subcollection index (automatic) |

**Finding:** All queries use **single-field ordering** which requires only automatic default indexes. No composite indexes need manual creation. All indexing requirements self-resolve at database creation time.

### 3.2 Catalog Seed Data Requirements

The `firebase/seed_data.json` contains 3 course documents required for `roadmap_viewmodel.dart` to display the academic roadmap on app startup (empty collection → empty state UI).

**Required seeding documents (exact match):**

1. **Document ID:** `PRM323`
   - Fields: `code` (string): `PRM323`, `name` (string): `Mobile Programming with Flutter`, `credits` (number): `3`, `semester` (number): `5`, `major` (string): `SE`, `prerequisites` (array): `["CSD201", "PRO192"]`.

2. **Document ID:** `SWP391`
   - Fields: `code` (string): `SWP391`, `name` (string): `Software Development Project`, `credits` (number): `5`, `semester` (number): `5`, `major` (string): `SE`, `prerequisites` (array): `["SWT301", "SWE201c"]`.

3. **Document ID:** `SWR302`
   - Fields: `code` (string): `SWR302`, `name` (string): `Software Requirement`, `credits` (number): `3`, `semester` (number): `5`, `major` (string): `SE`, `prerequisites` (array): `["CSD201"]`.

**Note:** All other data (tasks, notes, notifications, sync metadata) must be created on-demand by the application under `users/{uid}`. Manual seeding of user-specific data in Console is discouraged.

---

## 4. Manual Firestore Console Provisioning Steps

The project owner must execute the following steps in Firebase Console.

> ⚠️ **CRITICAL:** The selected database location cannot be changed after creation.

### Step 1: Open Firestore Console
1. Open browser and sign in to [Firebase Console](https://console.firebase.google.com/).
2. Select project **`prm323-lab2-gr6`**.
3. In the left navigation menu, click **Build** -> **Firestore Database**.

### Step 2: Create Database
1. Click **Create database** button.
2. **Database ID:** Keep `(default)`.
3. **Database type:** Select **Native mode** (Firestore).
4. **Location:** Select **`asia-southeast1`** from the dropdown (Singapore). This is the approved region.
5. Click **Enable**.

6. Wait 60–90 seconds for the database to fully provision.

### Step 3: Verify Database Created
1. In Firestore Console, confirm the database status shows **Active**.
2. The database should appear under **Firestore Database** with location label **`asia-southeast1`**.

### Step 4: Deploy Security Rules (CLI Method)
Once the database is active:

1. Open a terminal in the project root (`G:\FPT\Semester8\PRM\Lab3\prm323-lab2-gr6`).
2. Execute the deployment command:

   ```bash
   npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
   ```

3. Expected output (excerpt):
   ```
   ✔  deploying firestore:rules
   [prm323-lab2-gr6]  Updating Cloud Firestore rules...
   ✔  firestore:rules deployed successfully.
   ```

4. Verify published rules via:
   ```bash
   npx firebase-tools firestore:rules:get --project prm323-lab2-gr6
   ```
   Expected output must exactly match the 71-line contents of `firebase/firestore.rules` (starting with `rules_version = '2'` and including all `match /databases/{database}/documents` blocks).

---

## 5. Region Decision — Irreversible

| Chosen Region | Rationale | Immutability |
|---|---|---|
| **`asia-southeast1` (Singapore)** | Lowest network latency from Vietnam (FPT campuses ~30-40 ms); matches Firestore location in T03-M4 runbook. | **FINAL.** Google Cloud permanently assigns the database region upon creation. Do not select another region. |

> 🚫 **Do not choose:** `us-central1`, `europe-west1`, `asia-east1`, or any other region. Choosing incorrectly requires destroying and recreating the entire Firebase project.

---

## 6. Rules Deployment Preparation

### 6.1 Preconditions (Must Be Verified Before Executing CLI)
- [ ] Firestore database is active and visible in Firebase Console.
- [ ] Database location is confirmed as `asia-southeast1`.
- [ ] `google-services.json` has been refreshed with 3 OAuth clients (completed in T03-M5A).
- [ ] `flutter analyze` passes (0 issues).
- [ ] Project is on `main` branch; no uncommitted code changes.

### 6.2 CLI Deployment Command (Run from Project Root)
```bash
npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
```

### 6.3 Expected Output
```
✔  deploying firestore:rules
[prm323-lab2-gr6]  Updating Cloud Firestore rules...
✔  firestore:rules deployed successfully.
```

### 6.4 Post-Deployment Verification
1. Rules published successfully.
2. Query Firestore rules via CLI:
   ```bash
   npx firebase-tools firestore:rules:get --project prm323-lab2-gr6
   ```
3. Compare output against `firebase/firestore.rules` 71-line content.

### 6.5 Rollback / Recovery
- Emergency default-deny ruleset can be deployed immediately:
  ```text
  rules_version = '2';
  service cloud.firestore { match /{document=**} { allow read, write: if false; } }
  ```
  Deploy via:
  ```bash
  echo "rules_version = '2'; service cloud.firestore { match /{document=**} { allow read, write: if false; } }" > firebase/firestore.rules && npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
  ```

---

## 7. Verification Checklist (After Manual Execution)

| Item | Verification Command / Evidence | Status |
|---|---|:---:|
| **Firestore Database Active** | Visible in Firebase Console under **Build** -> **Firestore Database** | |
| **Database Location** | Console shows `asia-southeast1` | |
| **Rules Published** | `npx firebase-tools firestore:rules:get` returns 71-line content matching `firebase/firestore.rules` | |
| **Catalog Data Seeded** | 3 documents (`PRM323`, `SWP391`, `SWR302`) present under `courses` collection | |
| **Code Compiles** | `flutter analyze` passes with 0 issues | |
| **APK Builds** | `flutter build apk --debug` succeeds | |

---

## 8. Risks & Rollback Considerations

| Risk | Severity | Mitigation |
|---|:---:|---|
| **Wrong Region Selected** | **CRITICAL (Project-level)** | Once `asia-southeast1` is chosen, location is immutable. If wrong region chosen, destroy project and start fresh. |
| **Rules Deployment Fails** | MEDIUM | Emergency default-deny ruleset can be deployed immediately via CLI as shown in §6.5. |
| **Unauthorized Writes Before Rules Deployed** | LOW | Until rules are published, Firestore returns `PERMISSION_DENIED` on all reads/writes — code gracefully handles this (see `BaseViewModel` loading state). |
| **Billing Upgrade Prompt** | LOW | Project on Spark plan only. No Blaze upgrade required; default-deny rules enforce strict boundaries. |
| **Data Loss from Improper Rollback** | LOW | Emergency ruleset above disables all access temporarily; data remains intact under new rules. |

---

## 9. Exact Next Action for Project Owner

1. **Execute Firestore Console Steps** (Section 4) to create the database in `asia-southeast1`.
2. **Execute CLI Rules Deployment** (Section 6.2) once database is active:
   ```bash
   npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
   ```
3. **Seed Catalog Data** (optional, manual Console) — add 3 course documents under `courses` collection if immediate roadmap display is required.
4. **Notify the assistant** once the database is active and rules deployed to trigger runtime verification (`flutter run` on Android device, test Firestore read/write roundtrip).