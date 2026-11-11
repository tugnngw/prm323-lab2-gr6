> **Yêu cầu chấm mới.** Cần chạy trên thiết bị Android thật. [Web admin](../admin-web/README.md) đã đọc Crashlytics thật qua REST. Cloudinary có adapter PDF và consent, chờ cấu hình để xác minh upload thật. ARTEMIS TC_11 pass 1 lượt trên emulator. Slide để sau. [Chi tiết và bằng chứng](implementation-verification-2026-11-05.md).

> 05/11/2026 — Giữ Spark, dùng PDF cục bộ. Upload Storage còn thiếu trong rubric. [Kết quả kiểm tra nhẹ](implementation-verification-2026-11-05.md).

> Cập nhật tiếp 04/11: 114 Flutter tests, analyzer sạch, APK/PDF cục bộ và menu chia sẻ đã xác minh. FCM ba trạng thái + cold deep link, RC 31→30 cùng APK và dashboard Crashlytics đã có evidence. Upload Storage còn thiếu bucket/billing; ARTEMIS đủ số lượt chưa đạt (quota). Chi tiết: docs/implementation-verification-2026-11-04.md.

> Cập nhật tiếp hạng mục 1–2–3 ngày 04/11/2026: xem [báo cáo xác minh mới](implementation-verification-2026-11-04.md). Đã thêm nhập dữ liệu học tập riêng, Advisor/Strategy theo dữ liệu, tab môn và route FCM. Cloud evidence/E2E vẫn có blocker thực; checklist cũ không chứng minh hoàn tất.

# PRM393 Lab 3 — Checklist triển khai

> **Mục tiêu:** Hoàn thiện ứng dụng Flutter Cloud-Enabled Mobile App, tích hợp Firebase, kiểm thử E2E bằng Google ARTEMIS, AI Code Review và đầy đủ evidence.
>
> **Quy ước trạng thái:** `[ ]` Chưa làm · `[-]` Đang làm · `[x]` Hoàn thành · `[!]` Cần xử lý lại
>
> **Thông tin bài:** Nhóm: `GR6` · Repository: `PRM393_Final_GR6` · Ngày cập nhật: `11/11/2026`
>
> **Trạng thái tiến độ:**
> - **Code:** Các tính năng chính được ghi nhận là đã triển khai; đây là chỉ số nội bộ, không phải điểm rubric.
> - **Kiểm thử local gần nhất:** `flutter test` 89/89 pass. Analyzer đã phát hiện lỗi trong helper PDF không dùng; helper đã bị gỡ và phải chạy lại analyze/build trước khi xác nhận trạng thái mới.
> - **Rubric chính thức:** Thang 10 điểm: Functional 2.50, Firebase 2.00, Architecture 0.75, UI/UX 0.75, ARTEMIS 1.50, AI Code Review 0.50, Slides 1.00, Video 1.00. Report là tài liệu evidence bắt buộc, không có điểm riêng. Tổng điểm chưa chốt vì thiếu runtime/reviewer evidence.
> - Báo cáo `report/PRM393_LAB3_GR6.pdf` 10 trang; slide `slides/PRM393_LAB3_GR6.pdf` 14 slide.

---

## 0. Definition of Done

- [ ] Ứng dụng chạy được trên thiết bị Android thật.
- [ ] Không còn mock/hard-coded data trong luồng chính; dữ liệu đọc/ghi từ Firestore hoặc API thật.
- [ ] Có tối thiểu 8 màn hình chính của Lab 2 + Sign-in + Profile/Settings.
- [ ] Ba User Flow chạy hoàn chỉnh, gồm nhánh lỗi và phục hồi.
- [ ] Có Firebase Auth, Firestore, Storage, FCM, Analytics, Crashlytics và Remote Config.
- [ ] Có trạng thái Loading, Empty, Error/Retry và Data cho các màn hình tải dữ liệu.
- [ ] Kiến trúc View → ViewModel → Service/Repository → Firebase/API được giữ đúng.
- [ ] Có tối thiểu 10 test ARTEMIS; mỗi test chạy ít nhất 3 lần.
- [ ] Có ít nhất 5 AI Code Review findings và sửa ít nhất 3 findings bằng 3 commit riêng.
- [ ] Có đầy đủ evidence trong `evidence/`.
- [ ] Có Report PDF 8–12 trang, Slide PDF 12–15 trang và video demo 5–10 phút.
- [ ] Repository public, README có hướng dẫn chạy, test và link video.
- [ ] Không commit secret, service account hoặc private API key.

---

## 1. Chuẩn bị và phạm vi Lab 2

### 1.1. Xác định phạm vi

- [ ] Đọc lại bản Lab 2 cuối cùng.
- [ ] Đọc toàn bộ nhận xét của giảng viên.
- [ ] Chốt 3 personas: năm 1, năm 3 và năm cuối/ngành khác.
- [ ] Chốt 3 User Flow chính.
- [ ] Liệt kê các tính năng Core dùng chung cho mọi persona.
- [x] Chốt định danh nhóm GR6, repository `PRM393_Final_GR6` và tên package/app.
- [ ] Xác định thiết bị Android dùng để demo và test.

### 1.2. Cập nhật Figma

