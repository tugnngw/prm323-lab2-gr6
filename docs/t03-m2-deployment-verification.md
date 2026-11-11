# T03-M2 — Firebase Security Rules Deployment Verification Report

**Date:** 2026-10-31  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Assessment Mode:** STRICTLY READ-ONLY (No deployments, no config mutations, no secrets exposed)  
**Verification Verdict:** **T03-M2 COMPLETE** (Actual deployment status conclusively determined)  

---

## 1. Executive Summary & Status Table

Authoritative inspection of Google Cloud and Firebase REST APIs confirms that **neither Firestore Rules nor Storage Rules are deployed** to Firebase project `prm323-lab2-gr6`. 

Both services are currently uninitialized on the Google Cloud backend: Cloud Firestore API is disabled (no database created), and Cloud Storage has no provisioned buckets on the active Spark plan.

| Component | Local Rules | Deployment Status | Evidence | Classification | Next Action |
|---|---|---|---|:---:|---|
| **Firestore Rules** | Present (`firebase/firestore.rules`, 71 lines) | **Not Deployed** | `firebaserules.googleapis.com/v1/.../releases` returns `{}` (0 releases); `firestore.googleapis.com/v1/.../databases` returns HTTP 403 `SERVICE_DISABLED`. | **BLOCKED** | Initialize Firestore Database in Firebase Console, then deploy rules via manual CLI command or Console Rules editor. |
| **Storage Rules** | Present (`firebase/storage.rules`, 49 lines) | **Not Deployed / Blocked** | `storage.googleapis.com/.../buckets` returns 0 buckets; `firebasestorage.googleapis.com/.../buckets` returns `{}`; Cloud Billing API confirms Spark plan (`billingEnabled: false`). | **BLOCKED** | Group decision on Spark storage initialization vs. Blaze plan vs. retaining in-app mock storage fallback. |

---

## 2. Environment & Project Verification

Authoritative state of local repository, Firebase CLI, and Google Cloud project configuration:

| Parameter | Observed State | Authoritative Source |
|---|---|---|
| **Git Branch & HEAD** | `main` @ `90554bb` (`fix(test): repair test doubles, service imports, and viewmodel test contracts`) | `git status`, `git log -1` |
| **Working Tree** | Clean (`0` staged, `0` unstaged diffs against remote) | `git status` |
| **Firebase CLI Version** | `15.34.2` | `npx firebase-tools --version` |
| **CLI Authenticated User** | `duongkt.st.2005@gmail.com` | `npx firebase-tools login:list` |
| **Firebase Project ID** | `prm323-lab2-gr6` (Project Number: `510519082861`) | `npx firebase-tools projects:list` |
| **Registered Android App** | `FPTU Second Brain` (`1:510519082861:android:4cf5b64c4e2e4487c46464`) | `npx firebase-tools apps:list` |
| **Cloud Billing Plan** | **Spark (Free Tier)** (`billingAccountName: ""`, `billingEnabled: false`) | `cloudbilling.googleapis.com/v1/projects/prm323-lab2-gr6/billingInfo` |
| **Configuration Mapping** | `firestore.rules` -> `firebase/firestore.rules`<br>`storage.rules` -> `firebase/storage.rules` | `firebase.json` |

---

## 3. Firestore Deployment Status & Authoritative Evidence

### 3.1 Rules Release Query
Inspection of deployed rules releases via Google Firebase Rules API:
- **Endpoint:** `GET https://firebaserules.googleapis.com/v1/projects/prm323-lab2-gr6/releases`
- **HTTP Status:** `200 OK`
- **Payload:**
  ```json
  {}
  ```
- **Finding:** The release registry contains zero deployed releases. Neither `cloud.firestore` nor `firebase.storage` releases exist.

### 3.2 Ruleset Metadata Query
- **Endpoint:** `GET https://firebaserules.googleapis.com/v1/projects/prm323-lab2-gr6/rulesets`
- **HTTP Status:** `200 OK`
- **Payload:**
  ```json
  {}
  ```
- **Finding:** No security rulesets have ever been compiled or saved to this project.

