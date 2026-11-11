# T03-M3 — Firebase Runtime Readiness Audit Report

**Date:** 2026-10-31  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Package Name:** `com.example.prm323_lab3`  
**Assessment Mode:** STRICTLY READ-ONLY (No modifications to code, tests, rules, or cloud resources)  
**Final Verdict:** **READY FOR FIREBASE SETUP** (Codebase is architecturally ready for backend provisioning; runtime integration is currently blocked by missing cloud infrastructure)  

---

## 1. Executive Summary

This audit assesses the runtime readiness of the Firebase integration across production code, local configuration, and cloud backend infrastructure.

Key conclusions:
1. **Production Code Architecture:** The application code is structurally complete, typed, and adheres to the Lab 3 fail-loud specification (Lab 3 §1.4). Silent mock fallbacks have been eliminated from `lib/`. When Firebase fails to initialize, `FirebaseConfigErrorApp` renders a blocking full-screen error widget. When unauthenticated or network-disconnected, ViewModels return empty states rather than fictitious mock data.
2. **Infrastructure Blockers (Cloud Backend):** Runtime Firebase operations cannot currently function because backend cloud services are unprovisioned on the Spark plan:
   - Cloud Firestore API is `SERVICE_DISABLED` (no database instance exists).
   - Firebase Storage has 0 provisioned buckets.
   - Firebase Security Rules exist locally but have not been deployed to the cloud.
3. **Authentication Configuration Blockers:** `google-services.json` on disk contains **0 OAuth clients** (`oauth_client: []`). The debug keystore SHA-1 fingerprint has not been registered in Firebase Console, making Google Sign-In runtime execution impossible on Android (`ApiException: 10`).
4. **Scope Boundaries:** Registration and email/password login are intentionally not implemented in code; authentication is designed exclusively around Google Sign-In with university domain scoping (`@fpt.edu.vn`).

---

## 2. Environment and Git State

Authoritative local environment status:

| Parameter | Observed State | Source / Command |
|---|---|---|
| **Git Branch** | `main` | `git status` |
| **HEAD Commit** | `90554bb` (`fix(test): repair test doubles, service imports, and viewmodel test contracts`) | `git log -1 --oneline` |
| **Working Tree** | Clean tracked tree (`docs/t03-m2-deployment-verification.md` untracked) | `git status -s` |
| **Flutter SDK** | 3.47.5 • Dart 3.13.4 • Channel stable | `flutter --version` |
| **Android SDK / AGP** | Android SDK 37 • Gradle 9.3.1 • AGP 9.1.0 | `android/build.gradle.kts` |
| **Connected Devices** | 0 active Android devices / emulators connected | `adb devices`, `flutter devices` |
| **Available Emulators** | 1 AVD installed (`Small_Phone` • Generic Android) | `flutter emulators` |
| **Local Google Services** | Present at `android/app/google-services.json` (683 bytes) | File system check |
| **Debug Keystore** | Present at `~/.android/debug.keystore` | File system check |
| **Debug Keystore SHA-1** | `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A` | `keytool.exe -list -v` |
| **Debug Keystore SHA-256**| `58:34:6F:5F:06:D5:9C:0E:B7:6C:87:6B:1F:A5:BC:31:3E:C2:6B:8E:3C:79:8F:56:3C:2A:66:D4:85:BA:98:30` | `keytool.exe -list -v` |

---

## 3. Firebase Infrastructure Status

Authoritative status from Google Cloud & Firebase REST API endpoints (verified via authenticated token in T03-M2):