- [ ] Đổi mã màn hình sang cấu trúc phân cấp.
- [ ] Bổ sung Sign-in.
- [ ] Bổ sung Profile/Settings.
- [ ] Bổ sung Firebase Demo Area.
- [ ] Bổ sung màn hình Strategy Simulator.
- [ ] Bổ sung dialog `DLG-04.1_ShareConsent`.
- [ ] Áp dụng giao diện tối giản: card trắng, ít màu, có leading icon.
- [ ] Kiểm tra layout ở độ rộng 360 dp và 412 dp.
- [ ] Đồng bộ tên Frame với route trong app.
- [ ] Chụp ảnh Figma làm evidence.

---

## 2. Khởi tạo repository và cấu trúc dự án

- [x] Tạo repository public: `PRM393_Final_GR6`. — Đã đổi tên repo nhóm và push
- [x] Khởi tạo hoặc kiểm tra Flutter project. — `pubspec.yaml` (Flutter 3.47.5, Dart 3.13.4, name: prm323_lab3)
- [x] Ghim phiên bản Flutter/Dart trong README. — `README.md:14` (Flutter 3.47.5, Dart 3.13.4)
- [x] Ghim version các package trong `pubspec.yaml`. — Pinned caret/exact versions cho mọi dependency
- [x] Tạo cấu trúc thư mục chuẩn: — Đầy đủ `lib/` (theme, models, services, firebase, viewmodels, screens, widgets, utils) và root (`firebase/`, `e2e_test/`, `docs/`, `evidence/`, `report/`, `slides/`)

```text
lib/
├── theme/
├── models/
├── services/
├── firebase/
├── viewmodels/
├── screens/
├── widgets/
└── utils/

firebase/
e2e_test/
docs/
evidence/
report/
slides/
```

- [x] Tạo `README.md`. — Có sẵn, cập nhật đầy đủ bảng tính năng, 89 test, lệnh chạy
- [x] Tạo `.gitignore` đúng cho Flutter, Firebase và Python. — Bỏ qua `.env`, keystore, build artifacts
- [x] Kiểm tra không commit secret/API key cá nhân. — Không có service account private key trong repo
- [ ] Tạo commit giai đoạn Plan. — Không tự tạo commit khi chưa có yêu cầu từ user

---

## 3. Giai đoạn Plan — Design Traceability

### 3.1. File bắt buộc

- [x] Tạo `docs/design-traceability.md`. — Đầy đủ bảng truy vết màn hình, flows, và 9 nhóm widgets

### 3.2. Bảng truy vết màn hình

- [x] Mapping mã màn hình Lab 2 → Flutter route. — `docs/design-traceability.md:7-19`
- [x] Mapping route → Screen Widget. — `docs/design-traceability.md:7-19`
- [x] Mapping screen → ViewModel. — `docs/design-traceability.md:7-19`
- [x] Mapping ViewModel → Firestore collection/API. — `docs/design-traceability.md:7-19`
- [x] Mapping screen → test case tương ứng. — `docs/design-traceability.md:7-19`

### 3.3. Bảng truy vết User Flow

- [x] Flow 1: Curriculum, môn tiên quyết và Course Detail. — `docs/design-traceability.md:24-29`
- [x] Flow 2: Study Plan, task và notes. — `docs/design-traceability.md:30-35`
- [x] Flow 3: Advisor, lỗi/phục hồi và Strategy Simulator. — `docs/design-traceability.md:36-41`
- [x] Ghi nhánh thay thế. — `docs/design-traceability.md:24-41`
- [x] Ghi nhánh lỗi. — `docs/design-traceability.md:27,33,39`
- [x] Ghi nhánh phục hồi. — `docs/design-traceability.md:27,33,39`

### 3.4. Bảng truy vết components

- [x] Mapping 9 nhóm component Lab 2 → reusable widgets. — `docs/design-traceability.md:46-59`
- [x] Ghi variant/state của từng widget. — `docs/design-traceability.md:46-59`
- [x] Ghi Semantics label của widget tương tác chính. — `docs/design-traceability.md:46-59`

### 3.5. Thay đổi so với Lab 2

- [x] Ghi thay đổi màn hình. — Bổ sung SignInScreen, CourseDetailScreen, AdvisorScreen, StrategySimScreen, SyncVaultScreen
- [x] Ghi thay đổi navigation. — Chuyển BottomNav 4 tab + named routes
- [x] Ghi thay đổi màu sắc/design token. — Material 3 seed color `AppColors.primary`, bổ sung `AppElevation`, `AppFontSize`, `AppSpacing` tokens
- [x] Ghi lý do kỹ thuật/UX cho từng thay đổi. — Đáp ứng rubric Lab 3 (Firebase integration, MVVM, accessibility)
- [ ] Cập nhật lại Figma và kiểm tra tính nhất quán. — Thuộc phần việc design/Figma, cần screenshot Figma thật
- [ ] Chụp ảnh Figma làm evidence. — Chờ screenshot Figma từ user

---

## 4. Giai đoạn Architect — MVVM và Design System

### 4.1. MVVM