### 3.3 Database State Query
Inspection of Cloud Firestore databases via Cloud Firestore API:
- **Endpoint:** `GET https://firestore.googleapis.com/v1/projects/prm323-lab2-gr6/databases`
- **HTTP Status:** `403 PERMISSION_DENIED`
- **Error Code & Reason:**
  ```json
  {
    "error": {
      "code": 403,
      "message": "Cloud Firestore API has not been used in project prm323-lab2-gr6 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=prm323-lab2-gr6 then retry...",
      "status": "PERMISSION_DENIED",
      "details": [
        {
          "@type": "type.googleapis.com/google.rpc.ErrorInfo",
          "reason": "SERVICE_DISABLED",
          "domain": "googleapis.com",
          "metadata": {
            "service": "firestore.googleapis.com",
            "serviceTitle": "Cloud Firestore API"
          }
        }
      ]
    }
  }
  ```
- **CLI Corroboration:** Executing `npx firebase-tools firestore:indexes --project prm323-lab2-gr6` fails with identical HTTP 403 `SERVICE_DISABLED`.
- **Verdict:** Cloud Firestore has **never been provisioned / initialized** in project `prm323-lab2-gr6`. Rules deployment is impossible until a database instance is created in Firebase Console.

---

## 4. Storage Deployment Status & Authoritative Evidence

### 4.1 Bucket Provisioning Query
- **Endpoint (GCS):** `GET https://storage.googleapis.com/storage/v1/b?project=prm323-lab2-gr6`
- **HTTP Status:** `200 OK`
- **Payload:**
  ```json
  {
    "kind": "storage#buckets"
  }
  ```
- **Endpoint (Firebase Storage):** `GET https://firebasestorage.googleapis.com/v1beta/projects/prm323-lab2-gr6/buckets`
- **HTTP Status:** `200 OK`
- **Payload:**
  ```json
  {}
  ```
- **Finding:** The project contains **0 Cloud Storage buckets**. Neither the default Appspot bucket (`prm323-lab2-gr6.appspot.com`) nor the Firebase Storage bucket (`prm323-lab2-gr6.firebasestorage.app` declared in `lib/firebase_options.dart`) exists.

### 4.2 Billing Account Status
- **Endpoint:** `GET https://cloudbilling.googleapis.com/v1/projects/prm323-lab2-gr6/billingInfo`
- **HTTP Status:** `200 OK`
- **Payload:**
  ```json
  {
    "name": "projects/prm323-lab2-gr6/billingInfo",
    "projectId": "prm323-lab2-gr6",
    "billingAccountName": "",
    "billingEnabled": false
  }
  ```
- **Finding:** The project is on the free Spark plan with no linked billing account. On recent Google Cloud infrastructure, provisioning new Cloud Storage buckets via Firebase Console often prompts for a linked billing account (Blaze plan), blocking automated CLI deployment until manually resolved in Console.

---

## 5. Local vs. Deployed Rules Comparison

| Feature / Scope | Local File Specification | Deployed Cloud State | Variance / Gap |
|---|---|---|---|
| **Firestore Ruleset** | `firebase/firestore.rules` (71 lines, `rules_version = '2'`) | **None** (`releases/cloud.firestore` missing) | Deployed ruleset absent. Firestore API disabled. |
| **User Profile Security** | `match /users/{userId}`: `isOwner(userId)` | None | Not active in cloud. |
| **Subcollections Security** | `tasks`, `notes`, `sync`, `notifications`, `tokens`: `isOwner(userId)` | None | Not active in cloud. |
| **Catalog Security** | `courses`, `curriculums`: `isAuthenticated()`, `write: false` | None | Not active in cloud. |
| **Audit Log Security** | `audit_logs`: append-only if `userId == auth.uid` | None | Not active in cloud. |
| **Catch-All Deny** | `match /{document=**} { allow read, write: if false; }` | None | Not active in cloud. |
| **Storage Ruleset** | `firebase/storage.rules` (49 lines, `rules_version = '2'`) | **None** (`releases/firebase.storage` missing) | Deployed ruleset absent. Storage uninitialized. |
| **Storage Note Attachments** | `match /notes/{userId}/{allPaths=**}`: `isOwner()`, <10MB, image/pdf/txt | None | Not active in cloud. |
| **Storage Reports** | `match /reports/{userId}/{allPaths=**}`: `isOwner()`, <10MB, PDF only | None | Not active in cloud. |
| **Storage Catch-All** | `match /{allPaths=**} { allow read, write: if false; }` | None | Not active in cloud. |

