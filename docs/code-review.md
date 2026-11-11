# AI-assisted code review — StudyPilot (GR6)

Tài liệu ghi lại các vòng review thực tế trên mã nguồn, quyết định xử lý và commit sửa. Review do AI hỗ trợ (Codex ở các vòng trước, Qoder ở vòng 10/11/2026), thực hiện trên working tree và lịch sử Git của nhánh `main`. Không có reviewer bên ngoài hay PR review độc lập; báo cáo không giả lập kết quả đó.

## 1. Vòng review 10/11/2026 (bàn giao Lab 3 + Final)

Phạm vi: toàn bộ thay đổi so với baseline `aebf28a`, tập trung vào tuân thủ MVVM, toàn vẹn dữ liệu, bảo mật rules và trạng thái lỗi của web.

| ID | Mức | Phát hiện | Quyết định | Sửa và kiểm chứng | Commit |
|---|---|---|---|---|---|
| CR-15 | High | `AdvisorViewModel` import trực tiếp `cloud_firestore`, `firebase_ai`, `firebase_core` và tự dựng Firestore/Gemini; ViewModel phụ thuộc SDK, vi phạm kiến trúc. | Accepted | Tách `AiService`/`GeminiAiService`; inject `AiService` + `FinalFirestore` qua Provider. `flutter analyze` sạch, 159 test pass. | `bd4c989` |
| CR-16 | High | Role gate trong `main.dart` đọc role bằng SDK Firestore ngay trong widget, không đi qua service layer. | Accepted | Thêm `FirestoreService.watchUserRole` và stream trong `_MobileRoleGate`; fake service trong test cập nhật theo. | `bd4c989` |
| CR-17 | High | `main()` await App Check/Crashlytics/Remote Config; một dịch vụ lỗi có thể chặn toàn bộ app dù không bắt buộc. | Accepted | Cô lập từng bước trong `try/catch`, log và tiếp tục; lỗi Firebase cốt lõi vẫn dẫn tới màn hình cấu hình. | `bd4c989` |
| CR-18 | High | Sync Vault viết task "Connectivity check" để thử Firestore nhưng không xoá, để lại dữ liệu giả trong tài khoản thật. | Accepted | Ghi marker có timestamp, đọc lại, xoá đúng các bản ghi vừa tạo; không đụng task khác. | `f2b2cb0` |
| CR-19 | Medium | Màn Thông báo chỉ có `StreamBuilder` thô, thiếu nhánh loading/empty/error và không thử lại được. | Accepted | Thêm `AnnouncementsViewModel` + 4 trạng thái chuẩn, có nút thử lại. | `f2b2cb0` |
| CR-20 | High | Rules cho phép hồ sơ tự khai trường `admin`, không giới hạn kích thước; audit log nhận mọi trường nên có thể giả bản ghi đặc quyền. | Accepted | Chặn `admin != false`, giới hạn 40 trường; audit log chỉ `userId/action/createdAt`, action 1–100 ký tự. | `e5256c1` |
| CR-21 | Medium | Bốn listener web khi lỗi chỉ log console, màn hình trắng không có cách phục hồi; thiếu telemetry/App Check. | Accepted | Banner lỗi + nút thử lại từng màn; thêm Analytics/Remote Config/App Check scaffolding và event nghiệp vụ. | `c9b9985` |
| CR-22 | Medium | Remote Config template chỉ có 4 tham số trong khi app đọc 9, dễ deploy thiếu cờ AI. | Accepted | Template và defaults khớp đủ 9 tham số. | `e5256c1` |
| CR-23 | Medium | E2E còn test từ chối email ngoài `@fpt.edu.vn`, trong khi quy tắc đó đã bị bỏ; test sẽ fail giả. | Accepted | Thay bằng case huỷ Google picker, kiểm tra thông điệp và trạng thái đăng xuất. | `bd4c989` |
| CR-24 | Low | Tài liệu `design-traceability`, `architecture`, `analytics-plan`, `test-plan` lệch code (tên dự án, số màn hình, event, đầu mối test). | Accepted | Viết lại theo code và kết quả chạy thật. | commit tài liệu |
| CR-25 | Low | Gói dùng chung và app còn tên cũ "Second Brain/FPTU", không thống nhất thương hiệu. | Accepted | Đổi thành `study_pilot_core` / StudyPilot; giữ nguyên `applicationId` để không phá Firebase binding. | `bd4c989` |
| CR-26 | Medium | Fixture rules test của `experience_notes` thiếu `title` dù UI và rules bắt buộc, khiến test đỏ dù sản phẩm đúng. | Accepted | Thêm `title` hợp lệ vào fixture; chạy emulator 15/15 pass. | `e5256c1` |
| CR-28 | Medium | `study_plan_screen` ghi `ai_request`/`ai_error`/`ai_result_accepted` bằng `logEvent` thô, thiếu tham số `feature`. | Accepted | Dùng `logAiRequest`/`logAiError`/`logAiResultAccepted` với `feature: 'study_plan'` và model từ Remote Config. | `4142399` |
| CR-29 | Low | Chưa có test tự động cho `AnnouncementsViewModel` sau khi thêm. | Accepted | ViewModel nhận hàm `watchAnnouncements`; test phủ loading/empty/data/error/retry. Tổng 159 test. | `4142399` |
| CR-30 | Low | Cần xác nhận `e2e_test/uv.lock` pin đúng ARTEMIS. | Resolved | `pyproject.toml` và `uv.lock` cùng ghim commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`. | — |

### Kiểm chứng sau sửa

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 159/159 pass |
| `flutter build apk --debug` / `--release` | Thành công |
| Rules emulator (`firebase emulators:exec`) | 15/15 pass |
| `node --test admin-web` | 14/14 pass |
| `node --check admin-web/app.js` | Pass |

## 2. Findings chấp nhận nhưng chưa xử lý trong đợt này

| ID | Mức | Nội dung | Lý do / kế hoạch |
|---|---|---|---|
| CR-27 | Medium | `CommunityTipsSection`, `MyTipsScreen`, `StudyPlanScreen` gọi trực tiếp `FinalFirestore` thay vì qua ViewModel riêng. | Đây là repository facade, không phải SDK; refactor 1.000+ dòng widget có rủi ro hồi quy cao. Ghi nhận là nợ kiến trúc, ưu tiên sau demo. |

## 3. Vòng review trước (04–07/11/2026)

Các finding CR-01…CR-14 đã được ghi trong lịch sử tài liệu và xử lý ở các commit trước baseline. Tóm tắt nhóm chính:

- **CR-01/CR-02/CR-03**: mất task sau reload, response cũ khôi phục dữ liệu sau logout, toggle thiếu Undo/error — đã sửa và có regression test.
- **CR-04/CR-05**: export dùng dữ liệu cũ khi sync lỗi; Remote Config không phát thay đổi — đã sửa bằng `SyncReloadService` và `ChangeNotifier`.
- **CR-06/CR-07/CR-08/CR-09**: huỷ đăng nhập bị che lỗi, thiếu test crash/non-fatal, trùng Hero tag, thiếu event logout — đã sửa.
- **CR-10…CR-14**: giữ câu hỏi Advisor khi thử lại, tách lỗi Analytics khỏi export, chặn đuôi MIME kế thừa, và hai việc deferred (thu hồi asset khi ghi metadata lỗi, quota endpoint AI).

## 4. Quy trình còn lại

1. Khi có PR, chạy lại reviewer trên diff PR và lưu nguyên output vào `evidence/code-review/`.
2. Với mỗi finding mới, ghi Accepted/Modified/Rejected kèm lý do trước khi sửa.
3. Commit sửa phải chứa mã CR trong message; không tạo lịch sử giả cho thay đổi đã có.
4. Disclose công cụ AI và phạm vi review trong báo cáo; không trình bày review AI như review của người ngoài.