- [x] Tạo `docs/architecture.md`. — Có sẵn, mô tả chi tiết MVVM 4 tầng
- [x] Mô tả cây thư mục và trách nhiệm từng thư mục. — `docs/architecture.md:62-118`
- [x] Vẽ sơ đồ MVVM bằng Mermaid. — `docs/architecture.md:8-20`
- [x] Vẽ sequence diagram cho một User Flow hoàn chỉnh. — `docs/architecture.md:25-58` (Google Auth flow)
- [x] Lập bảng ViewModel → Service sử dụng. — `docs/architecture.md:120-130`
- [x] Đảm bảo Widget không gọi trực tiếp Firebase SDK. — Không có import `package:firebase_*` trong `lib/screens` và `lib/widgets`
- [x] Đảm bảo Widget không gọi trực tiếp HTTP/API. — Không có `package:http` hay `package:dio` trong codebase
- [x] Đảm bảo không có business logic trong `build()`. — Mọi thao tác ghi/tính toán chuyển sang ViewModel
- [x] Đảm bảo không dùng global mutable state. — Sử dụng Provider pattern, không có global static variable
- [x] Thiết lập Provider hoặc Riverpod. — `provider: ^6.1.2`, cấu hình tại `lib/main.dart:129-214`
- [x] Inject Service/Repository vào ViewModel. — `MultiProvider` inject `AuthService`, `FirestoreService`, v.v. vào từng ViewModel

### 4.2. State Model

- [x] Định nghĩa state `Loading`. — `ViewState.loading` trong `lib/models/app_state.dart`
- [x] Định nghĩa state `Empty`. — `ViewState.empty` trong `lib/models/app_state.dart`
- [x] Định nghĩa state `Error(message, retry)`. — `ViewState.error` + `AppErrorState(message, onRetry)` trong `lib/widgets/app_states.dart`
- [x] Định nghĩa state `Data/Populated`. — `ViewState.data` trong `lib/models/app_state.dart`
- [x] Mỗi màn hình tải dữ liệu có state model riêng hoặc dùng model chuẩn. — `AsyncViewState<T>` chuẩn áp dụng trên `RoadmapScreen`, `TasksScreen`, `NotesScreen`, `CourseDetailScreen`

### 4.3. Theme tokens

- [x] Định nghĩa `ColorScheme`. — `AppColors` (`lib/theme/app_colors.dart`) + `ColorScheme.fromSeed` (`lib/theme/app_theme.dart:8-28`)
- [x] Định nghĩa `TextTheme`. — `AppTheme.light()` (`lib/theme/app_theme.dart:29-38`)
- [x] Định nghĩa `AppSpacing`. — `lib/theme/app_spacing.dart:1-12` (hairline, xxs, micro, xs, sm, md, lg, xl, xxl)
- [x] Định nghĩa `AppRadius`. — `lib/theme/app_spacing.dart:14-21` (xs, sm, md, lg, xl, full)
- [x] Định nghĩa elevation/shadow tokens. — `AppElevation` (`lib/theme/app_spacing.dart:25-28`: flat = 0, overlay = 6)
- [x] Loại bỏ màu hard-code khỏi screen/widget. — Toàn bộ màu trong `lib/screens` và `lib/widgets` dùng `AppColors.*`
- [x] Loại bỏ kích thước lẻ tẻ không có token. — Kích thước spacing dùng `AppSpacing.*`, font size bổ sung dùng `AppFontSize.*`

### 4.4. Reusable widgets

- [x] `AppButton`. — `lib/widgets/app_button.dart` (Semantics button + label)
- [x] `AppTextField`. — `lib/widgets/app_text_field.dart` (+ `AppSearchBar`)
- [x] `AppCard`. — `lib/widgets/app_components.dart` (optional `semanticLabel`)
- [x] `AppBottomNav`. — `lib/widgets/app_navigation.dart`
- [x] `CustomAppBar`. — `lib/widgets/app_components.dart`
- [x] `AppConfirmDialog`. — `lib/widgets/app_components.dart`
- [x] `AppLoadingState`. — `lib/widgets/app_states.dart`
- [x] `AppEmptyState`. — `lib/widgets/app_states.dart`
- [x] `AppErrorState`. — `lib/widgets/app_states.dart`
- [x] Thêm Semantics cho button, input, card, tab và navigation. — button/input/card/banner đã có `Semantics`; nav dùng `NavigationDestination` (label sẵn), cấp tư vấn dùng `ChoiceChip` (label sẵn). Chart: app không có chart.
- [ ] Tạo commit giai đoạn Architect.

---

## 5. Giai đoạn Integrate — Firebase và Authentication

### 5.1. Firebase project

- [x] Tạo Firebase Project ở Spark Plan. — Project `prm323-lab2-gr6`
- [x] Đăng ký Android app. — Package `com.example.prm323_lab3`
- [x] Chạy FlutterFire CLI. — Đã sinh `lib/firebase/firebase_options.dart`
- [x] Thêm `android/app/google-services.json`. — File có sẵn trong `android/app/`
- [x] Kiểm tra `Firebase.initializeApp()`. — `lib/main.dart:58` với `FirebaseConfigErrorApp` xử lý lỗi cấu hình
- [x] Kiểm tra build Android sạch. — `flutter build apk --debug` exit code 0

### 5.2. Google Authentication

- [ ] Bật Google provider trong Firebase Authentication. — Cần thao tác Firebase Console
- [ ] Cấu hình SHA-1/SHA-256 cho Android. — Cần cấu hình trên Firebase Console
- [x] Tạo `AuthService`. — `lib/services/auth_service.dart` + `FirebaseAuthService`
- [x] Implement Google Sign-In. — `hostedDomain: 'fpt.edu.vn'`, lọc domain FPT
- [x] Implement auth state stream/routing. — `AuthGate` trong `lib/main.dart:316-364`
- [x] Chưa đăng nhập → Sign-in. — Chuyển đến `SignInScreen`
- [x] Đã đăng nhập → Home. — Chuyển đến `HomeScreen`
- [x] Hủy chọn tài khoản → thông báo rõ ràng. — Bắt lỗi hủy trong `AuthViewModel`
- [x] Mất mạng → Error state, không crash. — Bắt network error, hiển thị thông báo lỗi
- [x] Đăng xuất → xóa dữ liệu cục bộ và quay về Sign-in. — `AuthViewModel.signOut()` reset state
- [ ] Chụp evidence Auth State. — Cần máy thật chụp màn hình

