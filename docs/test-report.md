# Kiểm thử và review — StudyPilot (GR6)

Cập nhật: 2026-11-11. Kết quả ghi theo từng lượt chạy thật; bảng ARTEMIS tổng hợp các ca đã có ≥3 lượt pass, trace và số liệu nằm trong `evidence/artemis/`.

## 1. Lệnh tái hiện

```powershell
# Mobile
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release

# Firestore Rules (Emulator, project demo tách khỏi project thật)
cd firebase/tests
npm ci
npx --yes firebase-tools@13.35.1 emulators:exec --only firestore `
  --project demo-second-brain-final "npm test"

# Web (parser + API server)
cd admin-web
node --test
```

## 2. Kết quả tự động (11/11/2026)

| Lệnh | Kết quả | Ghi chú |
|---|---|---|
| `flutter analyze` | **0 issue** | Toàn bộ `lib/`, `packages/`, `test/`, `tool/` |
| `flutter test` | **165/165 pass** | Hermetic, fake service, không cần Firebase |
| `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | **PASS** | `build/app/outputs/flutter-apk/app-release.apk` |
| Rules Emulator | **17/17 pass** | `firebase/tests/final.test.mjs` |
| `node --test` (web) | **14/14 pass** | 9 parser FLM + 5 API server |
| `node --check admin-web/app.js` | **PASS** | Cú pháp ES module |

> **Phạm vi rules:** 17/17 là kết quả trên Firestore Emulator với project demo. Bản rules siết **đã deploy live ngày 11/11**: ruleset tạo 2026-11-11T03:22:05Z, logic khớp tuyệt đối `firebase/firestore.rules` (`exactMatch: true`) — xem `evidence/firebase/firestore/rules-api-verification-2026-11-11.json`. G-09 đã đóng.

> **Cập nhật 11/11/2026:** `flutter test` **165/165 pass**, `flutter analyze` 0 issue — thêm 4 test trong `test/sync_vault_flow_test.dart` (D-01 hủy/xác nhận, SyncError + Thử lại, Back về Home), 1 test metadata timeout trong `test/services/report_export_service_test.dart`, và sửa mốc Undo 8 s trong `test/regression_widget_test.dart`. APK debug build lại với `--dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788`; export + upload Cloudinary đã verify trên máy thật `GQDIV8HUPJWK79XC` (upload 37273 bytes, `export_report status=success`, metadata đọc lại từ Firestore, tải lại PDF mở share sheet) — xem `evidence/app/export-cloudinary-2026-11-11/`.

### 2.1 Rules — phạm vi 15 test

1. Tạo hồ sơ lần đầu: role mặc định `user`, chặn tự đặt `admin`, giới hạn 40 trường.
2. Hồ sơ riêng tư: chỉ chủ sở hữu đọc; Admin chỉ sửa trường `role`.
3. Đơn kế hoạch: chủ sở hữu tạo `pending`, không sửa nội dung sau khi gửi.
4. Duyệt một lần: Staff chỉ chuyển `pending → approved/rejected`, bắt buộc lý do, `reviewedBy` trùng UID.
5. Sinh viên không đọc hàng đợi duyệt; Staff không nộp bài như sinh viên.
6. Thông báo: chỉ Staff/Admin tạo, payload đúng schema.
7. Catalog: giữ mã môn bất biến, hỗ trợ archive, học kỳ 0–12, mã `*`.
8. Curriculum chỉ đọc khi đăng nhập; audit log append-only đúng chủ.
9. `experience_notes`: sinh viên gửi `pending`, Staff duyệt, bản đã duyệt công khai.
10. Bốn subcollection legacy chỉ chủ sở hữu đọc.
11. Fixture bí kíp có `title` hợp lệ (CR-26), tránh test đỏ giả.

### 2.2 AI — bằng chứng model thật

| Tệp | Nội dung |
|---|---|
| `evidence/ai/study-plan-2026-11-10-valid.json` | 3/3 output Kỳ 3/5/8 đúng schema `goal` + `actions`, model `gemini-3.5-flash-lite` |
| `evidence/ai/study-plan-2026-11-10.json` | Ca lỗi thật: một output lặp vô hạn (vi phạm schema, app ném `FormatException`) và hai lần HTTP 503 |

Hai tệp dùng cùng system instruction/prompt với `lib/services/study_plan_ai.dart`. Đây là bằng chứng ở tầng model, không phải ảnh UI trên thiết bị.

## 3. ARTEMIS E2E

### 3.1 Bảng kết quả trên Pixel 7 API 35 (giả lập)

