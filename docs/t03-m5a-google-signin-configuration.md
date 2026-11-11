# T03-M5A — Google Sign-In Configuration & Verification Report

**Date:** 2026-11-01  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Android Package:** `com.example.prm323_lab3`  
**Assessment Phase:** Post-Console Manual Action Verification  
**Final Status:**  
* **CONFIGURATION:** **PASS**  
* **BUILD:** **PASS**  
* **RUNTIME:** **NOT TESTED** (Awaiting Android emulator / physical device execution)  

---

## 1. Executive Summary & Verification Verdict

Following manual registration of debug signing fingerprints and enablement of the Google Sign-In provider in Firebase Console by the project owner:

1. **Configuration Verified (PASS):** `android/app/google-services.json` has been refreshed and safely inspected. It now contains **3 OAuth clients**, including Type 1 (Android client matching local debug SHA-1 `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A`) and Type 3 (Web client ID required for exchanging Firebase Auth credentials).
2. **Cloud Provider Verified (PASS):** Independent query to Google Identity Toolkit REST API (`identitytoolkit.googleapis.com`) authoritatively confirms that provider `google.com` is active and enabled (`enabled: true`) in project `prm323-lab2-gr6`.
3. **Build Verified (PASS):** `flutter analyze` passed with 0 issues. `flutter build apk --debug` succeeded in 44.4s, generating `build/app/outputs/flutter-apk/app-debug.apk`.
4. **Git Security Clean (PASS):** `android/app/google-services.json` is strictly ignored by `.gitignore` (line 53) and remains untracked. No credentials or secrets staged.
5. **Runtime Execution (NOT TESTED):** No connected Android device or emulator with Google Play Services is currently active in the CLI environment. Live sign-in verification must be performed once an Android target is launched.

---

## 2. Project & Android Package Verification

Authoritative state of local configuration files:

| Verification Item | Configured Target | Observed State | Status |
|---|---|---|:---:|
| **Git Branch & HEAD** | `main` | `main` @ `90554bb` | **PASS** |
| **Tracked Working Tree** | Clean | Clean (0 modified tracked files) | **PASS** |
| **Android Namespace** | `com.example.prm323_lab3` | `com.example.prm323_lab3` (`android/app/build.gradle.kts:10`) | **PASS** |
| **Android Application ID** | `com.example.prm323_lab3` | `com.example.prm323_lab3` (`android/app/build.gradle.kts:21`) | **PASS** |
| **Firebase Project ID** | `prm323-lab2-gr6` | `prm323-lab2-gr6` (`android/app/google-services.json`) | **PASS** |
| **Firebase Project Number** | `510519082861` | `510519082861` (`android/app/google-services.json`) | **PASS** |
| **Registered Android App ID** | `1:510519082861:android:...` | `1:510519082861:android:4cf5b64c4e2e4487c46464` | **PASS** |

---

## 3. Cryptographic Fingerprint & OAuth Client Verification

### 3.1 Local vs. Registered SHA Fingerprints
Local debug keystore (`C:\Users\duong\.android\debug.keystore`, alias `androiddebugkey`) was recalculated via JDK 21 `keytool.exe` and compared against Firebase Management API (`firebase.googleapis.com/v1beta1/.../androidApps/.../sha`):

| Hash Algorithm | Local Debug Keystore Fingerprint | Cloud Registered Fingerprint | Consistency |
|---|---|---|:---:|
| **SHA-1** | `01:74:66:E9:3E:54:F7:0E:42:F6:6B:6B:D7:43:95:63:79:A9:C9:0A` | `017466e93e54f70e42f66b6bd743956379a9c90a` | **100% MATCH** |
| **SHA-256** | `58:34:6F:5F:06:D5:9C:0E:B7:6C:87:6B:1F:A5:BC:31:3E:C2:6B:8E:3C:79:8F:56:3C:2A:66:D4:85:BA:98:30` | `58346f5f06d59c0eb76c876b1fa5bc313ec26b8e3c798f563c2a66d485ba9830` | **100% MATCH** |
| **Legacy SHA-1** | N/A (Previous project cert) | `56918787957ba4323024f082deee93b6190adc4f` | Coexists peacefully |

