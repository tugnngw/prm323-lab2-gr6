# T03-M4 — Firebase Provisioning Runbook & Manual Execution Guide

**Date:** 2026-10-31  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Target Environment:** Android Mobile Client (Flutter 3.47.5 / Dart 3.13.4 / AGP 9.1.0)  
**Execution Mode:** STRICTLY MANUAL (Runbook prepared for human project owner / admin execution)  
**Safety Status:** READ-ONLY AUDIT COMPLETE — ZERO CLOUD RESOURCES MUTATED  

---

## 1. Executive Summary & Prerequisites

This runbook provides complete, safe, step-by-step instructions for the manual provisioning of Firebase infrastructure for **FPTU Second Brain**. 

As established in `docs/t03-m2-deployment-verification.md` and `docs/t03-m3-firebase-runtime-readiness.md`:
1. The project has zero active cloud rules, uninitialized Firestore, and zero Storage buckets.
2. The Android client configuration (`android/app/google-services.json`) currently contains an empty `oauth_client: []` array, blocking Google Sign-In (`ApiException: 10`).
3. The client codebase adheres strictly to a fail-loud architecture without silent mock fallbacks.

### 1.1 Prerequisites Checklist

Before executing any step in this runbook, verify the following prerequisites:

- [ ] **Access Credentials:** Access to Google account `duongkt.st.2005@gmail.com` with **Owner** or **Editor** role in [Firebase Console](https://console.firebase.google.com/project/prm323-lab2-gr6).
- [ ] **Local Machine:** Windows 11 workstation with Android SDK 37, Java OpenJDK 21, and Android debug keystore.
- [ ] **Firebase CLI:** Node.js environment with `npx firebase-tools@15.34.2` authenticated (`npx firebase-tools login:list`).
- [ ] **Clean Repository State:** Branch `main` with clean working tree.
- [ ] **Android Device / Emulator:** Android device or emulator with Google Play Services (API 34/35) for runtime validation.

---

## 2. Phase 1 — Google Sign-In Provisioning (P0 Blocker)

### 2.1 Technical Context & Fingerprint Data

Google Sign-In on Android requires Firebase Authentication to possess OAuth 2.0 Client IDs tied to the application's package name and signing certificate SHA-1 fingerprint. Without this registration, `google-services.json` omits the `oauth_client` definitions, resulting in runtime failure:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

The authoritatively extracted fingerprints from `C:\Users\duong\.android\debug.keystore`:

| Key Type | Value |
|---|---|
| **Keystore Path** | `C:\Users\duong\.android\debug.keystore` |
| **Keystore Alias** | `androiddebugkey` |
| **Android Package** | `com.example.prm323_lab3` |
| **SHA-1 Fingerprint** | `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A` |
| **SHA-256 Fingerprint** | `58:34:6F:5F:06:D5:9C:0E:B7:6C:87:6B:1F:A5:BC:31:3E:C2:6B:8E:3C:79:8F:56:3C:2A:66:D4:85:BA:98:30` |

### 2.2 Step-by-Step Console Registration

1. **Open Firebase Console:**
   Navigate to [Firebase Console Project Settings](https://console.firebase.google.com/project/prm323-lab2-gr6/settings/general).
2. **Locate Android App:**
   Scroll down to the **Your apps** section and select **FPTU Second Brain** (`com.example.prm323_lab3`).
3. **Register SHA-1 Fingerprint:**
   - Click **Add fingerprint**.
   - Paste the SHA-1 value: `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A`.
   - Click **Save**.
4. **Register SHA-256 Fingerprint:**
   - Click **Add fingerprint** again.
   - Paste the SHA-256 value: `58:34:6F:5F:06:D5:9C:0E:B7:6C:87:6B:1F:A5:BC:31:3E:C2:6B:8E:3C:79:8F:56:3C:2A:66:D4:85:BA:98:30`.
   - Click **Save**.
5. **Enable Google Sign-In Provider:**
   - In the left sidebar, click **Build** -> **Authentication**.
   - Navigate to the **Sign-in method** tab.
   - Under **Additional providers**, click **Google**.
   - Toggle **Enable** to ON.
   - Enter project support email: `duongkt.st.2005@gmail.com`.
   - Click **Save**.
6. **Download Updated Configuration:**
   - Return to **Project Settings** -> **General** -> **Your apps** -> `com.example.prm323_lab3`.
   - Click **Download google-services.json**.
   - Save the file, overwriting the existing `android/app/google-services.json`.

### 2.3 Verification & Validation

Inspect `android/app/google-services.json` using a text editor or CLI to verify the client array:
```json
"oauth_client": [
  {
    "client_id": "510519082861-xxxxxxxxxxxxxxxx.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.prm323_lab3",
      "certificate_hash": "017466e93e54f70e42f66b6bd743956379a9c90a"
    }
  },
  {
    "client_id": "510519082861-yyyyyyyyyyyyyyyy.apps.googleusercontent.com",
    "client_type": 3
  }
]
```
- **Type 1:** Android client bound to the debug certificate hash.
- **Type 3:** Web client ID required for exchanging ID tokens with Firebase Auth.

---

## 3. Phase 2 — Firestore Provisioning & Rules Deployment

### 3.1 Security Rules Analysis (`firebase/firestore.rules`)

The audited rules file (`firebase/firestore.rules`, 71 lines) enforces strict owner isolation and public catalog boundaries:

| Path Pattern | Read Access | Write Access | Constraints & Helpers |
|---|---|---|---|
| `/users/{userId}` | `isOwner(userId)` | `isOwner(userId)` | Profile document (`passedCourses` transcript). |
| `/users/{userId}/tasks/{taskId}` | `isOwner(userId)` | `isOwner(userId)` | Student task management. |
| `/users/{userId}/notes/{noteId}` | `isOwner(userId)` | `isOwner(userId)` | Student academic notes. |
| `/users/{userId}/sync/{syncId}` | `isOwner(userId)` | `isOwner(userId)` | Sync records and PDF report metadata. |
| `/users/{userId}/notifications/{notificationId}` | `isOwner(userId)` | `isOwner(userId)` | Push notification store. |
| `/users/{userId}/tokens/{tokenId}` | `isOwner(userId)` | `isOwner(userId)` | FCM device tokens for push delivery. |
| `/courses/{courseId}` | `isAuthenticated()` | `false` | Public catalog; admin-only writes via Console/Admin SDK. |
| `/curriculums/{curriculumId}` | `isAuthenticated()` | `false` | Curriculum roadmap catalog; admin-only writes. |
| `/audit_logs/{logId}` | `false` | `create` only if `request.resource.data.userId == request.auth.uid` | Append-only audit logs; read/update/delete denied. |
| `/{document=**}` | `false` | `false` | Catch-all default deny. |

### 3.2 Index Requirements

Inspection of `lib/services/firebase_firestore_service.dart` confirms that **no composite indexes are required**:
- `courses` query: `.orderBy('semester')` -> Single-field index (automatic).
- `tasks` query: `.orderBy('dueDate', descending: false)` -> Single-field subcollection index (automatic).
- `notes` query: `.orderBy('updatedAt', descending: true)` -> Single-field subcollection index (automatic).
- `notifications` query: `.orderBy('receivedAt', descending: true).limit(50)` -> Single-field subcollection index (automatic).

All conditional filtering (`isCompleted`, `priority`, `courseCode`, search text) is executed in-memory within ViewModels (`tasks_viewmodel.dart`, `roadmap_viewmodel.dart`). Therefore, Cloud Firestore default single-field indexing fully satisfies all query contracts.

### 3.3 Irreversible Location Decision

> ⚠️ **CRITICAL IRREVERSIBLE DECISION:** The Firestore database location is **permanently locked** upon creation. It cannot be moved, renamed, or changed without destroying the entire database.

- **Recommended Location:** `asia-southeast1` (Singapore)  
  *Rationale:* Provides lowest network latency (~30-40 ms) and optimal throughput from Vietnam (FPT University campuses).
- **Secondary Option:** `asia-east1` (Taiwan)  
  *Rationale:* Low latency alternative (~45-55 ms) if Singapore is restricted.

### 3.4 Step-by-Step Database Creation

1. Navigate to [Firebase Console Firestore Database](https://console.firebase.google.com/project/prm323-lab2-gr6/firestore).
2. Click **Create database**.
3. **Database ID:** Keep `(default)`.
4. **Security Rules:** Select **Start in production mode** (ensures all access is blocked by default until rules are published).
5. **Location:** Select **`asia-southeast1 (Singapore)`** from the dropdown.
6. Click **Enable** and wait 60–90 seconds for database provisioning.

### 3.5 Security Rules Deployment

Deploy the audited local rules using either of the following methods:

#### Method A: Firebase CLI (Recommended)
Execute from project root in terminal:
```bash
npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
```

#### Method B: Firebase Console Editor
1. In Firebase Console, go to **Firestore Database** -> **Rules** tab.
2. Select and delete the default rules.
3. Paste the complete 71 lines from [firebase/firestore.rules](firebase/firestore.rules).
4. Click **Publish**.

### 3.6 Catalog Data Seeding (`firebase/seed_data.json`)

To enable the Academic Roadmap screen without mock fallbacks, seed the `courses` collection:
1. In Firebase Console, go to **Firestore Database** -> **Data** tab.
2. Click **Start collection**.
3. Collection ID: `courses`.
4. Add Document 1:
   - Document ID: `PRM323`
   - Fields:
     - `code` (string): `PRM323`
     - `name` (string): `Mobile Programming with Flutter`
     - `credits` (number): `3`
     - `semester` (number): `5`
     - `major` (string): `SE`
     - `prerequisites` (array of strings): `["CSD201", "PRO192"]`
5. Add Document 2:
   - Document ID: `SWP391`
   - Fields:
     - `code` (string): `SWP391`
     - `name` (string): `Software Development Project`
     - `credits` (number): `5`
     - `semester` (number): `5`
     - `major` (string): `SE`
     - `prerequisites` (array of strings): `["SWT301", "SWE201c"]`
6. Add Document 3:
   - Document ID: `SWR302`
   - Fields:
     - `code` (string): `SWR302`
     - `name` (string): `Software Requirement`
     - `credits` (number): `3`
     - `semester` (number): `5`
     - `major` (string): `SE`
     - `prerequisites` (array of strings): `["CSD201"]`

*(Note: User-specific data such as tasks, notes, and notifications must NOT be manually created in Console; they are created on-demand by the application under `users/{uid}`).*

---

## 4. Phase 3 — Storage Provisioning & Spark/Blaze Evaluation

### 4.1 Client Fail-Loud Architecture

`FirebaseStorageService` (`lib/services/firebase_storage_service.dart`) enforces a strict fail-loud policy:
```dart
FirebaseStorage get _client {
  final client = _storage;
  if (client == null) {
    throw StateError(
        'Cloud Storage chưa được khởi tạo (thiếu google-services.json / '
        'Firebase.initializeApp thất bại). Từ chối trả về URL giả lập.');
  }
  return client;
}
```
If Cloud Storage is not initialized in the backend, attempting to upload note attachments or export PDF reports surfaces a clear error banner (`Cloud Storage chưa sẵn sàng — không thể đính kèm tệp.`) and gracefully cancels the operation without application crashes.

### 4.2 Security Rules Analysis (`firebase/storage.rules`)

The audited rules file (`firebase/storage.rules`, 49 lines) enforces:

| Path Pattern | Read Access | Write Access | Constraints |
|---|---|---|---|
| `/notes/{userId}/{allPaths=**}` | `isOwner(userId)` | `isOwner(userId)` | Size < 10 MB; MIME: `image/*`, `application/pdf`, `text/plain`. |
| `/reports/{userId}/{allPaths=**}` | `isOwner(userId)` | `isOwner(userId)` | Size < 10 MB; MIME: `application/pdf` only. |
| `/{allPaths=**}` | `false` | `false` | Catch-all default deny. |

### 4.3 Spark Plan vs. Blaze Plan Cost Analysis

| Attribute | Spark Plan (Free) | Blaze Plan (Pay-as-you-go) |
|---|---|---|
| **Monthly Cost** | **$0.00 / month** | **$0.00 / month** (within free tier) |
| **Credit Card Required** | No | Yes (Required for activation) |
| **Storage Capacity** | 5 GB total stored data | 5 GB free tier, then $0.026/GB |
| **Download Bandwidth** | 1 GB / day | 1 GB/day free, then $0.12/GB |
| **Upload Operations** | 20,000 / day | 20,000/day free, then $0.05/10k |
| **Download Operations** | 50,000 / day | 50,000/day free, then $0.004/10k |
| **Provisioning Blocker** | Google Cloud Console frequently blocks bucket creation on Spark without billing verification. | Bucket creation succeeds immediately. |
| **Financial Risk** | **Zero financial risk** (hard limit cut-off). | **Potential risk** of charges if runaway loops or large uploads occur. |

### 4.4 Team Decision Framework

The project owner and team must decide between three paths:

- **Path A (Attempt Spark Bucket Creation — Recommended First):**
  Attempt to click **Get started** in Firebase Console -> Storage on the Spark plan. If Google allows bucket creation without billing prompt, proceed with Spark.
- **Path B (Blaze Plan with Strict Budget Safeguard):**
  If Spark blocks bucket creation and Storage is deemed mandatory by course rubric:
  1. Upgrade project to Blaze plan with project owner's card.
  2. **MANDATORY SAFEGUARD:** Immediately create a Google Cloud Budget with a **$1.00 USD monthly budget cap** and email alerts at 50% ($0.50) and 90% ($0.90) to prevent any unexpected charges.
- **Path C (Defer Cloud Storage):**
  If Blaze plan is rejected, do not initialize Storage. Firestore, Authentication, Analytics, Remote Config, and FCM function normally. Note attachments and PDF export will safely display error messages without breaking the rest of the application.

### 4.5 Step-by-Step Storage Creation (If Approved)

1. Navigate to [Firebase Console Storage](https://console.firebase.google.com/project/prm323-lab2-gr6/storage).
2. Click **Get started**.
3. **Security Rules:** Select **Start in production mode**.
4. **Cloud Storage Location:** Select `asia-southeast1` (matching Firestore).
5. Click **Done**.
6. **Deploy Rules:**
   - In Storage, select the **Rules** tab.
   - Paste the contents of [firebase/storage.rules](firebase/storage.rules).
   - Click **Publish**.
   - *(Or via CLI: `npx firebase-tools deploy --only storage:rules --project prm323-lab2-gr6`)*.

---

## 5. Phase 4 — Authentication Scope & Requirements Evaluation

### 5.1 Repository & Codebase Audit

An audit of the entire codebase and specification documentation reveals:
1. `lib/services/auth_service.dart` defines only `signInWithGoogle()` and `signOut()`.
2. `lib/screens/sign_in_screen.dart` renders a single login action: `Đăng nhập với Google (@fpt.edu.vn)`.
3. `lib/viewmodels/auth_viewmodel.dart` contains no email/password logic or state.
4. `docs/lab3-takeover-audit.md` §5.2 specifically audits `Google Sign-In implemented`.
5. Unit test suite contains zero test cases for email/password credentials.

### 5.2 Recommendation

**Recommendation: STICK STRICTLY TO GOOGLE SIGN-IN ONLY.**
- Email/Password authentication is **not required** by any project contract.
- Adding Email/Password would introduce significant unplanned scope: sign-up screens, password reset flows, email verification handlers, and additional test suites.
- Google Sign-In with `@fpt.edu.vn` domain alignment matches the educational objectives of PRM323 Lab 3.

---

## 6. Phase 5 — Structured Runbook Table & Operations Matrix

| Step | Action | Owner | Risk Level | Verification Command / Metric | Rollback / Recovery |
|---|---|---|:---:|---|---|
| **01** | Register Debug Keystore SHA-1 & SHA-256 in Console | Project Owner | **LOW** | Console lists SHA-1 `01:74:...:0A` and SHA-256 `58:34:...:30` | Delete fingerprint from Console |
| **02** | Enable Google Sign-In Provider in Auth | Project Owner | **LOW** | Status shows "Enabled" with support email configured | Disable provider toggle |
| **03** | Download & replace `google-services.json` | Project Owner / Dev | **LOW** | `grep -c "oauth_client" android/app/google-services.json` > 0 | `git checkout android/app/google-services.json` |
| **04** | Create Cloud Firestore Database (`asia-southeast1`) | Project Owner | **HIGH (Irreversible Location)** | Database created; status active in Console | Cannot delete default database without project reset |
| **05** | Deploy `firebase/firestore.rules` | Project Owner / Dev | **MEDIUM** | `npx firebase-tools firestore:rules:get` matches local 71 lines | Re-publish default deny rules |
| **06** | Seed `courses` catalog in Firestore | Project Owner / Dev | **LOW** | 3 documents present (`PRM323`, `SWP391`, `SWR302`) | Delete collection or documents |
| **07** | Decide & Execute Storage Plan (Path A, B, or C) | Team / Owner | **HIGH (Billing if Blaze)** | If Path A/B: bucket exists; if Path C: graceful UI error verified | If Blaze: delete bucket & downgrade to Spark |
| **08** | Deploy `firebase/storage.rules` (if Storage enabled) | Project Owner / Dev | **MEDIUM** | Storage Rules tab shows audited 49 lines | Re-publish default deny rules |
| **09** | End-to-End Android Runtime Verification | Dev / QA | **LOW** | Sign-in succeeds; Firestore read/write roundtrip verified | Sign out, clear app data (`adb shell pm clear com.example.prm323_lab3`) |

---

## 7. Rollback, Recovery & Irreversible Decisions

### 7.1 Irreversible Decisions

1. **Firestore Database Region (`asia-southeast1`):**  
   Google Cloud assigns regions permanently. If the wrong region is chosen (e.g. `us-central1`), high latency from Vietnam cannot be fixed without creating a new Firebase project.
2. **Blaze Plan Billing Commitment (If Path B chosen):**  
   Requires a credit card. Must be paired with a hard Google Cloud budget alert ($1.00 USD) to prevent financial exposure.

### 7.2 Rollback Procedures

- **Invalid `google-services.json`:**  
  Revert local file: `git checkout android/app/google-services.json`.
- **Misconfigured Rules:**  
  Emergency default-deny ruleset can be deployed immediately:
  ```
  rules_version = '2';
  service cloud.firestore { match /{document=**} { allow read, write: if false; } }
  ```
- **Unwanted Storage Costs:**  
  Delete all stored files and buckets via Firebase Console Storage, then disable Storage or downgrade billing account.

---

## 8. Final Acceptance Checklist

Following manual execution of this runbook, verify all acceptance criteria:

- [ ] **Google Sign-In Works:** Tapping "Đăng nhập với Google" on Android device successfully prompts Google Account selector, completes authentication, and navigates to `HomeScreen`.
- [ ] **Firestore Rules Active:** Firestore Rules tab displays the 71 lines from `firebase/firestore.rules`.
- [ ] **Roadmap Screen Populated:** Navigating to Roadmap displays 3 courses (`PRM323`, `SWP391`, `SWR302`) retrieved from Firestore.
- [ ] **Tasks Persistence Verified:** Creating a task writes to `users/{uid}/tasks/{taskId}` in Firestore and persists across app restarts.
- [ ] **Notes Persistence Verified:** Creating a note writes to `users/{uid}/notes/{noteId}` in Firestore.
- [ ] **Fail-Loud Architecture Maintained:** No silent mock data is surfaced anywhere in the application.
- [ ] **Zero Unauthorized Resource Creation:** Only the approved project resources have been provisioned.