### 5.3. Firestore

- [x] Tạo collection `users/{uid}`. — Cấu trúc dữ liệu theo uid người dùng
- [x] Tạo collection `courses`. — Catalog môn học
- [x] Tạo collection `curriculums`. — Khung chương trình
- [x] Tạo collection cho study plan/tasks. — `users/{uid}/tasks`
- [x] Tạo collection cho notes. — `users/{uid}/notes`
- [x] Tạo collection cho notifications. — `users/{uid}/notifications`
- [x] Tạo collection cho reports metadata. — `users/{uid}/reports`
- [x] Seed dữ liệu kiểm thử không chứa thông tin cá nhân thật. — `firebase/seed_data.json` và `docs/seed-courses.json`
- [x] Tạo `FirestoreService`/repositories. — `lib/services/firestore_service.dart` + `FirebaseFirestoreService`
- [ ] Kiểm tra read/write bằng user test account. — Cần tài khoản test và mạng
- [x] Tạo `firebase/firestore.rules`. — File rules chuẩn trong `firebase/`
- [x] Chặn truy cập khi chưa đăng nhập. — `request.auth != null`
- [x] Giới hạn dữ liệu user theo `uid`. — `request.auth.uid == userId`
- [ ] Kiểm tra rules bằng Firebase Emulator hoặc test thủ công. — Cần chạy emulator
- [x] Không dùng `allow read, write: if true`. — Đã quét xác nhận 0 vi phạm

### 5.4. Storage

- [x] Tạo `StorageService`. — `lib/services/storage_service.dart` + `FirebaseStorageService`
- [x] Tạo đường dẫn `reports/{uid}/...`. — `report_export_service.dart:62`
- [x] Tạo `firebase/storage.rules`. — File rules chuẩn trong `firebase/`
- [x] Chỉ cho user đọc/ghi thư mục của chính họ. — `request.auth.uid == userId`
- [x] Kiểm tra không có `allow read, write: if true`. — Đã quét xác nhận 0 vi phạm
- [ ] Tạo commit giai đoạn Integrate. — Chờ lệnh commit từ user

---

## 6. Giai đoạn Features — Màn hình và User Flows

### 6.1. Màn hình bắt buộc

- [x] `SCR-00.1_AuthSetup` / Sign-in.
- [x] `SCR-01.0_Home`.
- [x] `SCR-01.1_SyncSettings` hoặc Settings.
- [x] `SCR-02.0_Curriculum`.
- [x] `SCR-02.1_CourseDetail`.
- [x] `SCR-03.0_StudyPlan`.
- [x] `SCR-03.1_NoteEditor`.
- [x] `SCR-03.2_NotesVault`.
- [x] `SCR-04.0_AdvisorHub`.
- [x] `SCR-04.1_StrategySim`.
- [x] Profile/Settings với Firebase Demo Area.

### 6.2. Flow 1 — Curriculum

- [x] Hiển thị danh sách môn từ Firestore/API.
- [x] Tìm kiếm môn học.
- [x] Empty state khi không có kết quả.
- [x] Lọc `Kiểm tra môn tiên quyết`.
- [x] Đối chiếu với bảng điểm người dùng.
- [x] Cảnh báo môn chưa đạt.
- [x] Mở Course Detail.
- [x] Hiển thị đề cương/slot/điều kiện tiên quyết.
- [x] Xử lý Loading, Error và Retry.
- [x] Ghi Analytics event tìm kiếm và xem chi tiết.

### 6.3. Flow 2 — Study Plan và Notes

- [x] Hiển thị kế hoạch học tập từ Firestore.
- [x] Hiển thị lịch slot và bảng điểm liên quan.
- [x] Tạo task.
- [x] Sửa task.
- [x] Đánh dấu task hoàn thành.
- [x] Tạo note.
- [x] Sửa note.
- [x] Xóa note nếu có trong thiết kế.
- [x] Hiển thị Notes Vault.
- [x] Xử lý Empty/Error/Retry.
- [x] Ghi Analytics event hành động chính.

### 6.4. Flow 3 — Advisor và Strategy

- [x] Hỏi đáp theo cấp độ môn học. — `AdvisorLevel.course`, `_courseReply`
- [x] Hỏi đáp theo cấp độ kỳ học. — `AdvisorLevel.semester`, `_semesterReply`
- [x] Hỏi đáp theo cấp độ chương trình. — `AdvisorLevel.program`, `_programReply`
- [x] Hỏi đáp theo cấp độ điểm số. — `AdvisorLevel.score`, `_scoreReply`; UI selector: 4 `ChoiceChip` trong `advisor_screen.dart`
- [x] Phân tích học đi/học lại. — `_programReply` (môn học đi/học lại) + `RoadmapViewModel.isEligibleForCourse`
- [x] Dùng bảng điểm và slot trống. — `CourseModel.completedSlots/totalSlots` hiển thị ở Course Detail; bảng điểm thật không lưu (không bịa) — Advisor nói rõ điều này
- [x] Hiển thị nhánh lỗi. — `AdvisorViewModel.errorMessage` + bubble lỗi + thanh lỗi trong screen
- [x] Cho phép Retry/phục hồi. — `retryLastQuestion()` + nút "Thử lại"
- [x] Hiển thị dialog xin quyền chia sẻ dữ liệu. — `_askConsent()` trong `advisor_screen.dart`; `askQuestion` **fail closed** khi chưa consent
- [x] Ghi Analytics event xem/tạo strategy.

