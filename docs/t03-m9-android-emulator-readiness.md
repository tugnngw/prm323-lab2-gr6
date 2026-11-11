# T03-M9 — Android Emulator Environment Readiness Report

**Date:** 2026-11-01  
**Project:** FPTU Second Brain (`prm323-lab2-gr6` / `com.example.prm323_lab3`)  
**Firebase Project ID:** `prm323-lab2-gr6` (Project Number: `510519082861`)  
**Android Package:** `com.example.prm323_lab3`  
**Target API Level:** 34 (Android 14) / 35 (Android 15) with Google Play Services  
**Safety Status:** ENVIRONMENT AUDIT COMPLETE — No AVD with Google Play Services available. Zero cloud resources mutated.  
**Final Verdict:** **T03-M9 ENVIRONMENT UNAVAILABLE**

---

## 1. Flutter and Android SDK Environment Inspection

| Verification Item | Observed State | Status |
|---|---|---:|
| **Flutter Channel** | `stable` (3.47.5) | **PASS** |
| **OS Platform** | Windows 11 (10.0.26300.9711) | **PASS** |
| **Android SDK Version** | 37.0.0 | **PASS** |
| **Android Toolchain** | Available (`android.toolchain`) | **PASS** |
| **Chrome for Web** | Available (`chrome.develop`) | **PASS** |
| **Visual Studio for Windows** | Available (Community 2026 18.10.3) | **PASS** |
| **Network Resources** | Available | **PASS** |
| **Connected Devices** | 3 listed (Windows desktop, Chrome, Edge) | **NO Android** |
| **Flutter Doctor** | `No issues found!` | **PASS** (overall environment healthy) |

### 1.1 `flutter doctor` Output Summary
```
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.47.5, on Microsoft Windows [Version 10.0.26300.9711], locale en-US)
[√] Windows Version (Windows 11 or higher, 26H2, 2009)
[√] Android toolchain - develop for Android devices (Android SDK version 37.0.0)
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps (Visual Studio Community 2026 18.10.3)
[√] Connected device (3 available)
[√] Network resources

• No issues found!
```

**Overall Finding:** The Flutter toolchain and Android SDK are correctly installed and operational (SDK 37.0.0). No configuration issues detected.

---

## 2. AVD Availability & Google Play Services Check

| Verification Item | Observed State | Status |
|---|---|---:|
| **Available Emulators** | 1 AVD exists: `Small_Phone` (Generic, android) | **LIMITED** |
| **AVD System Image** | Platform: `android` (generic) | **MISSING Google Play Services** |
| **Google Play System Image** | Not installed for any AVD | **BLOCKED** |
| **API Level** | Android (generic) — no specific API 34/35 confirmed | **UNVERIFIED** |
| **`flutter devices` Output** | Windows (desktop), Chrome (web), Edge (web) | **NO Android target** |

### 2.1 Available Emulator Details
```
$ flutter emulators
1 available emulator:

Id          • Name        • Manufacturer • Platform
Small_Phone • Small Phone • Generic      • android
```

**Critical Gap:** The sole existing AVD (`Small_Phone`) uses a **generic Android platform image without Google Play Services**. This AVD cannot execute Google Sign-In flows (`ApiException: 10`) or rely on Firebase Auth backend integration.

### 2.2 Google Play Services Status
- No AVD has the **Google Play system image** installed.
- No AVD targets API 34 or API 35 with Google APIs.
- The `android` generic platform does not include Firebase Auth or Google Sign-In libraries pre-linked.

---

## 3. Exact Android Studio Setup Instructions

To create a suitable AVD for T03-M8 runtime verification, execute the following steps in **Android Studio**:

### Step 1: Open AVD Manager
1. Launch **Android Studio**.
2. Navigate to **More** → **AVD Manager** (or click the AVD Manager icon on the toolbar).

### Step 2: Create a New AVD
1. Click **Create Virtual Device**.
2. **Select Hardware:** Choose a device profile (e.g., **Pixel 7 Pro** recommended for optimal compatibility).
3. **System Image:** Click **Download** (or **See more system images**).
   - **Search:** `Google Play` or `Google APIs`.
   - **Target:** Select **API 34 (Android 14)** or **API 35 (Android 15)**.
   - **Installation:** Ensure **Google Play** is listed (indicates Play Services included).
   - If only "Android SDK Platform-34" appears without "Google Play," proceed to install Google Play Services manually in Step 4.
