# Sửa lỗi và xác minh — 04/11/2026

## Phạm vi

Tiếp tục working tree có sẵn trên branch `main`, baseline HEAD `2337e00`.
Không reset, đổi branch, stage, commit, push, deploy Rules hoặc đổi billing.
Giữ nguyên Flutter, Provider, MVVM và các chỉnh sửa người dùng đã có.

## Thay đổi trong đợt này

| Nhóm | File | Hành vi sau sửa |
|---|---|---|
| Tasks | `lib/services/firebase_firestore_service.dart` | Trả mọi document, dùng Firestore document ID làm canonical ID và giữ legacy ID mà không sửa map nguồn |
| Session | `lib/viewmodels/{base,tasks,notes,roadmap,notifications}_viewmodel.dart` | Bỏ kết quả đọc cũ/sai UID, không notify sau dispose, không rollback dữ liệu riêng của account đã logout |
| Advisor | `lib/viewmodels/advisor_viewmodel.dart` | Xóa hội thoại/consent và vô hiệu reply đang chờ khi đổi tài khoản; theo dõi thay đổi feature flag |
| Navigation | `lib/main.dart` | Reset Navigator theo UID để bỏ các màn hình riêng đã push khi đổi account |
| Task UX | `lib/screens/tasks_screen.dart` | Checkbox có feedback lỗi và Hoàn tác 8 giây; tap nội dung mở edit; sheet giữ nội dung khi lưu thất bại |
| Hero | `lib/screens/{tasks,notes}_screen.dart` | Hai FAB dùng tag riêng, không lỗi duplicate Hero khi mở route |
| Export | `lib/screens/sync_vault_screen.dart` | Dùng SyncReloadService kiểm tra state lỗi trước consent/upload và kiểm tra lại identity trước export |
| Export diagnostics | `lib/services/report_export_service.dart` | Ghi non-fatal từ lỗi export thật; không gửi nội dung PDF/URL token vào exception; dùng đúng generatedAt khi được truyền |
| Remote Config | `lib/services/remote_config_service.dart`, `lib/main.dart` | Service thông báo thay đổi; AuthGate rebuild; UI không báo thành công khi fetch lỗi |
| Auth/Analytics | `firebase_auth_service.dart`, `analytics_service.dart`, `firebase_analytics_service.dart`, `auth_viewmodel.dart` | Hủy sign-in có message, giữ nguyên AuthException domain, thêm logout và xóa identity telemetry |
| Crashlytics | `lib/services/crashlytics_service.dart`, `lib/screens/sync_vault_screen.dart` | Có test crash qua dialog xác nhận; demo debug chủ động bật collection; gửi non-fatal không giả báo dashboard đã nhận |
| Docs | README, analytics plan, status, AI log và code-review record | Bổ sung Codex disclosure, sửa parameter/event mapping, phân biệt local verification và Console evidence |

## Kiểm tra tự động

| Lệnh | Kết quả quan sát |
|---|---|
| `flutter analyze --no-pub` | PASS, 0 issues (8.8 giây ở lượt cuối) |
| `flutter test --no-pub --reporter expanded` | PASS, 100/100 tests |
| `flutter build apk --debug --no-pub` | PASS (28.9 giây ở lượt cuối) |

Thêm 11 regression tests trong:
- `test/services/firestore_tasks_regression_test.dart`: gọi adapter Firestore thật với SDK fakes, kiểm tra 3 documents/legacy ID/empty result.
- `test/viewmodels/session_regression_test.dart`: delayed reads/deletion sau logout, dispose khi request đang chạy, Advisor reset, logout telemetry.
- `test/regression_widget_test.dart`: Undo ở giây thứ 7 và persisted state; toggle failure UI; Remote Config gate rebuild; export từ chối khi reload lỗi.