### 6.5. PDF export và upload

- [x] Dùng package `pdf`/`printing`. — `pubspec.yaml:49-50`; `lib/services/report_pdf_service.dart`
- [x] Tạo PDF từ dữ liệu thật đang hiển thị. — `sync_vault_screen.dart` reload Roadmap/Tasks/Notes rồi truyền vào `exportStudyReport`
- [x] Có tiêu đề, thời gian và nội dung báo cáo. — `_buildTitle(uidHint, generatedAt)` + 3 section
- [x] Hiển thị Share Consent trước khi lưu/chia sẻ. — `_askExportConsent()` gọi trước `exportStudyReport`; từ chối → return, không upload
- [ ] Lưu file cục bộ nếu cần. — hiện chỉ giữ PDF trong bộ nhớ (share sheet); rubric ghi "nếu cần", không bắt buộc
- [x] Upload lên `reports/{uid}/study_report_<timestamp>.pdf`. — `report_export_service.dart:62`
- [x] Hiển thị upload progress. — `onProgress` → `LinearProgressIndicator` + `%`
- [x] Hiển thị Download URL. — `SelectableText(_exportResult!.downloadUrl)`
- [x] Mở/chia sẻ file trên thiết bị. — `_openLastReport()` → `Printing.sharePdf`
- [x] Lưu metadata vào Firestore. — `saveReportMetadata(userId, {...})` fileName/storagePath/downloadUrl/sizeBytes/generatedAt/counts/source
- [x] Ghi event `export_report`. — `logExportReport(status:, fileSizeKb:, durationMs:)`
- [ ] Chụp evidence PDF, progress và Storage URL. — **chưa có**: cần device + Storage bucket, chưa chạy

### 6.6. Firebase Demo Area

- [x] Notification Center. — `lib/screens/notifications_screen.dart` + route `/notifications`
- [x] Nút Export & Upload PDF. — `sync_vault_screen.dart` AppCard "Export & Upload PDF"
- [x] Hiển thị Download URL. — `SelectableText(_exportResult!.downloadUrl)` + `storagePath`
- [x] Hiển thị Remote Config hiện hành.
- [x] Nút refresh Remote Config.
- [x] Nút gửi Crashlytics non-fatal.
- [x] Nút test Firestore read/write roundtrip.
- [x] ✅ Hoàn thành Firebase Demo Area (sync_vault_screen.dart).

---

## 7. Giai đoạn Instrument — Firebase Services

### 7.1. Analytics

- [x] Tạo `docs/analytics-plan.md`. — Có sẵn, mô tả chi tiết 13 custom events
- [x] Lập kế hoạch tối thiểu 7 events. — Đã lập 13 events vượt yêu cầu (7/7 bắt buộc + 6 mở rộng)
- [x] Mỗi event có trigger. — Bảng trigger cụ thể trong `docs/analytics-plan.md`
- [x] Mỗi event có parameters và kiểu dữ liệu. — Tham số chuẩn hóa, kiểu int/string
- [x] Mỗi event ánh xạ tới User Flow. — Ánh xạ Flow 1/2/3 và Vault flow
- [x] Mỗi event có product question. — Mục đích phân tích rõ ràng
- [x] Không gửi tên/email hoặc dữ liệu cá nhân. — Đã kiểm tra code, chỉ gửi course_id, query_length, category, error_type
- [x] Gọi `setUserId(uid)` sau login. — `AuthViewModel._handleAuthStateChanged` gọi `_analyticsService.setUserId(user.uid)`
- [ ] Bật Analytics Debug Mode. — Cần thiết bị Android + `adb shell setprop debug.firebase.analytics.app`
- [ ] Kiểm tra events trên DebugView. — Cần thao tác trên máy thật
- [ ] Chụp DebugView cho toàn bộ event. — Cần Firebase Console thật
- [ ] Lưu ảnh tại `evidence/firebase/analytics/`. — Chờ chụp từ Console

### 7.2. Crashlytics

- [x] Gọi `setUserIdentifier`. — `AuthViewModel` gọi `_crashlyticsService.setUserId(user.uid)`
- [x] Thiết lập ít nhất 1 custom key. — `_crashlyticsService.setCustomKey('auth_method', 'google')`
- [x] Ghi nhận non-fatal từ lỗi thật. — `FlutterError.onError` và `PlatformDispatcher.instance.onError` tự động ghi nhận
- [x] Gửi test crash chủ động. — Nút "Gửi test Crashlytics non-fatal" trong `SyncVaultScreen`
- [ ] Kiểm tra Dashboard. — Cần Firebase Console thật
- [ ] Chụp evidence có User ID và custom key. — Cần Firebase Console thật
- [ ] Lưu ảnh tại `evidence/firebase/crashlytics/`. — Chờ chụp từ Console

### 7.3. Remote Config

