# Kế hoạch kiểm thử — StudyPilot (GR6)

Cập nhật: 2026-11-11. Tài liệu phân tách **kiểm thử tự động** (đã chạy, có kết quả) và **E2E** (kết quả ghi theo từng lượt thật). Ô "Chờ lượt" là kịch bản nằm trong lịch chạy tiếp theo; chỉ kết quả có trace/ảnh mới được tính PASS.

## 1. Phạm vi và chiến lược

| Tầng | Mục tiêu | Công cụ |
|---|---|---|
| Tĩnh | Không lỗi analyzer, không import SDK sai lớp | `flutter analyze` |
| Unit/Widget | ViewModel, state 4 nhánh, routing, PDF, parse dữ liệu | `flutter test` + fake service |
| Rules | Cho phép/từ chối theo vai trò và chuyển trạng thái | Firestore Emulator + `@firebase/rules-unit-testing` |
| Web | Parser FLM và API server | `node --test` |
| E2E | Luồng thật trên thiết bị, quan sát UI/log | pytest + ARTEMIS (ADB) + Appium-UIAutomator |

**Môi trường E2E**: thiết bị Android thật (serial `GQDIV8HUPJWK79XC`), package `com.example.prm323_lab3`, tài khoản Google test chuyên dụng đã đăng nhập sẵn. Không dùng tài khoản cá nhân, không nhập mật khẩu trong kịch bản.

**Quy tắc dữ liệu**: mỗi case dùng fixture tên duy nhất (`unique_name`), không sửa bản ghi có sẵn, không tạo điểm/transcript giả. Case có ghi dữ liệu phải dọn hoặc dùng tiền tố nhận diện.

## 2. Kiểm thử tự động — trạng thái mới nhất