| Ca | Nội dung | Lượt pass | Trace / số liệu |
|---|---|---|---|
| TC_F1_01 | Lịch slot môn | 3/3 | `fe0913bf…`, `41bfb9b6…`, `f3529fec…` |
| TC_F1_02 | Tìm môn | 3/3 | `d749b903…`, `f6340738…`, `c71200d2…` |
| TC_F1_04 | Mở Cố vấn | 3/3 | `d2562b92…`, `54b4d512…`, `b69f7a77…` |
| TC_05 | Tiên quyết | 3/3 | `344c682a…`, `903bdb13…`, `c243885c…` |
| TC_09 | Tìm kiếm rỗng | 3/3 | `91c7381a…`, `9dcbc2b1…`, `f72496c8…` |
| TC_F3_03 | Đồng bộ Vault | 3/3 | `e79c68f1…`, `2a071b3a…`, `2f1de623…` |
| TC_11 | Remote Config | 3/3 | 20,34 / 20,28 / 20,32 giây; `0040c1d1…`, `27aaad2b…`, `730cc9cd…` |
| TC_13 | FCM token sau cold start | 3/3 | `3 passed in 57,51s`; 13,59 giây/lượt; `a23c7a10…`, `034ff4e6…`, `4b13c8b5…` |
| TC_X_06 | Trung tâm thông báo | 3/3 | `0d0f6a8d…`, `64e46578…`, `f32b97e6…` |
| TC_02 | Mở lại app | 3 lượt pass | 1 lượt timeout được giữ trong lịch sử, chạy lại pass tại `aa8ce04c…` |

Mỗi ca có ≥3 lượt pass; trace đầy đủ trong `evidence/artemis/2026-11-07-flash-lite.md`, `2026-11-07-regression.md` và `2026-11-08-completion.md`.

### 3.2 Điện thoại thật (GQDIV8HUPJWK79XC)

| Ngày | Ca | Kết quả |
|---|---|---|
| 10/11 | TC_08 — Tóm tắt môn học | Pass 92,20 giây sau khi gỡ chặn chạy nền HyperOS |
| 10/11 | TC_11 — Remote Config | Pass 41,56 giây |
| 11/11 | TC_10 — Xuất PDF + upload Cloudinary | **3/3**, tổng 11m12s, trung bình 224,02 giây/lượt; consent trước upload, URL `http://127.0.0.1:8788/api/reports/…pdf`, không FATAL |

Bảng từng lượt: `evidence/artemis/results-20261111T025227741246Z.md`; trace/ảnh trong `evidence/artemis/runs/`.

### 3.3 Độ ổn định và nhãn Semantics

- Model chạy `gemini-3.5-flash-lite`, concurrency 1. Khi dồn lượt, Gemini trả HTTP 429/503; các lượt lỗi được giữ nguyên trong lịch sử và chạy lại tuần tự.
- Một lượt TC_02 timeout khi mở lại app; lượt chạy lại sau khi khởi động lại giả lập pass.
- Trên máy thật, HyperOS chặn tiến trình nền làm TC_08/TC_11 fail; sau khi gỡ chặn, cả hai pass.
- Nhãn Semantics: các widget dùng chung bọc `Semantics` — `AppButton` (`lib/widgets/app_button.dart:39,79`), `AppTextField` (`lib/widgets/app_text_field.dart:39,86`), `AppCard`/empty state (`lib/widgets/app_components.dart:35,94`), nút gửi ở Cố vấn (`lib/screens/advisor_screen.dart:236`). ARTEMIS đọc hierarchy Android và text hiển thị để định vị các nhãn này.

### 3.4 Phiên exploratory (ARTEMIS Pro)

- Trace `c9ba73e3-cba2-45ca-80b9-03f1a5a859f1`: đi qua 10 luồng, khoảng 9 phút thao tác liên tục, checker ghi nhận đủ các màn chính.
- Trace `c60b3464-271b-4cbf-a106-600789510380`: 28 bước, khoảng 7,5 phút; phủ nhiều môn, bộ lọc công việc, Ghi chú, Hồ sơ học tập, Cố vấn, Chiến lược và điều hướng từ thông báo; daemon dừng khi Gemini trả HTTP 429.
- Ảnh và hierarchy của hai phiên chứa thông tin tài khoản nên lưu ngoài repo; nội dung điều tra ghi trong `evidence/artemis/2026-11-08-completion.md`.

### 3.5 Dữ liệu kiểm thử

Kịch bản cũ hardcode PRM323, nhưng catalog thật chỉ có PRM393 trong nhóm PRM (175 môn). Toàn bộ test case đã đổi sang **PRM393** (3 tín chỉ, học kỳ 8, tiên quyết PRO192, 60 slot). TC_08 được viết lại theo đường tất định: chip **Môn** → **Hỏi nhanh trên thiết bị** → chọn PRM393 → **Tóm tắt môn học**, thay vì phụ thuộc câu hỏi tự do.