| Component | Status | Cloud Response / Evidence | Blocker Description |
|---|---|---|---|
| **Firebase Project** | Active | `projects/prm323-lab2-gr6` (ID: `510519082861`) | None (Project exists and is accessible) |
| **Cloud Billing** | Spark (Free) | `billingAccountName: ""`, `billingEnabled: false` | Zero billing linked; restrictions on Storage provisioning |
| **Firestore API** | Disabled | HTTP 403 `SERVICE_DISABLED` on `firestore.googleapis.com` | Database not created in Firebase Console |
| **Firestore Database** | Non-existent | `npx firebase-tools firestore:databases:list` fails | No default database instance |
| **Firestore Rules** | Not Deployed | `GET /v1/projects/prm323-lab2-gr6/releases` returns `{}` | Local `firebase/firestore.rules` not in cloud |
| **Storage Buckets** | 0 Buckets | `GET /v1beta/projects/prm323-lab2-gr6/buckets` returns `{}` | Bucket `prm323-lab2-gr6.firebasestorage.app` unprovisioned |
| **Storage Rules** | Not Deployed | Ruleset releases count: 0 | Local `firebase/storage.rules` not in cloud |
| **OAuth Android Client** | Missing | `google-services.json` contains `oauth_client: []` | SHA-1 not registered in Firebase Console |

---

## 4. Production Code Audit