- [x] Chọn tham số boolean để bật/tắt tính năng. — `maintenance_mode`, `feature_ai_advisor_enabled`
- [x] Chọn tham số int/string thay đổi UI hoặc hành vi. — `min_app_version`, `banner_message`, `sync_interval_seconds`
- [x] Tạo giá trị mặc định trong app. — `RemoteConfigService._defaultParameters`
- [x] Tạo `firebase/remote-config-defaults.json`. — File có sẵn trong `firebase/`
- [x] Fetch và activate config. — `RemoteConfigService.initialize()` gọi `fetchAndActivate()`
- [x] Hiển thị giá trị trong Firebase Demo Area. — `SyncVaultScreen` hiển thị toàn bộ giá trị Remote Config hiện hành
- [ ] Chụp trạng thái trước khi đổi Console. — Cần Firebase Console thật
- [ ] Đổi giá trị trên Console. — Cần Firebase Console thật
- [ ] Chụp trạng thái sau khi đổi không build lại. — Cần Firebase Console thật

### 7.4. FCM

- [x] Xin notification permission Android 13+. — `FirebaseMessagingService.requestNotificationPermissions()`
- [x] Lấy và xử lý FCM token. — `FirebaseMessagingService.initialize()` lưu token vào `users/{uid}/tokens`
- [x] Xử lý foreground message. — `FirebaseMessaging.onMessage.listen` hiển thị `ForegroundPushBanner`
- [x] Xử lý background message. — `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`
- [x] Xử lý terminated message. — `FirebaseMessaging.instance.getInitialMessage()` trong `main.dart`
- [x] Lưu notification vào Notification Center. — `NotificationsViewModel.addNotification()` lưu vào danh sách & Firestore
- [x] Tap notification mở màn hình liên quan. — `_handleNotificationTap` điều hướng theo route/course_id
- [ ] Chụp evidence cả 3 trạng thái. — Cần device nhận push notification thật
- [ ] Tạo commit giai đoạn Instrument. — Chờ lệnh commit từ user

---

## 8. Giai đoạn Test — Google ARTEMIS E2E

### 8.1. Môi trường

- [ ] Cài Python 3.12+.
- [ ] Cài `uv`.
- [ ] Cài và kiểm tra ADB.
- [ ] Kết nối thiết bị Android.
- [ ] Cài Google ARTEMIS.
- [ ] Ghim commit/version ARTEMIS trong README.
- [ ] Cấu hình model API key qua environment variable.
- [ ] Tạo Google test account riêng.
- [ ] Không ghi API key/account secret vào repository.

### 8.2. Test plan

- [ ] Tạo `docs/test-plan.md`.
- [ ] Liệt kê màn hình và flow được kiểm thử.
- [ ] Viết TC-01: Google Sign-In native interaction.
- [ ] Viết TC-02: Auth state routing.
- [ ] Viết TC-03: Curriculum flow.
- [ ] Viết TC-04: Search course.
- [ ] Viết TC-05: Prerequisite check.
- [ ] Viết TC-06: Study Plan.
- [ ] Viết TC-07: Notes.
- [ ] Viết TC-08: Advisor/Strategy.
- [ ] Viết TC-09: Error/Empty path.
- [ ] Viết TC-10: PDF export/upload.
- [ ] Viết TC-11: Remote Config.
- [ ] Viết TC-12: Logout.
- [ ] Viết TC-13: FCM notification.
- [ ] Viết TC-14: Analytics evidence.
- [ ] Mỗi test có command tự nhiên.
- [ ] Mỗi test có expected result cụ thể.
- [ ] Mỗi test assert dữ liệu cấu trúc thực tế.

### 8.3. Test code

- [ ] Tạo `e2e_test/pyproject.toml`.
- [ ] Tạo `e2e_test/conftest.py`.
- [ ] Tạo `test_auth.py`.
- [ ] Tạo `test_curriculum_flow.py`.
- [ ] Tạo `test_study_plan_flow.py`.
- [ ] Tạo `test_advisor_error_flow.py`.
- [ ] Tạo `test_export_profile.py`.
- [ ] Dùng profile Flash cho regression test.
- [ ] Dùng profile Pro cho exploratory session.
- [ ] Assert tên môn/số lượng môn/trạng thái upload/config value.
- [ ] Có ít nhất một test kiểm tra Analytics event.
- [ ] Chạy mỗi test ít nhất 3 lần.
- [ ] Ghi pass rate từng test.
- [ ] Ghi thời gian trung bình.
- [ ] Điều tra test flaky.
- [ ] Sửa flaky test hoặc ghi rõ nguyên nhân.
- [ ] Lưu trace ID từng lần chạy.
- [ ] Lưu screenshot/replay/video.
- [ ] Lưu tại `evidence/artemis/`.

### 8.4. Exploratory session

- [ ] Thực hiện session không kịch bản 15–30 phút.
- [ ] Dùng profile Pro.
- [ ] Ghi thời gian bắt đầu/kết thúc.
- [ ] Ghi các vấn đề phát hiện.
- [ ] Ghi cách tái hiện.
- [ ] Ghi severity và trạng thái xử lý.
- [ ] Tạo commit giai đoạn Test.

---

## 9. Giai đoạn Review — AI Code Review