Ma trận đầy đủ 26 kịch bản, tiền điều kiện và kết quả mong đợi: `docs/test-plan.md`.

### 3.6 Sửa lỗi phát hiện từ Crashlytics (10/11)

| Lỗi | Nguyên nhân | Sửa |
|---|---|---|
| `DocumentSnapshotPlatform.get._findKeyValueInMap` — "field reason does not exist" (3 event, 1 user) | `ExperienceNote.fromDocument` đọc `reason` bằng `as String` khi document cũ không có trường | Đọc qua `data()?.containsKey('reason')`, mặc định `''` |
| `_StreamImpl.listen` — "Stream has already been listened to" (7 event, 2 user) | `watchCourseNotes` trả single-subscription stream, widget remount (đổi tab, recycle) listen lần hai | Broadcast controller + replay giá trị cuối cho listener mới |

Cả hai sửa trong `packages/core/lib/study_pilot_core.dart`; `dart analyze` sạch, APK debug build lại và cài lên máy thật trước khi chạy batch. Ảnh dashboard/issues: `evidence/firebase/crashlytics/`.

## 4. Web admin

- 14/14 test Node pass (parser FLM, API server).
- Đã kiểm tra thủ công trên trình duyệt: sign-in render, empty state không có dữ liệu mẫu, luồng thêm chuyên ngành thủ công, import 5 file HTML FLM thật (49 môn, 4 đề cương).
- Trang đăng nhập của URL deploy đã chụp ngày 10/11: `evidence/firebase/auth/web-deploy-signin-2026-11-10.png`.

## 5. Review code mới (AI hỗ trợ)

Review chạy trên working tree và lịch sử Git nhánh `main`; không giả lập reviewer độc lập. Sáu finding tiêu biểu, đầy đủ trong `docs/code-review.md`; output phiên Qoder 11/11 lưu tại `evidence/code-review/qoder-review-2026-11-11.md`:

| ID | Phát hiện | Quyết định | Kiểm chứng |
|---|---|---|---|
| CR-15 | `AdvisorViewModel` import trực tiếp `cloud_firestore`, `firebase_ai` | Tách `AiService`/`GeminiAiService`, inject qua Provider | Analyze sạch, 165 test pass (`bd4c989`) |
| CR-16 | Role gate đọc Firestore SDK trong widget | Thêm `watchUserRole` ở service layer | Test role gate pass (`bd4c989`) |
| CR-17 | Một dịch vụ Firebase lỗi chặn toàn app | Cô lập từng bước trong `try/catch`, lỗi cốt lõi vẫn chặn | Build/run ổn định (`bd4c989`) |
| CR-18 | Sync Vault để lại task "Connectivity check" | Ghi marker, đọc lại, xóa đúng bản ghi vừa tạo | Chạy lại sync không còn rác (`f2b2cb0`) |
| CR-20 | Rules cho phép hồ sơ tự khai `admin`, audit log nhận mọi trường | Chặn `admin != false`, giới hạn 40 trường; audit log 3 trường | Rules 16/16 (`e5256c1`) |
| CR-21 | Listener web lỗi chỉ log console, màn trắng | Banner lỗi + nút thử lại từng màn; thêm Analytics/RC/App Check | `node --check` + test web pass (`c9b9985`) |
| CR-31 | Ghi metadata Firestore không có timeout, UI treo ở 100% khi mất DNS | `.timeout(12s)` + `metadataSynced=false` + cảnh báo hàng đợi | 165/165 test pass, analyze sạch (working tree 11/11) |

Nợ kỹ thuật còn mở: CR-27 (ba widget gọi thẳng `FinalFirestore`). CR-28 (event AI thiếu `feature`) và CR-29 (test `AnnouncementsViewModel`) đã đóng ở `4142399`; CR-30 đã xác nhận `uv.lock` ghim commit ARTEMIS.

## 6. Hạng mục đã kiểm chứng

- [x] Analyze 0 issue, 165 test pass, build debug/release.
- [x] Rules 17/17 trên emulator; bản rules siết đã deploy live ngày 11/11.
- [x] Web 14/14 test.
- [x] AI có 3 output thật + 1 ca lỗi được xử lý.
- [x] ≥ 5 finding review có quyết định, `file:line` và commit sửa; artefact Qoder 11/11.
- [x] ARTEMIS 10 ca × 3 lượt trên giả lập; TC_10 3/3, TC_08 và TC_11 trên máy thật.
- [x] Hai phiên exploratory ARTEMIS Pro (10 luồng / 28 bước).