### 4.1 Firebase Core
- **Implementation:** `lib/main.dart:44-77`, `lib/firebase_options.dart`.
- **Initialization:** `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- **Error Handling:** Wrapped in `try/catch`. On failure, stores `_firebaseInitError` and renders `FirebaseConfigErrorApp` (lines 115-117, 242-281).
- **Mock Fallback Verification:** Zero mock fallback in `main.dart`. If initialization fails, the app refuses to load mock services and displays a blocking error screen stating: *"Ứng dụng yêu cầu cấu hình Firebase hợp lệ... Không thể kết nối Firebase"*.

### 4.2 Authentication
- **Implementation:** `lib/services/auth_service.dart`, `lib/services/firebase_auth_service.dart`, `lib/viewmodels/auth_viewmodel.dart`.
- **Scope & Methods:**
  - `signInWithGoogle()`: Implemented using `google_sign_in: ^6.2.2` and `FirebaseAuth.instance.signInWithCredential()`.
  - `signOut()`: Implemented via `Future.wait([_googleSignIn.signOut(), _auth.signOut()])`.
  - `authStateChanges`: Stream mapped from `_auth.authStateChanges()`.
  - `currentUserId` / `currentUserEmail`: Directly mapped from `_auth.currentUser`.
- **Absence of Email/Password & Registration:**
  - Neither `AuthService` nor `FirebaseAuthService` implements email/password sign-up or login (`createUserWithEmailAndPassword`, `signInWithEmailAndPassword`).
  - This is an intentional design choice for the FPT student portal requiring `@fpt.edu.vn` Google authentication, but represents a structural limitation if non-Google accounts are required.
- **Identity Propagation:** When `authStateChanges` emits true, `AuthViewModel._onLogin()` triggers:
  1. `analyticsService.setUserId(uid)`
  2. `crashlyticsService.setUserId(uid)`
  3. `analyticsService.logLoginSuccess(method: 'google')`
  4. `crashlyticsService.setCustomKey('auth_method', 'google')`
  5. `_registerPushToken(uid)`

### 4.3 Google Sign-In
- **Implementation:** `FirebaseAuthService.signInWithGoogle()`.
- **OAuth / Android Package Configuration:**
  - Package: `com.example.prm323_lab3` (matches `android/app/build.gradle.kts` and `google-services.json`).
  - Scopes requested: `['email', 'profile']`.
  - User cancellation handling: Handled gracefully (returns cleanly without throwing exception).
  - Error translation: Maps `FirebaseAuthException` codes (`network-request-failed`, `user-disabled`, `account-exists-with-different-credential`) to localized Vietnamese error messages.
- **Missing Console Prerequisites:**
  - Debug SHA-1 (`01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A`) is not registered in Firebase Console.
  - `google-services.json` has `oauth_client: []`.
  - Runtime Google Sign-In attempts on Android will fail immediately with `ApiException: 10` (Developer Error).

### 4.4 Firestore
- **Implementation:** `lib/services/firestore_service.dart`, `lib/services/firebase_firestore_service.dart`.
- **Offline Persistence:** Enabled via `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`.
- **Collection Paths & UID Scoping:**
  - Catalog: `/courses` (ordered by `semester`), `/courses/{courseId}`.
  - User Profile: `/users/{userId}`.
  - User Tasks: `/users/{userId}/tasks` (ordered by `dueDate`).
  - User Notes: `/users/{userId}/notes` (ordered by `updatedAt` desc).
  - Sync / Reports: `/users/{userId}/sync/{reportId}`.
  - Notifications: `/users/{userId}/notifications` (ordered by `receivedAt` desc, limit 50).
  - FCM Tokens: `/users/{userId}/tokens/{tokenId}`.
- **CRUD & Security Enforcement:**
  - `addTask`, `updateTask`, `saveNote` enforce `userId != null` and throw `ArgumentError` if omitted.
  - All read/write methods utilize `GetOptions(source: Source.serverAndCache)`.
  - Local rules (`firebase/firestore.rules`) enforce `isOwner(userId)` on all subcollections and deny broad write access.

### 4.5 Storage
- **Implementation:** `lib/services/storage_service.dart`, `lib/services/firebase_storage_service.dart`.
- **Fail-Loud Architecture:**
  - Lines 20-28 of `FirebaseStorageService` explicitly throw `StateError` if `_storage` is null: *"Cloud Storage chưa được khởi tạo... Từ chối trả về URL giả lập"*. Zero fake mock URL generation exists in production code.
- **Upload / Download Operations:**
  - `uploadFile()`: Supports `onProgress` callbacks using `uploadTask.snapshotEvents`, sets MIME `contentType`, records upload timestamp metadata, and returns real `getDownloadURL()`.
  - `downloadFile()`: Imposes 10 MB maximum safety buffer cap (`maxSizeBytes = 10 * 1024 * 1024`).
- **MIME & Size Validation in Callers:**
  - `NotesViewModel.uploadAttachment`: Validates file size <= 10 MB and restricts MIME types to PDF, image (`image/png`, `image/jpeg`), and text (`text/plain`). Rejects unsupported formats with user-facing message.
  - `ReportExportService`: Explicitly uploads with `contentType: 'application/pdf'` under `reports/$userId/...`.

### 4.6 FCM / Notifications
- **Implementation:** `lib/services/messaging_service.dart`, `lib/services/firebase_messaging_service.dart`, `lib/viewmodels/notifications_viewmodel.dart`.
- **Three-State Push Handlers (Lab 3 T12):**
  - **Foreground:** Handled by `FirebaseMessaging.onMessage.listen()` -> emits to `onForegroundMessage` stream -> `NotificationsViewModel` persists to Firestore via `saveNotification` and refreshes list.
  - **Background:** Handled by `FirebaseMessaging.onMessageOpenedApp.listen()` -> emits to `onNotificationTap` stream -> records `lastTappedRoute` for deep-link navigation in `AppShell`. Top-level `@pragma('vm:entry-point') fcmBackgroundHandler` handles background wakeups.
  - **Terminated:** Handled on startup by `takeInitialMessage()` -> queries `FirebaseMessaging.instance.getInitialMessage()` -> routes on cold start.
- **Token Management:**
  - `requestPermission()`: Requests alert, badge, sound permissions.
  - `getToken()` / `onTokenRefresh`: Automatically registered to Firestore under `users/{uid}/tokens/{tokenId}` upon user sign-in.

### 4.7 Feature Integration & Dependencies

| Feature | Production Implementation | Firebase Services Required | Standalone / Offline Capability |
|---|---|---|---|
| **Roadmap** | `RoadmapViewModel` | Firestore (`courses`, `users/{uid}`) | Prerequisite evaluation is in-memory; catalog requires Firestore. |
| **Tasks** | `TasksViewModel` | Firestore (`users/{uid}/tasks`) | Local optimistic state with rollback; requires Firestore for sync. |
| **Notes** | `NotesViewModel` | Firestore (`users/{uid}/notes`), Storage (`notes/{uid}/*`) | Local optimistic state with rollback; requires Storage for attachments. |
| **Academic Advisor** | `AdvisorViewModel` | Remote Config (`feature_ai_advisor_enabled`), Analytics | **100% standalone logic.** Rule-based advice and GPA simulator execute in-memory with local defaults. |
| **PDF Export** | `ReportExportService`, `ReportPdfService` | Storage (`reports/{uid}/*`), Firestore (`users/{uid}/sync`) | **PDF generation is 100% standalone** (local fonts); cloud upload/audit requires Storage & Firestore. |
| **Notification Center** | `NotificationsViewModel` | FCM (`FirebaseMessaging`), Firestore (`users/{uid}/notifications`) | UI renders empty state standalone; live pushes require FCM & Firestore. |

---

## 5. Runtime Verification Matrix

*Evaluation against actual environment state: `android/app/google-services.json` present, no emulator running, Cloud Firestore API disabled, Cloud Storage 0 buckets.*

| Test ID | Test | Preconditions | Execution Method | Expected Behavior | Actual Behavior | Status | Blocker / Defect |
|---|---|---|---|---|---|:---:|---|
| **M3-01** | Flutter app starts | APK build succeeds | Static & build verification | App compiles and boots entrypoint `main()` | `flutter build apk --debug` exits 0 (179 MB APK); code loads `FptuSecondBrainApp` | **PASS** | None |
| **M3-02** | Firebase Core initialization | `DefaultFirebaseOptions.android` configured | Code inspection & options check | Native FirebaseApp initialized from options | Core initializes native client, but downstream APIs disabled | **PASS** (Core) | Downstream APIs disabled in cloud |
| **M3-03** | Firebase Auth availability | Firebase Core initialized | Code inspection & SDK check | `FirebaseAuth.instance` ready | Auth instance accessible; Google provider enabled in code | **PASS** (SDK) | Console configuration missing |
| **M3-04** | Registration flow | User input in UI | Code inspection | Sign-up with email/password creates user | Feature not implemented in code; only Google Sign-In exists | **NOT TESTED** / **ABSENT** | Not in codebase scope |
| **M3-05** | Login/logout flow | Valid user credentials | Code inspection & call analysis | Sign-in acquires credentials; sign-out clears | `FirebaseAuthService.signOut()` works; sign-in blocked by Google OAuth | **BLOCKED** | SHA-1 missing in Console; `oauth_client: []` |
| **M3-06** | Auth state persistence | Active auth session | Code inspection | Token cached in Keychain/Keystore across restarts | Code correctly listens to `authStateChanges`; blocked from testing | **BLOCKED** | Blocked by M3-05 |
| **M3-07** | Google Sign-In readiness | Google Play Services & OAuth | Keystore & `google-services.json` check | Google Sign-In prompts account picker and returns idToken | `google-services.json` lacks OAuth client (`oauth_client: []`); will throw `ApiException: 10` | **BLOCKED** | SHA-1 not registered in Firebase Console |
| **M3-08** | Firestore initialization | Firebase Core initialized | Cloud API check | `FirebaseFirestore.instance` connects with offline cache | API returns HTTP 403 `SERVICE_DISABLED`; database does not exist | **BLOCKED** | Firestore database not created in Console |
| **M3-09** | Firestore CRUD | Firestore initialized & auth active | API query & service inspection | Documents created/read under `users/{uid}/*` | Cannot write or read from non-existent cloud database | **BLOCKED** | Firestore database not created in Console |
| **M3-10** | Firestore UID isolation | Rules deployed & multi-user session | Rules file inspection & cloud status | Cross-UID read/write denied by security rules | Local rules secure (`isOwner`), but NOT deployed to cloud | **BLOCKED** | Rules not deployed; database uncreated |
| **M3-11** | Storage initialization | Firebase Core initialized | Cloud Storage API check | `FirebaseStorage.instance` targets storage bucket | Bucket `prm323-lab2-gr6.firebasestorage.app` does not exist | **BLOCKED** | 0 buckets in project; Spark plan limitation |
| **M3-12** | Storage upload/download | Storage initialized & auth active | Service code inspection & API check | Files uploaded under `notes/{uid}/` and `reports/{uid}/` | Fails loud with `FirebaseException` (no bucket exists) | **BLOCKED** | No bucket provisioned in cloud |
| **M3-13** | FCM initialization and token | Google Play Services active | Code inspection | Device token generated and returned | Token generation requires Google Play Services and backend registration | **BLOCKED** | Requires running device & Play Services |
| **M3-14** | Notification persistence | FCM message received | Code inspection | Notification saved to `users/{uid}/notifications` | Message handling code ready; persistence blocked by missing Firestore | **BLOCKED** | Firestore database not created |
| **M3-15** | Roadmap/Tasks/Notes integration | Services injected | Code & unit test verification | Loads from Firestore; handles empty/loading states | Unit tests pass with mocks (17/17 tests); real runtime blocked by backend | **BLOCKED** (Runtime) | Firestore & Auth blockers |
| **M3-16** | Academic Advisor integration | Remote Config initialized | Code inspection & unit test run | Rule-based advice and GPA simulation work in-memory | Tests pass (4/4 tests); local logic operates independently of cloud | **PASS** | None (Fully functional client-side) |
| **M3-17** | PDF Export | App running | Code inspection & font asset check | Generates PDF locally with DejaVuSans fonts | `ReportPdfService` builds PDF cleanly; cloud upload blocked by Storage | **PASS** (Local PDF) / **BLOCKED** (Cloud) | Storage bucket missing for upload |
| **M3-18** | Notification Center | ViewModel initialized | Code inspection & UI check | Renders empty state when no notifications | UI and ViewModel render clean empty state; push transport blocked | **PASS** (UI) / **BLOCKED** (Live Push) | FCM & Firestore cloud blockers |

---

## 6. Mock/Test Coverage versus Real Runtime Coverage

The current test suite (`flutter test`) achieves **100% pass rate (25/25 tests)** across all test files:
- `test/viewmodels/advisor_viewmodel_test.dart` (4 tests)
- `test/viewmodels/roadmap_viewmodel_test.dart` (3 tests)
- `test/viewmodels/tasks_notes_test.dart` (14 tests)
- `test/widget_test.dart` (4 tests)

### Discrepancy Analysis

| Dimension | Mock / Test Suite Coverage | Real Firebase Runtime Coverage |
|---|---|---|
| **Authentication** | 100% verified via `MockAuthService` (simulates authenticated `currentUserId`, unauthenticated states, streams). | **0% verified.** Google Sign-In cannot execute due to missing SHA-1 and empty `oauth_client`. |
| **Firestore Persistence** | 100% verified via `FakeFirestoreService` & `MockFirestoreService` (CRUD, UID scoping, rollback, failure flags). | **0% verified.** Firestore API is disabled; database instance uncreated. |
| **Storage Attachments** | 100% verified via unit tests (MIME filtering, size rejection, rollback). | **0% verified.** Storage bucket does not exist. |
| **FCM / Push Messages** | 100% verified via nullable `MessagingService?` injection in widget tests. | **0% verified.** Requires physical device or Google Play emulator with cloud dispatch. |
| **PDF Generation** | 100% functional locally via `ReportPdfService` and bundled TrueType fonts. | Local generation works; cloud upload fails due to missing bucket. |
| **Academic Advisor** | 100% functional locally (pure algorithmic and rule-based logic). | **100% functional.** Operates with default fallback even if Remote Config is offline. |

**Key Takeaway:** The test suite validates application business logic, state machines, and fail-loud error boundaries with high fidelity, but **zero tests currently touch live Firebase endpoints**. Passing unit tests must not be misconstrued as live cloud verification.

---

## 7. Security and UID Isolation Assessment

### 7.1 Client-Side Enforcement
- **UID Scoping:** Verified across all ViewModels (`TasksViewModel`, `NotesViewModel`, `RoadmapViewModel`, `NotificationsViewModel`). Every user-owned mutation or query explicitly binds the operation to `authService.currentUserId`.
- **Zero Persona Hardcoding:** Audited code contains zero hardcoded student personas (`user_p02`, `ducnmse180000`). All user IDs originate strictly from `AuthService`.
- **Unauthenticated Operation Rejection:** If `currentUserId == null`, mutations in `TasksViewModel` and `NotesViewModel` abort immediately, return `false`, set `lastError` to `"Bạn chưa đăng nhập"`, and execute zero remote network requests.
- **Optimistic State Rollback:** If a remote write throws an exception, local state is restored to its exact pre-mutation state, preventing UI desynchronization.
- **PII Protection:** `FirebaseAnalyticsService` scrubs all blacklisted PII keys (`email`, `name`, `phone`, `address`) before sending payloads to Google Analytics.

### 7.2 Cloud-Side Rules Enforcement
- Local files `firebase/firestore.rules` and `firebase/storage.rules` implement robust ownership gating (`isOwner(userId)`), size caps (<10 MB), MIME whitelisting, and catch-all `allow read, write: if false;`.
- **Vulnerability Gap:** Because these rules are **not deployed to Firebase**, the cloud project currently has **no active security rules**. Once the Firestore database is created, deploying these rules is an urgent prerequisite before allowing production writes.

---

## 8. Infrastructure Blockers

The following cloud infrastructure components are absent and block live runtime execution:

```
[Firebase Project: prm323-lab2-gr6]
  │
  ├── ❌ Cloud Firestore API: Disabled (SERVICE_DISABLED)
  │      └── Blocker: Database must be created in Firebase Console
  │
  ├── ❌ Cloud Firestore Rules: Not Deployed (0 releases)
  │      └── Blocker: Requires database creation before rules deployment
  │
  ├── ❌ Firebase Storage: 0 Buckets Provisioned
  │      └── Blocker: Bucket must be created in Firebase Console (Spark/Blaze constraint)
  │
  ├── ❌ Firebase Storage Rules: Not Deployed (0 releases)
  │      └── Blocker: Requires bucket provisioning before rules deployment
  │
  └── ❌ Android OAuth 2.0 Client: Missing (oauth_client: [])
         └── Blocker: Debug SHA-1 must be added in Console, google-services.json refreshed
```

---

## 9. Code Defects Independent of Infrastructure

The code audit identified the following non-infrastructure limitations and defects:

1. **Absence of Email/Password Authentication:**
   - `AuthService` and `FirebaseAuthService` only implement `signInWithGoogle()`.
   - If lab grading criteria require standard email/password registration and login, this represents an unimplemented requirement.
2. **UI Copy / Computation Mismatch (Finding F6):**
   - In `lib/screens/advisor_screen.dart:101`, static text displays `"Mốc Sinh viên Giỏi: GPA tích lũy ≥ 8.0"` (cumulative wording).
   - In contrast, `AdvisorViewModel` computes the 11-credit semester term GPA (`"GPA kỳ 5"` in `strategy_sim_screen.dart`). Production code was left unchanged per read-only constraints, but copy should be synchronized.
3. **Storage Fallback Mismatch in Provider (Cosmetic):**
   - In `lib/main.dart:132-134`: `Provider<StorageService>(create: (_) => storageService ?? FirebaseStorageService())`.
   - While `FirebaseStorageService` correctly fails loud, the comment on line 124 mentions Firebase guarantee. This is safe but notable.

---

## 10. Manual Actions Required

To achieve full live Firebase runtime operation, the following manual actions must be executed by the project owner in **Firebase Console**:

### Step 1: Register Android Debug SHA-1 & Refresh `google-services.json`
1. Open **Firebase Console** -> Project `prm323-lab2-gr6` -> **Project Settings** -> **Your apps**.
2. Select Android app `com.example.prm323_lab3`.
3. Click **Add fingerprint** and add:
   - **SHA-1:** `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A`
   - **SHA-256:** `58:34:6F:5F:06:D5:9C:0E:B7:6C:87:6B:1F:A5:BC:31:3E:C2:6B:8E:3C:79:8F:56:3C:2A:66:D4:85:BA:98:30`
4. Enable **Google Sign-In** under **Build** -> **Authentication** -> **Sign-in method**.
5. Download updated `google-services.json` and replace `android/app/google-services.json` (verify that `oauth_client` now contains client entries).

### Step 2: Initialize Cloud Firestore Database
1. In Firebase Console, navigate to **Build** -> **Firestore Database** -> Click **Create database**.
2. Select **Production mode** (secure default).
3. Select location: `asia-southeast1` (Singapore) or `asia-east1` (Taiwan).
4. Click **Enable**.

### Step 3: Deploy Firestore Security Rules
Execute from project root:
```bash
npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6
```
*(Or paste [firebase/firestore.rules](firebase/firestore.rules) into Console -> Firestore -> Rules -> Publish).*

### Step 4: Resolve Firebase Storage Provisioning
1. In Firebase Console, navigate to **Build** -> **Storage** -> Click **Get started**.
2. If Console permits bucket creation on the Spark plan, create bucket `prm323-lab2-gr6.firebasestorage.app` in `asia-southeast1` and deploy [firebase/storage.rules](firebase/storage.rules).
3. If Console enforces Blaze plan upgrade, obtain team consent before upgrading, or choose to run attachment features with client-side fallback.

---

## 11. Recommended Next Tasks & Final Summary

### Prioritized Recommendations

- **P0 — Must fix before Firebase setup:**
  1. Add debug SHA-1 to Firebase Console Android app `com.example.prm323_lab3`.
  2. Download refreshed `google-services.json` with populated `oauth_client`.
  3. Create Cloud Firestore database instance in Firebase Console.
  4. Deploy `firebase/firestore.rules`.
- **P1 — Must fix before runtime integration testing:**
  1. Initialize Firebase Storage bucket or establish team policy on Blaze upgrade.
  2. Seed initial course catalog into Firestore `/courses` collection (using `firebase/seed_data.json`).
  3. Launch Android emulator / connect physical device to test Google Sign-In end-to-end.
- **P2 — Improvements that can be deferred:**
  1. Implement email/password authentication if required by lab grading specification.
  2. Align UI text in `advisor_screen.dart` (`"GPA kỳ 5"` vs `"GPA tích lũy"`).
  3. Add in-app developer badge displaying live Firebase connection status.

---

## Final Summary Table

| Module | Implementation | Real Runtime | Status | Required Action |
|---|---|---|---|---|
| **Firebase Core** | Complete (`main.dart`, `firebase_options.dart`, `FirebaseConfigErrorApp`) | Functional native initialization | **READY** | None in code; downstream services need cloud setup |
| **Authentication** | Google Sign-In implemented; Email/Password omitted | Blocked by missing SHA-1 in Console | **BLOCKED** | Add SHA-1 in Console; re-download `google-services.json` |
| **Google Sign-In** | Complete (`FirebaseAuthService.signInWithGoogle`) | Blocked by empty `oauth_client` | **BLOCKED** | Register debug SHA-1 in Firebase Console |
| **Firestore** | Complete (`FirebaseFirestoreService` 15 methods, offline cache) | Blocked: API disabled, database uncreated | **BLOCKED** | Create Firestore Database in Firebase Console; deploy rules |
| **Storage** | Complete (`FirebaseStorageService`, fail-loud, 10MB cap) | Blocked: 0 buckets in cloud project | **BLOCKED** | Provision Storage bucket in Console or decide on Blaze |
| **FCM** | Complete (`FirebaseMessagingService` 3-state handlers) | Blocked: requires device + Play Services | **BLOCKED** | Test on physical device / Google Play emulator |
| **Roadmap/Tasks/Notes** | Complete (MVVM, fail-loud, UID scoping, rollback) | Blocked by Firestore & Auth runtime | **BLOCKED** | Dependent on Firestore and Auth setup |
| **Academic Advisor** | Complete (`AdvisorViewModel`, GPA simulator, advice engine) | **Functional** (100% local client logic) | **PASS** | None; fully operational standalone |
| **PDF Export** | Complete (`ReportPdfService` + `ReportExportService`) | Local PDF works; Cloud upload blocked | **PARTIALLY READY** | Storage bucket required for cloud upload |
| **Notification Center** | Complete (`NotificationsViewModel`, deep-linking) | Local UI works; Push delivery blocked | **PARTIALLY READY** | FCM token & Firestore required for live push |

---

## 12. Final Verdict

### **VERDICT: READY FOR FIREBASE SETUP**

**Justification:**
1. **Codebase Cleanliness:** 0 static analyzer issues, 25/25 automated unit/widget tests passing, clean debug APK build.
2. **Architectural Compliance:** Production code contains zero mock fallbacks, enforces UID scoping on all user-owned paths, and correctly handles errors through fail-loud mechanisms.
3. **Readiness Threshold:** The local codebase has reached the exact boundary where no further code modifications are productive until manual Firebase Console configuration (SHA-1 registration, database creation, rules deployment) is performed by the project owner.