4. Click **Next**.

### Step 5: Configure AVD Settings
1. **AVD Name:** Accept default or enter a descriptive name (e.g., `T03-M8_Emulator_API34_GooglePlay`).
2. **Device Type:** Keep default.
3. **Load Level:** Keep default.
4. **Central Processing Unit (CPU):** Emulation: **Quick Boot** recommended.
5. **Memory: RAM:** Keep default (1536 MB or 2048 MB).
6. **VM Heap Size:** Keep default (256 MB or 512 MB).
7. **Skin:** Keep default.
8. **Load Orientation:** Keep default.
9. Click **Finish**.

### Step 6: Install Google Play Services (If Missing)
If the AVD was created with a generic Android image without Google Play:
1. Launch the AVD from **AVD Manager** → **Play** button.
2. Once the emulator boots, open **Settings** → **Google** → **Services**.
3. If prompted, sign in with a Google Account.
4. Open **Google Play Store** and allow it to update/install Google Play Services.
5. Alternatively, sideload the Google Apps package (open GMS installation is beyond this runbook's scope; preferred approach is creating an AVD with Google Play from the start).

### Step 7: Verify AVD Functionality
1. Launch the AVD from **AVD Manager** → **Play**.
2. Wait for the home screen to appear.
3. Verify **Google Play Store** is accessible.
4. Verify **Google Play Services** version is visible in **Settings** → **Apps** → **Google Play Services**.

### Step 8: Confirm via Flutter CLI
1. In the project terminal, run:
   ```bash
   flutter emulators --launch Small_Phone
   ```
   (or the AVD name you created).
2. Run `flutter devices` to confirm the Android target appears.
3. Proceed to T03-M8 runtime verification (`flutter run --debug`).

---

## 4. Current Environment Verdict

| Checkpoint | Outcome |
|---|---:|
| **Flutter SDK & Android Toolchain** | ✅ PASS — SDK 37.0.0 installed; `flutter doctor` reports `No issues found!`. |
| **AVD with Google Play Services** | ❌ **UNAVAILABLE** — 1 AVD exists (`Small_Phone`) but uses generic `android` platform without Google Play Services. |
| **`flutter devices` Android Target** | ❌ **NOT AVAILABLE** — No Android emulator with Google Play Services listed. |
| **T03-M8 Runtime Test** | ❌ **PENDING** — Cannot proceed until AVD created with Google Play or physical device connected. |
| **T03-M9 Environment Status** | **UNAVAILABLE** — Requires AVD creation or physical device setup. |

### 4.1 Immediate Next Action
1. Follow **Section 3** above to create a new AVD in Android Studio with a System Image that includes **Google Play** (API 34 or API 35).
2. Launch the AVD and verify `flutter devices` lists an Android target.
3. Re-run `flutter run --debug` to enable T03-M8 runtime verification flows.
4. Report findings to the assistant; T03-M9 will transition from UNAVAILABLE → environment ready → T03-M8 runtime test can proceed.

**No further T03 steps can advance until an Android target with Google Play Services is available.**

---

## 5. Summary

The Flutter and Android SDK environment is healthy (doctor passes, SDK 37 available). However, the sole existing AVD lacks Google Play Services, preventing any Firebase Auth or Firestore runtime testing. Project owner must create a new AVD with a Google Play system image (API 34/35) via Android Studio, then launch it and verify `flutter devices` lists the Android target. After this setup, T03-M8 runtime verification can commence.

**T03 Task Chain Status:**
- T03-M1 through T03-M7: All completed with deliverables authored.
- T03-M8: **BLOCKED** — awaiting Android device/emulator.
- T03-M9: **ENVIRONMENT UNAVAILABLE** — AVD must be created with Google Play Services before T03-M8 can start.

**Next Action:** Project owner creates AVD in Android Studio with Google Play system image (API 34/35), launches it, confirms `flutter devices` shows Android target, then proceeds to T03-M8 runtime verification.

Sources:
- `flutter doctor -v` output (above).
- `flutter emulators` output (above).
- `flutter doctor` summary (above).
- Android Studio AVD creation guide (Section 3).