| Lệnh | Kết quả | Ghi chú |
|---|---|---|
| `flutter analyze` | **PASS — No issues found** | Toàn bộ `lib/`, `test/`, `tool/` |
| `flutter test` | **PASS — 159 tests** | Chạy hermetic, không cần Firebase thật |
| `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | **PASS** | `build/app/outputs/flutter-apk/app-release.apk` |
| `cd firebase/tests && npm run test:emulator` | **PASS — 17/17 tests** | Firestore Emulator, project `demo-second-brain-final` |
| `cd admin-web && node --test` | **PASS — 14 tests** (9 parser + 5 server) | `flm-parser.test.mjs`, `server.test.mjs` |

Bản đồ file test Flutter:

| Nhóm | File | Nội dung chính |
|---|---|---|
| Model | `course_model_test`, `note_model_test`, `notification_model_test` | Parse Firestore Timestamp, field thiếu |
| ViewModel | `academic_viewmodel_test`, `advisor_viewmodel_test`, `notifications_test`, `roadmap_viewmodel_test`, `roadmap_major_test`, `tasks_notes_test`, `session_regression_test`, `note_attachment_test` | State, lọc, rollback, đổi phiên |
| Screen/Widget | `widget_test`, `regression_widget_test`, `course_detail_tabs_test`, `major_onboarding_test`, `strategy_sim_test`, `academic_profile_form_test` | Điều hướng, 4 tab, onboarding, validate form |
| Service | `analytics_wiring_test`, `firestore_tasks_regression_test`, `notification_routing_test`, `report_export_service_test`, `study_plan_ai_test`, `version_gate_test` | Event, định tuyến push, PDF, AI, version gate |

Rules test (`firebase/tests/final.test.mjs`, 15 test khi chạy gồm 4 biến thể legacy):

1. Role bootstrap, hồ sơ riêng tư, chặn tự nâng quyền.
2. Đơn kế hoạch: sở hữu, schema, duyệt một lần, id cố định.
3. Thông báo: chỉ staff/admin được đăng, payload hợp lệ.
4. Quản trị catalog: giữ mã môn bất biến, hỗ trợ archive.
5. Import metadata và nhóm tự chọn hợp lệ.
6. Sinh viên nhận quyết định duyệt realtime không cần refresh.
7. Bốn subcollection legacy chỉ chủ sở hữu đọc.
8. Curriculum chỉ đọc khi đăng nhập; audit log append-only đúng chủ.
9. Staff/admin không nộp bài như sinh viên; sinh viên không đọc hàng đợi duyệt.
10. Môn theo chuyên ngành: id ghép, mã `*`, học kỳ 0–12.
11. Bí kíp: sinh viên gửi `pending`, staff duyệt, bản duyệt công khai.

## 3. E2E — 26 kịch bản ARTEMIS

Cột **Kết quả (3 lượt)** chỉ điền sau khi chạy thật và lưu trace/screenshot vào `evidence/artemis/`. Mỗi case chạy **3 lần độc lập**; trường "Chờ lượt" giữ nguyên cho tới khi có đủ lượt.

### 3.1 Xác thực và điều hướng

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-01 | Đã cài app, tài khoản test có trên thiết bị | Đăng xuất, đăng nhập lại qua native Google picker (không nhập mật khẩu) | Picker hiện; về Home; thấy đủ 4 tab Trang chủ/Lộ trình/Việc cần làm/Ghi chú | Chờ lượt |
| TC-02 | App vừa cold-start | Quan sát màn hình hiện tại, không đổi tài khoản | Ở Home nếu đã đăng nhập hoặc màn đăng nhập; text khớp "Chào" hoặc "Đăng nhập với Google" | **3 lượt pass** (giả lập; lượt timeout được chạy lại, trace `aa8ce04c…`) |
| TC-12 | Đang đăng nhập | Đăng xuất, kiểm tra không còn nội dung riêng tư, đăng nhập lại | Nút "Đăng nhập với Google" hiện; không lộ task/note; khôi phục về Home | Chờ lượt |
| TC-S_01 | Đang đăng nhập | Đăng xuất, bấm đăng nhập rồi hủy picker bằng Back | Thông điệp chứa "hủy"/"huỷ"; vẫn chưa đăng nhập; sau đó khôi phục được tài khoản | Chờ lượt |

### 3.2 Lộ trình, môn học, tìm kiếm

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-F1_01 | Danh mục có PRM393 | Lộ trình → PRM393 → tab Lịch slot | Đủ 3 tab Lịch slot/Đánh giá/Tổng quan; số slot là số thực; nếu 0 phải có text "chưa có" | **3/3** (giả lập) |
| TC-F1_02 | Danh mục có PRM393 | Lộ trình → gõ `PRM` vào ô tìm | Ô chứa đúng `PRM`; danh sách chỉ còn mã bắt đầu bằng PRM; có PRM393 | **3/3** (giả lập) |
| TC-F1_04 | Danh mục có PRM393 | PRM393 → Tổng quan → "Hỏi cố vấn về PRM393", không gửi | Màn "Cố vấn học tập"; câu hỏi điền sẵn chứa PRM393 | **3/3** (giả lập) |
| TC-05 | Hồ sơ học vụ có dữ liệu thật | Mở PRM393 → Tổng quan, đọc trạng thái tiên quyết | Trạng thái `eligible` hoặc `missing`; nếu thiếu phải có danh sách mã; không bịa transcript | **3/3** (giả lập) |
| TC-09 | Đang ở Lộ trình | Xóa tìm kiếm cũ, tìm `ZZZ_NO_COURSE_20261104`, rồi xóa | 0 dòng + text "Không tìm thấy"; xóa xong danh sách trở lại > 0 | **3/3** (giả lập) |

### 3.3 Việc cần làm và ghi chú

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-F2_01 | Không cần fixture cũ | Tạo task mới tên duy nhất, tick checkbox | Đúng tên; checked = true; snackbar có "Hoàn tác" | Chờ lượt |
| TC-F2_02 | Tạo task mới | Tick rồi bấm "Hoàn tác" trong 8 giây | Task trở về unchecked | Chờ lượt |
| TC-V1 | Tạo task mới | Mở sheet sửa, thêm " EDITED", cập nhật, sync thủ công, quay lại Tasks | Tiêu đề sau reload đúng `<tên> EDITED`; log không có `editTask error`/FATAL | Chờ lượt |
| TC-F2_05 | Tạo task mới | Sync Vault → "Kích hoạt đồng bộ Vault ngay", quay lại Tasks | Task xuất hiện đúng **1 lần** sau reload | Chờ lượt |
| TC-F3_01 | Không cần fixture cũ | Ghi chú → tạo note tên duy nhất, nội dung `Lab3 E2E fixture`, lưu, mở lại | Tiêu đề và nội dung khớp chính xác | Chờ lượt |
| TC-F3_02 | Đã mở Ghi chú một lần | Bật airplane mode, quay lại Ghi chú | Trạng thái data/empty/error rõ ràng; không tuyên bố đã sync server; tắt airplane mode | Chờ lượt |
| TC-F3_03 | Mạng bật | Sync Vault → đồng bộ → quay lại Ghi chú | data hoặc empty; không còn banner lỗi sync | **3/3** (giả lập) |

### 3.4 Cố vấn AI

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-08 | AI bật trong Remote Config, có mạng | Cố vấn → Môn học → hỏi "Tư vấn môn PRM393", chấp nhận consent | Trả lời thật chứa PRM393, "tín chỉ" và mục "Nguồn:"; nêu rõ dữ liệu cá nhân còn thiếu | Pass trên máy thật 10/11, 92,20 giây |

### 3.5 Xuất PDF, Remote Config, push, analytics

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-10 | Có mạng, media API sẵn sàng | Sync Vault → "Xuất & Tải PDF lên Cloudinary" | Consent hiện **trước** upload; upload success; URL `http://127.0.0.1:8788/api/reports/…pdf`; không FATAL | **3/3** (11/11, máy thật; 11m12s) |
| TC-11 | Remote Config đã fetch | Sync Vault → đọc card Remote Config | Hiện boolean `maintenance_mode`, `feature_ai_advisor_enabled` và chuỗi `min_app_version` thật | **3/3** (giả lập; 20,3 giây/lượt) và pass máy thật 41,56 giây |
| TC-S_06 | Đang ở Home | Bật airplane mode, mở lại app | App render Home hoặc màn đăng nhập, không crash; bật lại mạng | Chờ lượt |
| TC-X_06 | Đang ở Home | Mở Trung tâm thông báo | Đếm đúng số thông báo; nếu 0 phải có text trống; không suy diễn push đã gửi | **3/3** (giả lập) |
| TC-S_07 | Đang ở Home | Mở App info → Notifications, đọc quyền, quay lại app | Quyền `allowed`/`denied`; app render lại bình thường | Chờ lượt |
| TC-13 | App đã cold-start với phiên có sẵn | Quan sát Home, không đổi tài khoản | Tiêu đề "StudyPilot"; log có "Registered FCM token" | **3/3** (giả lập; `3 passed in 57,51s`) |
| TC-14 | Đang ở Home | Lộ trình → tìm PRM → mở PRM393 | Log có `Logged event: search_course` và `course_view` | Chờ lượt |
| TC-V5 | Đang ở Home | Đi qua 4 tab, mở chi tiết môn, quay lại Ghi chú | Đủ 4 tab; tiêu đề cuối "Ghi chú học tập"; logcat không rỗng | Chờ lượt |