Sửa `test/viewmodels/roadmap_viewmodel_test.dart` để await `loadData()` trong setup. Test prerequisite trước đó đọc state chưa tải xong. Full suite ban đầu phát hiện thêm auth stream replay làm supersede notification load: đã guard theo UID và chạy lại full suite thành công. Widget export test cũng phát hiện duplicate Hero tags: đã sửa source, không bỏ assertion.

Build còn cảnh báo native-access Java và Kotlin plugin compatibility cho Flutter tương lai. Không nâng dependency trong đợt sửa này.

## Xác minh emulator

Thiết bị do người dùng chọn: `Pixel_7_API_35_Google_Play`, serial `emulator-5554`, Android 15, 1080×2400.
Đã dùng ARTEMIS hierarchy/screenshot và ADB để khám phá UI trước khi viết regression tests.

1. Cài cập nhật APK bằng `adb install -r`, giữ dữ liệu app.
2. Cold start, Home và phiên đăng nhập được khôi phục. Lượt launch đầu có `am start -W` timeout dù app sau đó render; lượt cold start tiếp theo `Status: ok`, 6.522 giây. Không che giấu lượt timeout.
3. Tạo qua UI ba fixture `FIX20261104_A/B/C`, Tasks hiển thị 3 mục.
4. Force-stop và cold start, mở lại Tasks: vẫn đủ cả 3 mục; đây là kiểm tra reload đường đọc thực, không chỉ state optimistic.
5. Tick fixture A: số chưa xong từ 3 xuống 2, đã xong từ 0 lên 1, có action Hoàn tác. Bấm Hoàn tác: trở lại 3/0. Thời hạn chính xác kiểm tra bằng widget test tại giây thứ 7; không suy diễn timing từ model latency.
6. Chỉ xóa 3 fixture vừa tạo bằng UI; danh sách trở lại 0 mục. Không xóa dữ liệu có sẵn.
7. Mở Sync Vault từ Home: route hoạt động, có các controls RC, non-fatal, test crash và export. Không bấm gây crash hoặc upload trong smoke này.
8. Log khởi động xác nhận Firebase initialize, RC fetch/activate; có log `task_complete`. Không thấy fatal/unhandled/duplicate Hero trong log được lọc của process đã kiểm tra. Log event không thay thế DebugView.

Evidence:
- `evidence/app/fix-2026-11-04/tasks-after-restart.png`
- `evidence/app/fix-2026-11-04/tasks-after-undo.png`
- `evidence/app/fix-2026-11-04/firebase-demo-controls.png`

Đây là device smoke bằng ADB + ARTEMIS observation, **không phải** 10 ARTEMIS pytest cases × 3 runs.

## Chưa xác minh / còn lại

- PDF Storage upload/share/metadata thật, FCM delivery 3 trạng thái và destination detail arguments.
- DebugView từng event, Crashlytics dashboard nhận cả hai loại lỗi, Console RC before/after, Rules deployment/security tests và cross-account runtime.
- Domain check vẫn là client-side; không chứng minh enforcement server-side hoặc account legacy đã restore.
- Advisor vẫn là rule engine cục bộ; GPA là sandbox, chưa có transcript/timetable thật. Course Detail chưa đủ nội dung/tab theo thiết kế gốc. Không thêm dữ liệu giả để đánh dấu đạt.
- ARTEMIS harness còn assertions yếu/phụ thuộc thứ tự; cần khám phá các flow còn lại trước khi sửa test, pin commit/toolchain và chạy ≥3 lần/test. Chưa có lượt ARTEMIS mới được công bố PASS trong đợt này.
- `docs/code-review.md` có findings/decisions từ Codex review source local; còn thiếu PR reviewer output và 3 commit fix có liên kết.
- Report/slides hiện có giữ nguyên, vẫn là draft với placeholder; chưa tạo video hay điền Student ID thay người dùng.

Không dùng kết quả local để tuyên bố Lab 3 hoàn thành hoặc dự đoán điểm rubric.