- [ ] Tạo Pull Request trên GitHub.
- [ ] Chạy CodeRabbit/Copilot Code Review/SonarCloud/Kodus hoặc công cụ được chọn.
- [ ] Lưu kết quả output/screenshot.
- [ ] Tạo `docs/code-review.md`.
- [ ] Ghi CR-01.
- [ ] Ghi CR-02.
- [ ] Ghi CR-03.
- [ ] Ghi CR-04.
- [ ] Ghi CR-05.
- [ ] Mỗi finding có file:line.
- [ ] Bao phủ ít nhất 2 loại vấn đề:
  - [ ] MVVM/architecture.
  - [ ] Security.
  - [ ] Logic/bug.
  - [ ] Performance.
  - [ ] Testing.
  - [ ] Maintainability.
- [ ] Quyết định từng finding: Accepted/Modified/Rejected.
- [ ] Ghi lý do kỹ thuật.
- [ ] Sửa CR-01 bằng commit riêng.
- [ ] Sửa CR-02 bằng commit riêng.
- [ ] Sửa CR-03 bằng commit riêng.
- [ ] Commit message chứa ID, ví dụ `fix(CR-01): ...`.
- [ ] Gắn link commit vào bảng review.
- [ ] Tạo commit giai đoạn Review.

---

## 10. Evidence và quản lý bằng chứng

### 10.1. Cấu trúc evidence

```text
evidence/
├── app/
├── firebase/
│   ├── auth/
│   ├── firestore/
│   ├── storage/
│   ├── analytics/
│   ├── crashlytics/
│   ├── remote-config/
│   └── fcm/
├── artemis/
├── code-review/
├── figma/
└── video/
```

### 10.2. Kiểm tra evidence

- [ ] Mỗi rubric item có ít nhất một evidence tương ứng.
- [ ] Tên file evidence có mã nội dung và ngày.
- [ ] Screenshot đọc được, không bị cắt thông tin quan trọng.
- [ ] Có chú thích ngắn cho từng screenshot.
- [ ] Có trace ID/test name cho ARTEMIS.
- [ ] Có log/ảnh DebugView.
- [ ] Có log/ảnh Crashlytics.
- [ ] Có ảnh trước/sau Remote Config.
- [ ] Có ảnh Storage path và Download URL.
- [ ] Có ảnh AI review findings.
- [ ] Không đưa secret vào screenshot hoặc log.

---

## 11. Giai đoạn Report — Báo cáo, Slide, Video

### 11.1. Final Report — 8–12 trang

- [x] Tạo `report/PRM393_LAB3_GR6.pdf`. — Đã tạo qua `tool/generate_report_pdf.dart`
- [x] Tổng quan dự án và tóm tắt Lab 2. — Mục §1 (trang 2)
- [x] Design Traceability. — Mục §1.2 & §9 (trang 2, trang 10)
- [x] Lý do thay đổi thiết kế. — Chuyển từ mock data sang Cloud-enabled
- [x] Kiến trúc MVVM thực tế. — Mục §2.1 (trang 3)
- [x] Design System trong code. — Mục §2.3 (trang 3)
- [x] Mô tả 6 nhóm/dịch vụ Firebase. — Mục §4 & §5 (trang 5, trang 6)
- [x] Cách xử lý lỗi của từng dịch vụ. — Fail-loud & Retry (trang 3, trang 5, trang 6)
- [x] Analytics event plan. — Mục §5.1 (trang 6)
- [ ] Analytics DebugView evidence. — Ảnh Console còn chờ
- [ ] Crashlytics dashboard evidence. — Ảnh Console còn chờ
- [ ] Remote Config before/after evidence. — Ảnh Console còn chờ
- [ ] FCM delivery evidence. — Ảnh device/Console còn chờ
- [x] ARTEMIS test plan. — Mục §7.1 (trang 8, bảng 10 kịch bản chính)
- [ ] Bảng kết quả chạy 3 lần. — Trạng thái BLOCKED do Gemini Quota 429 (`evidence/artemis/RUN_LOG_2026-11-04.md`)
- [ ] Exploratory session. — Chờ chạy khi có quota ARTEMIS
- [ ] AI Code Review findings và decisions đủ điều kiện rubric. — Chưa có tool output/file:line/decision evidence
- [x] Khó khăn, bài học và công cụ AI sử dụng. — Mục §9.1 (trang 10)
- [x] Kiểm tra độ dài 8–12 trang. — Xác minh chính xác **10 trang** qua `tool/verify_pdfs.dart`

### 11.2. Slides — 12–15 trang

- [x] Tạo `slides/PRM393_LAB3_GR6.pdf` (kèm bản `.pptx`). — Slide Lab 3 của nhóm
- [x] Mỗi slide có một thông điệp chính. — Cấu trúc tiêu đề + danh mục + footer đồng nhất
- [x] Tổng quan sản phẩm. — Slide 1 & Slide 2
- [x] So sánh Figma và app thật. — Slide 2 & Slide 5
- [x] 3 User Flow. — Slide 2 & Slide 5
- [x] Sơ đồ MVVM. — Slide 3
- [-] Firestore/Auth/Storage. — Nội dung có; ảnh chứng minh runtime còn chờ
- [-] FCM. — Nội dung có; ảnh delivery runtime còn chờ
- [-] Analytics/DebugView. — Nội dung có; ảnh DebugView còn chờ
- [-] Crashlytics. — Nội dung có; ảnh dashboard còn chờ
- [-] Remote Config. — Nội dung có; ảnh before/after còn chờ
- [ ] ARTEMIS test result. — Slide 14 ghi nhận thực trạng hạ tầng sẵn sàng & sự cố Quota 429
- [ ] AI Code Review result có evidence. — Slide 15 phải ghi trạng thái pending cho đến khi có review thật
- [x] Kết luận. — Slide 15
- [x] Kiểm tra độ dài 12–15 slides. — Xác minh chính xác **15 slides** qua `tool/verify_pdfs.dart`