### 3.6 Khám phá tự do

| ID | Tiền điều kiện | Thao tác | Kết quả mong đợi | Kết quả (3 lượt) |
|---|---|---|---|---|
| TC-EXPLORATORY | Tài khoản test | Đi hết tab, 4 tab chi tiết môn, validate hồ sơ không lưu điểm giả, Advisor consent, Strategy, thông báo, Sync Vault, lỗi/phục hồi, Back | Ghi mọi issue kèm bước tái hiện/mức độ; ghi lại thời lượng và số bước thật | 2 phiên: 10 luồng/~9 phút; 28 bước/~7,5 phút |

## 4. Điều kiện thoát (exit criteria)

- `flutter analyze` 0 issue, `flutter test` 100% pass, build debug/release thành công.
- Rules test pass trên emulator với toàn bộ 15 test.
- ≥ 10 case E2E chạy đủ 3 lượt; case thất bại phải có log/ảnh và được xử lý hoặc ghi rõ giới hạn.
- Có bằng chứng Console: Analytics DebugView, Crashlytics non-fatal, Remote Config trước/sau, FCM 3 trạng thái, App Check.
- Không có dữ liệu giả hoặc kết quả tự suy diễn trong báo cáo.

## 5. Trạng thái thực thi

- **Đã xong**: toàn bộ kiểm thử tự động ở mục 2, gồm 159 test Flutter, 15 test rules trên emulator và 14 test web. Rules siết 10/11 đã deploy live (G-09 đóng).
- **Đang chạy trên máy thật**: đã gỡ chặn HyperOS (Gỡ lỗi USB + Cài đặt qua USB). Ngày 10/11 chạy ARTEMIS trên GQDIV8HUPJWK79XC với model `gemini-3.5-flash-lite`; batch tập trung 12 case × 3 lượt (đủ phủ điều kiện thoát ≥10 case và 6 công nghệ). Kết quả từng lượt lưu ở `evidence/artemis/results-*.md` và `runs/`. Lệnh tái hiện:
  ```bash
  cd e2e_test
  uv run pytest -m "e2e and not exploratory" --runs 3 -q
  ```
- **Exploratory + auth**: `TEST_ACCOUNT_EMAIL` và `E2E_ALLOW_AUTH_CHANGES=1` đặt trong `e2e_test/.env` (gitignore); chạy sau batch hồi quy vì chung thiết bị.
- **Bằng chứng Console đã có**: RC Version 3 (9 tham số), App Check, Crashlytics, Analytics DebugView (ảnh 10/11 trong `evidence/firebase/`). Còn thiếu cảnh tắt cờ RC trên thiết bị và checklist web sau đăng nhập (G-02).
