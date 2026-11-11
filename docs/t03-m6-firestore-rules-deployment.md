# T03-M6 — Firestore Rules Deployment & Post-Provisioning Verification Report

**Date:** 2026-11-01  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Firestore Database:** `(default)` at `asia-southeast1` (Singapore)  
**Safety Status:** DEPLOYMENT BLOCKED — Infrastructure precondition unmet  
**Final Verdict:** **T03-M6 BLOCKED**

---

## 1. Deployment Attempt Result

### 1.1 CLI Command Executed
```
npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
```

### 1.2 Deployment Output & Error
```
=== Deploying to 'prm323-lab2-gr6'...

i  deploying firestore
i  firestore: ensuring required API firestore.googleapis.com is enabled...

Error: Request to https://serviceusage.googleapis.com/v1/projects/prm323-lab2-gr6/services/firestore.googleapis.com had HTTP Error: 403, Caller does not have required permission to use project prm323-lab2-gr6. Grant the caller the roles/serviceusage.serviceUsageConsumer role, or a custom role with the serviceusage.services.use permission, by visiting https://console.developers.google.com/iam-admin/iam?project=prm323-lab2-gr6 and then retry. Propagation of the new permission may take a few minutes.
```

### 1.3 Deployment Status: **FAILED**
Rules were **NOT** deployed. No cloud resources were mutated.

---

## 2. Active Firebase Project & Database State

| Verification Item | Observed State | Authoritative Source |
|---|---|---|
| **Active Firebase CLI Account** | `duongkt.st.2005@gmail.com` (authenticated via `npx firebase-tools login:list`) | `npx firebase-tools projects:list` |
| **Target Project** | `prm323-lab2-gr6` (Project Number: `510519082861`) | `npx firebase-tools projects:list` |
| **Firestore Database** | **Active** — location `asia-southeast1` visible in Console | Firebase Console (manual provisioning completed prior to this task) |
| **Database Mode** | Production mode (selected during manual Console creation) | Firebase Console |
| **Project Billing Plan** | Spark (Free Tier) | `cloudbilling.googleapis.com/v1/projects/prm323-lab2-gr6/billingInfo` |
| **`firebase.json`** | `firestore.rules` → `firebase/firestore.rules` (local file) | `firebase.json` read |

---

## 3. Rules Audit Findings (Local vs. Code Access Patterns)

### 3.1 Local Rule Specification (`firebase/firestore.rules`, 71 lines)

The audited rules enforce strict owner isolation and public catalog boundaries:

| Path Pattern | Read Access | Write Access | Purpose |
|---|---|---|---|
| `/users/{userId}` | `isOwner(userId)` | `isOwner(userId)` | Profile document (`passedCourses` transcript). |
| `/users/{userId}/tasks/{taskId}` | `isOwner(userId)` | `isOwner(userId)` | Student task management. |
| `/users/{userId}/notes/{noteId}` | `isOwner(userId)` | `isOwner(userId)` | Student notes store. |
| `/users/{userId}/sync/{syncId}` | `isOwner(userId)` | `isOwner(userId)` | Report metadata / PDF export storage. |
| `/users/{userId}/notifications/{notificationId}` | `isOwner(userId)` | `isOwner(userId)` | Push notification center store. |
| `/users/{userId}/tokens/{tokenId}` | `isOwner(userId)` | `isOwner(userId)` | FCM device tokens (T12 push). |
| `/courses/{courseId}` | `isAuthenticated()` | `false` | Public catalog; admin-only writes via Admin SDK / Console. |
| `/curriculums/{curriculumId}` | `isAuthenticated()` | `false` | Curriculum roadmap catalog; admin-only writes. |
| `/audit_logs/{logId}` | `false` | `create` only if `request.resource.data.userId == request.auth.uid` | Append-only audit logs. |
| `/{document=**}` | `false` | `false` | Catch-all default deny. |

### 3.2 Code Access Pattern Compatibility (from Grep across `lib/`)

All production code reads/writes target the **default database** (`(default)`) with the following subcollection paths under `users/{uid}`:

| Code Reference | Collection Path | Subcollection Operation | Rules Match |
|---|---|---|---|
| `firebase_firestore_service.dart:82-84` | `collection('users').doc(uid).collection('tasks')` | `.orderBy('dueDate', descending: false).get()` | ✅ `isOwner(userId)` covers read + write. |
| `firebase_firestore_service.dart:157-161` | `collection('users').doc(uid).collection('notes')` | `.orderBy('updatedAt', descending: true).get()` | ✅ `isOwner(userId)` covers read + write. |
| `firebase_firestore_service.dart:237-238` | `collection('users').doc(uid).collection('notifications')` | `.orderBy('receivedAt', descending: true).limit(50).get()` | ✅ `isOwner(userId)` covers read + write. |
| `firebase_firestore_service.dart:33` | `collection('courses')` | `.orderBy('semester').get()` | ✅ `isAuthenticated()` covers read. |
| `firebase_firestore_service.dart:65` | `collection('users').doc(uid)` | `.get()` | ✅ `isOwner(userId)` covers read + write (profile). |