### 11.3. Video demo — 5–10 phút

- [ ] Video để chế độ public/link có thể truy cập.
- [ ] Mở Firebase Console song song khi demo.
- [ ] Demo Google Sign-In.
- [ ] Demo 3 User Flow.
- [ ] Demo nhánh lỗi và Retry.
- [ ] Demo tạo PDF.
- [ ] Demo upload Storage và Download URL.
- [ ] Demo FCM notification.
- [ ] Demo Remote Config trước/sau.
- [ ] Demo Crashlytics non-fatal/test crash.
- [ ] Chạy trực tiếp một test ARTEMIS.
- [ ] Giải thích một AI Code Review finding.
- [ ] Chỉ ra commit sửa lỗi.
- [ ] Kiểm tra thời lượng 5–10 phút.

---

## 12. README và hướng dẫn chạy

- [ ] Tên project và mô tả.
- [ ] Yêu cầu môi trường Flutter/Dart/Android.
- [ ] Hướng dẫn cài dependency.
- [ ] Hướng dẫn cấu hình Firebase.
- [ ] Hướng dẫn chạy app.
- [ ] Hướng dẫn chạy test ARTEMIS.
- [ ] Hướng dẫn đặt environment variables.
- [ ] Ghi version/commit ARTEMIS.
- [ ] Liệt kê các AI tools đã sử dụng.
- [ ] Link video demo.
- [ ] Link report/slides nếu có.
- [ ] Bản đồ các file tài liệu/evidence.
- [ ] Ghi giới hạn hoặc known issues.
- [ ] Kiểm tra README không chứa secret.

---

## 13. Kiểm tra cuối trước khi nộp

### Chức năng

- [ ] App cài và chạy trên thiết bị Android sạch.
- [ ] Google Sign-In hoạt động.
- [ ] Auth routing hoạt động.
- [ ] Ba flow chạy từ đầu đến cuối.
- [ ] Back navigation đúng.
- [ ] Loading/Empty/Error/Retry hoạt động.
- [ ] Dữ liệu là dữ liệu thật.
- [ ] PDF phản ánh dữ liệu đang xem.
- [ ] PDF upload đúng thư mục user.
- [ ] FCM hoạt động ở 3 trạng thái.
- [ ] Remote Config thay đổi không cần rebuild.
- [ ] Crashlytics nhận đủ hai loại lỗi.

### Kiến trúc và chất lượng

- [ ] Không gọi Firebase trực tiếp trong Widget.
- [ ] Không có business logic trong `build()`.
- [ ] Không có global mutable state.
- [ ] Service được inject.
- [ ] Theme token được dùng nhất quán.
- [ ] Có đủ 9 reusable widgets.
- [ ] Touch target tối thiểu 48x48 dp.
- [ ] Chữ nội dung tối thiểu 14 sp.
- [ ] Không overflow ở 360 dp và 412 dp.
- [ ] Contrast đạt yêu cầu.

### Test và quy trình

- [ ] Tối thiểu 10 test cases.
- [ ] Mỗi test chạy 3 lần.
- [ ] Có bảng pass rate.
- [ ] Có trace/screenshot/replay.
- [ ] Có exploratory session.
- [ ] Có 5 AI review findings.
- [ ] Có 3 commit sửa lỗi riêng.
- [ ] Git history thể hiện thứ tự Plan → Architect → Integrate → Features → Instrument → Test → Review → Report.

### Bảo mật và repository

- [ ] Repository public.
- [ ] Không có service account.
- [ ] Không có private API key.
- [ ] Không có password/test account credential.
- [ ] `firestore.rules` không mở toàn bộ dữ liệu.
- [ ] `storage.rules` giới hạn theo `uid`.
- [ ] Đã chạy `git status` và kiểm tra file ngoài ý muốn.
- [ ] Đã kiểm tra toàn bộ link trong README.
- [ ] Đã kiểm tra quyền truy cập video/report/slides.

---

## 14. Bảng tiến độ tổng hợp

| Giai đoạn | Deliverable chính | Trạng thái | Ngày hoàn thành | Evidence/link |
|---|---|---|---|---|
| Plan | `docs/design-traceability.md`, Figma | [ ] | | |
| Architect | `docs/architecture.md`, theme, widgets | [ ] | | |
| Integrate | Firebase, Auth, rules | [ ] | | |
| Features | Screens, flows, PDF, Demo Area | [ ] | | |
| Instrument | Analytics, Crashlytics, Remote Config, FCM | [ ] | | |
| Test | `docs/test-plan.md`, `e2e_test/`, traces | [ ] | | |
| Review | `docs/code-review.md`, 3 fix commits | [ ] | | |
| Report | Report, slides, video, README | [ ] | | |

---

## 15. Nhật ký vấn đề và quyết định

| ID | Ngày | Vấn đề/quyết định | Ảnh hưởng | Cách xử lý | Trạng thái |
|---|---|---|---|---|---|
| DEC-01 | | | | | [ ] |
| DEC-02 | | | | | [ ] |
| BUG-01 | | | | | [ ] |
| BUG-02 | | | | | [ ] |
| FLAKY-01 | | | | | [ ] |

> Cập nhật checklist sau mỗi session làm việc và trước mỗi commit quan trọng.