### 3.2 Refreshed `google-services.json` OAuth Structure
Inspection of `android/app/google-services.json` (secret values masked):
- **Total `oauth_client` entries:** **3** (previously 0)
- **OAuth Entry 0:**
  - `client_type`: `1` (Android Client)
  - `package_name`: `com.example.prm323_lab3`
  - `certificate_hash`: `017466e93e54f70e42f66b6bd743956379a9c90a` (Exact match with local debug SHA-1)
- **OAuth Entry 1:**
  - `client_type`: `1` (Android Client)
  - `package_name`: `com.example.prm323_lab3`
  - `certificate_hash`: `569187...dc4f` (Secondary SHA-1)
- **OAuth Entry 2:**
  - `client_type`: `3` (Server / Web Client ID)
  - Mandatory for Google Sign-In SDK to exchange Google ID tokens with Firebase Auth backend.

---

## 4. Authoritative Cloud Provider Status

An independent read-only REST inspection of Google Cloud Identity Toolkit API confirms active backend status:
- **API Endpoint:** `GET https://identitytoolkit.googleapis.com/v2/projects/prm323-lab2-gr6/defaultSupportedIdpConfigs`
- **HTTP Status:** `200 OK`
- **Payload Inspection:**
  ```json
  {
    "defaultSupportedIdpConfigs": [
      {
        "name": "projects/510519082861/defaultSupportedIdpConfigs/google.com",
        "enabled": true
      }
    ]
  }
  ```
- **Conclusion:** Google Sign-In is confirmed **ENABLED** on the Firebase backend.

---

## 5. Build & Compilation Verification

### 5.1 Static Analysis (`flutter analyze`)
- **Command:** `flutter analyze`
- **Output:**
  ```
  Analyzing prm323-lab2-gr6...
  No issues found! (ran in 58.6s)
  ```
- **Status:** **PASS** (Zero compiler warnings, zero errors).

### 5.2 Android Debug Binary Compilation (`flutter build apk --debug`)
- **Command:** `flutter build apk --debug`
- **Duration:** 44.4 seconds
- **Output:**
  ```
  Running Gradle task 'assembleDebug'...
  √ Built build\app\outputs\flutter-apk\app-debug.apk
  ```
- **Status:** **PASS** (APK assembled successfully with updated Google Services resource bindings).

---

## 6. Git & Secret File Hygiene

- **Rule:** Never commit `google-services.json` or expose credentials.
- **Verification Evidence:**
  - `git check-ignore -v android/app/google-services.json` -> `.gitignore:53:android/app/google-services.json`
  - `git status --short` -> Only documentation markdown files exist in untracked state.
- **Status:** **PASS** (Zero credentials exposed, zero accidental staging).

---

## 7. Remaining Requirements for Runtime Test

| Layer | Status | Evidence / Requirement |
|---|:---:|---|
| **Configuration** | **PASS** | Debug SHA-1/256 registered; `oauth_client` array populated with 3 entries. |
| **Cloud Provider** | **PASS** | `identitytoolkit.googleapis.com` reports `google.com` enabled (`true`). |
| **Compilation** | **PASS** | `flutter analyze` 0 issues; debug APK built successfully. |
| **Runtime Execution** | **NOT TESTED** | Requires launching an Android device/emulator with Google Play Services to tap "Đăng nhập với Google (@fpt.edu.vn)" and verify token exchange. |

### Exact Steps for Final Runtime Validation:
1. Connect physical Android device (with USB debugging) OR launch Android Studio Virtual Device with Google Play Services.
2. Run:
   ```bash
   flutter run --debug
   ```
3. On `SignInScreen`, tap **"Đăng nhập với Google (@fpt.edu.vn)"**.
4. Select Google Account -> Confirm navigation into `HomeScreen`.
5. Observe debug logs:
   ```
   [Auth] Google Sign-In succeeded for uid: <firebase-uid>
   ```