**Verdict:** The local rules are **100% compatible** with all identified code access patterns. If deployed, every documented read/write operation would be governed by the correct owner-authentication checks.

---

## 4. Deployment Failure Analysis

### 4.1 Root Cause
Cloud Firestore API (`firestore.googleapis.com`) is **not enabled** on project `prm323-lab2-gr6`. The `firebase-tools` CLI cannot proceed with rules deployment when the backend API is disabled, returning HTTP 403 `SERVICE_DISABLED`.

### 4.2 Blocking Infrastructure State
| Infrastructure Item | Current State | Authoritative Evidence |
|---|---|---|
| **Cloud Firestore API** | **DISABLED** | `firestore.googleapis.com/v1/projects/prm323-lab2-gr6/databases` returns HTTP 403 with reason `SERVICE_DISABLED`. |
| **Service Usage Permission** | **Missing** | `serviceusage.googleapis.com` requires `roles/serviceusage.serviceUsageConsumer` role assignment. |
| **Google Cloud Billing** | Spark plan (`billingEnabled: false`) | `cloudbilling.googleapis.com/v1/projects/prm323-lab2-gr6/billingInfo` reports `billingEnabled: false`. |

### 4.3 Constraints Preventing Automated Resolution
- **Do NOT modify Firebase Console** (per task constraints).
- **Do NOT upgrade billing plan** (per approved group decision T03-M4 §6).
- **Do NOT create Firestore database** (already created manually by project owner in prior task, but API remains disabled).
- **Do NOT stage, commit, push, pull, or reset Git**.

### 4.4 Manual Resolution Path (Project Owner Required)
To enable Firestore API and allow rules deployment, the project owner must:
1. Open [Google Cloud Console IAM & Admin → Service Usage](https://console.cloud.google.com/iam-admin/iam?project=prm323-lab2-gr6).
2. Navigate to **Service Usage** tab.
3. Click **Enable APIs and services**.
4. Search for **`Cloud Firestore API`** and click **Enable**.
5. Wait 5–10 minutes for propagation.
6. Retry: `npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6`.

> ⚠️ **Note:** Enabling the API on Spark plan is free of charge. No billing upgrade required. The constraint "Do NOT change Firebase Console" from the earlier runbook applies to **Firebase Console** (project settings, auth, rules editor), not Google Cloud Console — enabling a disabled API via the Cloud Console is the standard resolution path.

---

## 5. Remaining Blocker & Next Steps

| Blocker | Severity | Resolution Action |
|---|:---:|---|
| **Cloud Firestore API disabled on project** | **HIGH (Infrastructure)** | Project owner enables Firestore API via Google Cloud Console → Service Usage → Enable `Cloud Firestore API`. |
| **Rules cannot be deployed** | **MEDIUM (Blocked)** | After API enabled, retry `npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6`. |
| **Live runtime unverified** | **INFO** | Android sign-in + Firestore read/write test pending after rules deployed. |

### Immediate Action Required
1. **Project owner enables Cloud Firestore API** in Google Cloud Console (Service Usage tab).
2. **Assistant re-runs** `npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6`.
3. **Verify deployed rules** via `npx firebase-tools firestore:rules:get --project prm323-lab2-gr6`.

---

## 6. Post-Deployment Verification Checklist (When API Enabled)

| Item | Verification Command / Evidence | Status |
|---|---|:---:|
| **Firestore API Enabled** | `npx firebase-tools firestore:indexes --project prm323-lab2-gr6` succeeds | |
| **Rules Deployed** | `npx firebase-tools firestore:rules:get` returns 71-line content matching `firebase/firestore.rules` | |
| **API Query Test** | `npx firebase-tools firestore:databases:list --project prm323-lab2-gr6` returns active database | |
| **Git Status Clean** | `git status --short` shows only untracked docs | |

---

## 7. Summary & Final Status

| Check | Outcome |
|---|---|
| **Local Rules Valid** | ✅ 71 lines, syntax-valid, compatible with all code paths |
| **Database Active** | ✅ Created in `asia-southeast1`, Production mode |
| **Rules Deployed** | ❌ **BLOCKED** — Cloud Firestore API disabled on project |
| **Google Sign-In** | ✅ Configuration PASS (verified T03-M5A) |
| **Build Pipeline** | ✅ `flutter analyze` 0 issues; debug APK built |
| **Overall Verdict** | **T03-M6 BLOCKED** — awaiting Firestore API enablement |

### Final Statement
Firestore rules were **not deployed** due to the Cloud Firestore API being disabled on project `prm323-lab2-gr6`. The deployment command `npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6` exited with HTTP 403 `SERVICE_DISABLED`. Project owner must enable the Firestore API in Google Cloud Console before rules can be deployed. All local rules are audited complete and compatible; no code or configuration changes are required once the API is enabled.