---

## 6. Blockers, Limitations & Cost Implications

### 6.1 Firestore Blockers
1. **Uncreated Database Instance:** A Cloud Firestore database must be manually created in Firebase Console before rules can be attached. The CLI cannot create a default database non-interactively without prior initialization.
2. **Permission Boundary:** Enabling Google Cloud APIs and creating database instances alters Console state and falls outside read-only audit permissions.

### 6.2 Storage Blockers & Cost Analysis
1. **Missing Storage Bucket:** No Cloud Storage bucket exists for `prm323-lab2-gr6`.
2. **Spark vs. Blaze Pricing Policy:**
   - **Spark Plan (Current):** Free of charge ($0/mo). Includes 5 GB stored data, 1 GB/day download, 20k upload ops/day, 50k download ops/day. However, Google Cloud now frequently restricts initial bucket creation on Spark without billing verification.
   - **Blaze Plan (Pay-as-you-go):** Requires a linked credit card. Includes the same free tier usage allowances as Spark at $0 cost until free limits are exceeded.
   - **Risk Assessment:** Upgrading to Blaze without billing budget caps introduces risk of unexpected charges if infinite loops or large uploads occur. **Do not upgrade without unanimous group approval and budget cap configuration ($1-$5 limit).**
   - **Architecture Safeguard:** `FirebaseStorageService` in `lib/services/firebase_storage_service.dart` already contains robust fallback logic. If Storage is unavailable or uninitialized, the app gracefully falls back to mock storage or local cache without crashing.

---

## 7. Exact Next Steps & Manual Action Plan

### Step 1: Initialize Cloud Firestore (Manual Console Action — Required)
1. Navigate to **[Firebase Console](https://console.firebase.google.com/)** -> Project `prm323-lab2-gr6`.
2. Go to **Build** -> **Firestore Database** -> Click **Create database**.
3. Select **Production mode** (ensures secure default-deny baseline).
4. Select location: `asia-southeast1` (Singapore) or `asia-east1` (Taiwan) for lowest latency from Vietnam.
5. Click **Enable**.

### Step 2: Deploy Firestore Security Rules
Once the database is created, deploy the audited local rules using **either** method:

- **Method A — CLI Deployment (Requires manual execution):**
  ```bash
  npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
  ```
- **Method B — Console Editor Paste (Zero CLI required):**
  1. Open Firebase Console -> **Firestore Database** -> **Rules** tab.
  2. Paste the exact contents of [firebase/firestore.rules](firebase/firestore.rules).
  3. Click **Publish**.

### Step 3: Group Decision on Firebase Storage
Discuss within team:
- **Option 1 (Recommended for Lab 3):** Attempt to initialize Storage on Spark plan via Console (**Build** -> **Storage** -> **Get started**). If allowed without billing, publish [firebase/storage.rules](firebase/storage.rules).
- **Option 2:** If Console enforces Blaze plan for Storage, rely on client-side mock fallback for attachments (retaining $0 guarantee) and deploy only Firestore rules.

---

## 8. Final Verdict

**VERDICT: T03-M2 COMPLETE**

The deployment status of Firestore and Storage security rules has been definitively verified via authoritative Google Cloud and Firebase REST APIs:
- **Firestore Rules:** NOT DEPLOYED (Database uncreated; API disabled).
- **Storage Rules:** NOT DEPLOYED / BLOCKED (Bucket unprovisioned; Spark billing constraint).
- **Local Rules:** Preserved, audited, syntax-valid, and ready for deployment following manual service initialization.
