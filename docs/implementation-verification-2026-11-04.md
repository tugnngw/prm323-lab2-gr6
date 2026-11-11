# Kết quả tiếp tục hạng mục 1–2–3 — 04/11/2026

Phạm vi đã được người dùng cho phép sửa tiếp. Giữ Flutter/Provider và cấu trúc repository; không commit, push, đổi branch hay triển khai cloud rules. Những thay đổi tồn tại trước phiên vẫn được giữ.

## 1. Dữ liệu học tập và điều hướng

- Thêm `AcademicProfile`, `AcademicViewModel`, `/academic-profile`: nhập trực tiếp bảng điểm và thời khóa biểu, kiểm tra dữ liệu trước ghi; merge hồ sơ `users/{uid}` để giữ trường cũ. Người dùng xác nhận tự nhập trực tiếp. Hiện bảng điểm/lịch vẫn trống, không tạo dữ liệu học tập giả.
- Định dạng bảng điểm: `mã môn,tín chỉ,điểm 0–10,kỳ,true/false`; mỗi môn một kết quả hiện hành theo bảng điểm chính thức. GPA có trọng số trên các dòng đã nhập; không khẳng định đây là quy chế tính GPA/học lại chính thức của trường.
- Định dạng lịch: `mã môn,thứ ISO 1–7,slot đầu,số slot`; phát hiện giao nhau theo ngày và khoảng slot. Chưa có dữ liệu giờ học thực tế nên không quy đổi sang giờ/phút.
- Advisor production đọc danh mục/hồ sơ thực; trả lời thiếu dữ liệu rõ ràng. Không gọi LLM ngoài hay gửi bảng điểm vào Analytics. Đây là tư vấn theo quy tắc/dữ liệu, chưa chứng minh một dịch vụ AI sinh nội dung nếu rubric bắt buộc.
- Strategy lấy tín chỉ từ catalog và GPA/lịch từ hồ sơ; slider là điểm giả định do người dùng chọn, không phải điểm thật. Mục tiêu GPA là mục tiêu cá nhân.
- Course Detail có ba tab Lịch slot/Đánh giá/Tổng quan. Catalog Firestore chỉ có 4 môn, không có lịch slot/đầu điểm: đã kiểm tra empty state trên emulator, chưa thể xác minh nhánh có dữ liệu học vụ thực.
- Roadmap dùng kết quả hiện hành trong bảng điểm để ghi đè passedCourses cũ; refresh sau lưu hồ sơ. Không hiện tiến độ 0/0 như dữ liệu thật.
- FCM giữ `routeArgument`/`courseId` qua persist và cold-open; allowlist route, fallback khi thiếu courseId/route lạ, upsert thông báo chưa có khi tap. Unit test không thay thế việc gửi push thực đủ ba trạng thái.
- Sửa hộp thoại PDF: tham số đếm course/task/note trước đây bị đảo; chuyển sang named arguments và thêm widget regression với số lượng khác nhau. Nguồn dữ liệu loading/error không được báo đã reload thành công.
- Crashlytics: opt-in debug không bị tắt lại khi mở app sau test crash; dùng cơ chế persist native và mặc định Android manifest tắt, release bật trong initialize. Không thêm thư viện lưu trữ mới.

## 2. Cloud và bằng chứng thực

| Hạng mục | Kết quả đã xác minh | Còn thiếu |
|---|---|---|
| Firestore | REST đọc được catalog/profile; rules đang deploy tương đương code local khi bỏ comment/khoảng trắng | Kiểm thử account isolation qua tài khoản thử thứ hai, offline write/reconnect |
| Storage/PDF | Consent xuất hiện; SDK upload trả object-not-found; API bucket cấu hình trả 404 | Bucket thực/quyền truy cập, upload thành công, metadata, download/share thành công |
| FCM | Token đã lưu; thử send bị HTTP 403 cloudmessaging.messages.create | Quyền gửi, chứng minh foreground/background/terminated và deep link thật |
| Remote Config | App hiện maintenance=false, AI=true, min=1.0.0, interval=30; UI/unit phản ứng khi config đổi | API GET_TEMPLATE bị 403; chưa có publish trước/sau không build lại |
| Crashlytics | Non-fatal được SDK nhận; đã kích hoạt test crash và log native có FirebaseCrashlyticsTestCrash/FATAL EXCEPTION, mở lại app | Dashboard xác nhận issue và ảnh bằng chứng |
| Analytics | Giữ tracking plan, instrumentation và unit coverage | DebugView xác nhận event thực, dashboard evidence |

Không tự tạo bucket, nâng billing, cấp IAM hoặc deploy rules. Console cần tài khoản có quyền project `prm323-lab2-gr6`.

Computer Use bị chặn vì không xác định đủ chắc URL của cửa sổ trình duyệt Windows; không tiếp tục điều khiển trình duyệt sau chặn và không có ảnh dashboard giả.

## 3. ARTEMIS

- Dùng AVD do người dùng chọn `Pixel_7_API_35_Google_Play`, serial `emulator-5554`, Android 15, 1080×2400.
- Đã quan sát bằng ARTEMIS hierarchy/screenshot trước khi sửa test. SDK được pin; venv pytest riêng, assertion kiểm tra TaskResult.output JSON chặt chẽ; artifact duy nhất mỗi lượt, timeout/poll rõ ràng; khôi phục mạng cả khi offline task lỗi.
- 26 ca = 25 regression ×3 + 1 exploratory, tổng **76 mục collect**; không được tính là 76 ca đã chạy.
- 3 parser unit tests chạy trên host đạt, không tính vào Android E2E.
- Trace `8bc8574e-cc9b-499d-ba0c-9e9ed0eea52a`: bị quota, đã dừng.
- Trace `bb04ee4e-7503-455e-a96c-4db0f604227a`: failed sau key update, quota 429.
- Đã restart daemon chính thức bằng `artemis restart --no-open --daemon` để nạp key mới, chẩn đoán key hợp lệ và device idle trước thử lại.
- Trace SDK `7f318510-6ee2-4904-9fce-0fd1d611a8bd`: pytest thực chạy 1 ca TC_11 trong 198.63 giây, **FAILED**, output=None; log host có 429 (5 requests/min/model), 503 và timeout LLM 180 giây. Kết quả/raw record nằm dưới `evidence/artemis/`. Không lặp batch sau cùng lỗi hạ tầng.
- Thiếu scrcpy tùy chọn nên chưa có video replay. Chưa đạt >=10 ca ×3 hoặc exploratory 15–30 phút. Các ca thay đổi tài khoản/tạo fixture yêu cầu tài khoản FPT thử riêng và E2E_ALLOW_AUTH_CHANGES=1; chưa cấu hình thì SKIP, không tự đăng xuất tài khoản cá nhân.

## Kiểm thử và giới hạn

**Flutter: 112/112 test đạt; flutter analyze: không có lỗi/cảnh báo; 3 parser tests host đạt; Ruff F821 đạt; 76 mục E2E collect.** Kết quả cuối xem log `evidence/app/academic-2026-11-04/`: Flutter tests, analyzer, APK build. Screenshot kiểm tra empty states và form thật trong cùng thư mục. Crash evidence ở `evidence/firebase/crashlytics/`.

Không ghi bảng điểm mẫu vào cloud của người dùng; nhánh save được kiểm tra bằng test doubles, chưa xác nhận lưu/reload bảng điểm thật từ emulator. Chưa hoàn tất toàn bộ Lab: cloud evidence, E2E đủ lượt, tài liệu/slide/video và yêu cầu AI review 3 commits vẫn cần xử lý. Giữ nguyên lệnh cấm tự commit của người dùng.

## Để hoàn tất sớm nhất

1. Dùng tài khoản quản trị mở Firebase Console đúng project, kiểm tra bucket Storage có tồn tại và quyền FCM/Remote Config; không nâng gói nếu chưa quyết định.
2. Khi quyền có: upload PDF + metadata/download/share; gửi push 3 trạng thái; publish RC và refresh cùng APK; chụp DebugView và Crashlytics issue.
3. Dùng model/project ARTEMIS đủ quota, khởi động lại host, chạy TC_11 một lượt thành công rồi >=10 ca ×3; exploratory riêng. Cấu hình tài khoản thử riêng cho auth/write.
4. Nhập dữ liệu học tập thực trong app, kiểm tra lưu/mở lại theo tài khoản, cập nhật tài liệu và quay demo. Không dùng dữ liệu bịa để lấp evidence.


## Nhóm file thay đổi của lượt tiếp tục

- Model/VM mới: `lib/models/academic_profile.dart`, `lib/viewmodels/academic_viewmodel.dart`; cập nhật `course_model.dart`, `notification_model.dart`, `advisor_viewmodel.dart`, `roadmap_viewmodel.dart`, `notifications_viewmodel.dart`.
- UI/DI: `lib/main.dart`, `screens/academic_profile_screen.dart`, `strategy_sim_screen.dart`, `course_detail_screen.dart`, `advisor_screen.dart`, `notifications_screen.dart`, `sync_vault_screen.dart`, `roadmap_screen.dart`, `home_screen.dart`.
- Service: Firestore interface/implementation, messaging payload, sync reload guard, Crashlytics initialize và `android/app/src/main/AndroidManifest.xml`.
- Test Flutter: academic VM, notification routing, advisor setup, PDF consent widget regression, Firestore fakes tương ứng.
- Harness: `e2e_test/conftest.py`, `observations.py`, tám module test, pyproject, README, env example; `tool/test_artemis_observations.py`.
- Evidence và tài liệu: thư mục academic-2026-11-04, Firebase API/error/crash evidence, ARTEMIS run JSON/MD; README/status/checklist và AI code log cập nhật. Danh sách này không nhận công những thay đổi có sẵn của người dùng.

APK cuối build thành công, cài bằng `adb install -r` và mở được Home trên emulator. Xác minh consent PDF bản cuối hiển thị đúng **4 môn / 0 task / 0 note**, đã chụp `pdf-consent-correct-counts.png` và Hủy trước upload. Test logs `.txt` được giữ trong evidence (file `.log` bị gitignore).


## Firebase plugin kết nối lại — tối 04/11

Đã cài Firebase plugin 1.2.0. Phát hiện npm cache thiếu/truncated file làm CLI/MCP không khởi động; tải CLI sạch, khôi phục file cache sinh tự động, xác minh Firebase CLI 15.34.2 chạy được. Không sửa source cho việc sửa cache.

CLI login:list --json đã bất ngờ trả token trong output chẩn đoán. Không ghi token vào source/evidence; sau khi người dùng đồng ý, đã thực hiện logout thu hồi phiên cũ và mở đăng nhập tương tác lại. Các lần kiểm tra tài khoản sau đều capture output trong bộ nhớ và chỉ lấy thông tin cần thiết, không in token.

Đăng nhập lại vẫn dùng tài khoản Gmail hiện tại. Qua Firebase MCP: đọc project ACTIVE thành công; Crashlytics topIssues HTTP403; Remote Config get_template thất bại; Storage object probe HTTP404. Gcloud getIamPolicy bị từ chối. Cài plugin/đăng nhập lại không tự cấp IAM. Chưa thay đổi billing, IAM, rules hay deploy config. Bằng chứng không chứa token: evidence/firebase/plugin-verification-2026-11-04.json.


## Chẩn đoán E2E bổ sung — khoảng 19:43–20:15

Đã kiểm tra lại bằng model default cũ: trace `cd2d05b0-7275-42f2-a76e-a6b7e22f37af` gặp 503/504, dừng cancelled sau 187.63 giây. Probe Gemini 2.5 Flash với cùng key trả OK, nên sao lưu `C:/Users/duong/tools/artemis/config/artemis.jsonc` vào `C:/Users/duong/AppData/Local/Temp/prm393-artemis-before-model-switch-20261104-194622.jsonc`, đổi default/fallback và history chunking sang 2.5 Flash. Đây là cấu hình công cụ ngoài repo, không phải thay kiến trúc ứng dụng.

Trace `bcfd68cb-c26d-497d-be9b-9e05b2e95eba` thất bại thực (161.80 giây): có Android ANR `Input dispatching timed out (Application does not have a focused window)`. Host Windows lúc đó chỉ còn khoảng 400 MB RAM; chưa đủ bằng chứng kết luận đây là lỗi logic Dart. Đã lưu ảnh/lastanr trong `evidence/artemis/anr-2026-11-04/`. Dừng 1 Gradle daemon dùng xong giải phóng RAM, người dùng tự đóng Delta Force; RAM trống tăng hơn 6 GB. Đã reboot AVD, giữ app/data; native startup wait sau reboot xác minh Home trong 2.8 giây. Cửa sổ emulator còn được ghi nhận minimized, nên chưa kết luận tính ổn định của tương tác trong batch dài.

Trace `b6200a0a-0ac8-4bfe-b4c5-9597b7268ae7`: ARTEMIS completed nhưng SDK không trả output; pytest **FAILED** sau 33.87 giây. Không được tính là PASS. Đã xác minh API `/api/sessions/{id}/steps` có terminal report JSON đúng session; sửa adapter lấy đúng hành động cuối, từ chối sai session/nonterminal/failed, giữ native UI evidence riêng. 7 parser/adapter unit tests đạt. Native XML ADB dùng UTF-8; startup chờ semantics thực trước submit; pytest timeout tăng 480 giây. Lỗi trước submit cũng có artifact và không tính là task ARTEMIS đã thực thi.

Trace `c9319503-8636-4b17-ab32-e8389474fe7a`: FAILED sau 204.93 giây; log xác nhận Gemini 2.5 Flash bị `GenerateRequestsPerDayPerProjectPerModel-FreeTier`, limit **20/day**. Dừng chạy thêm model/batch; key hợp lệ không đồng nghĩa đủ quota. Không tự tăng billing hay gọi thêm model khác để lấp số lượt.

Tổng trạng thái vẫn là **0 E2E PASS**, chưa đạt >=10 ca ×3/exploratory. Collection vẫn 76; Ruff F821 và 7 host tests đạt, không thay thế device E2E. Các thay đổi lượt này chỉ nằm ở harness/tài liệu/evidence và cấu hình ARTEMIS ngoài repo; 112 Flutter tests/analyzer/APK của bản app trước vẫn là mốc xác minh cuối, không có thay đổi Dart trong lượt này.

## Tài khoản quản trị đang chờ cấp quyền

Người dùng cung cấp tài khoản quản trị khác. Đã mở đúng trang Google cho tài khoản đó; trang còn yêu cầu cấp quyền quản trị Firebase/Google Cloud cho Firebase CLI. Chưa bấm Cho phép khi chưa có xác nhận tại thao tác. Chưa kiểm chứng quyền hay claim tài khoản mới đã kết nối, và chưa thay IAM/billing/cloud config.


## Cập nhật sau khi đăng nhập quản trị và deploy Remote Config

Mục này thay thế các trạng thái “OAuth pending/403” ở các mốc lịch sử bên trên. Firebase CLI đã đăng nhập thành công tài khoản quản trị sau khi người dùng cấp quyền. Không thay IAM hoặc billing.

- **Remote Config:** người dùng duyệt thử 31 phút rồi trả 30. Đã deploy hai template, đọc lại cloud và quan sát UI lần lượt 31/30 trên cùng APK, không build/cài lại giữa hai mốc. Trạng thái cuối: maintenance=false, AI=true, min version=1.0.0, interval=30. Bằng chứng: `evidence/firebase/remote-config/same-apk-2026-11-04.json`, hai ảnh UI và lịch sử phiên bản. `firebase.json` trỏ template cuối 30; template thử 31 được giữ riêng.
- **FCM:** gửi thật qua Firebase, xác minh foreground banner + lưu Firestore; background notification + chạm mở + read=true; terminated được kiểm tra Launcher và PID rỗng trước gửi, sau đó notification khởi động lại app. Cold-start push mang route/courseId mở đúng chi tiết PRM323 ba tab, metadata được lưu và đánh dấu đã đọc. Xem `evidence/firebase/fcm/*verification*`, `deep-link-persistence-2026-11-04.json`, ảnh và callback log. Một lần thử terminated không đạt tiền điều kiện đã bị loại, không tính PASS.
- **Crashlytics:** tài khoản quản trị đọc được báo cáo API, có native test crash FATAL và test non-fatal đã được backend ghi nhận. Xem `evidence/firebase/crashlytics/admin-api-report-2026-11-04.json`. Chưa có ảnh dashboard; không đánh đồng SDK log với backend evidence.
- **Storage:** truy vấn bằng quyền quản trị trả danh sách bucket rỗng; bucket cấu hình trả 404; project chưa gắn billing. Đây là thiếu hạ tầng, không còn chỉ là thiếu quyền của tài khoản cũ. Chưa upload PDF/lưu metadata thành công trên cloud. Không tự nâng Blaze hoặc tạo tài nguyên tính phí.
- **ARTEMIS:** các thao tác native được ARTEMIS quan sát và ADB kiểm tra trong các thử nghiệm Firebase trên không thay thế pytest E2E. Vẫn 0 E2E PASS; chưa đạt >=10 ca x3 hoặc exploratory 15–30 phút. Quota LLM và tài khoản thử riêng vẫn cần xử lý.

## PDF trên thiết bị

Bổ sung nhánh tạo PDF cục bộ, tái sử dụng ReportPdfService/font và menu chia sẻ sẵn có; không cần Storage. Consent riêng nói rõ dữ liệu nằm trên thiết bị. Lỗi Analytics không làm mất PDF; lỗi mở menu chia sẻ hiển thị thông báo. Nhánh upload cloud hiện có được giữ. Event `export_report_local` chỉ ghi số lượng/kích thước, không nhận là upload hay gửi file thành công.

114 Flutter tests đạt (thêm kiểm tra local generation không gọi upload/metadata dù cloud lỗi, và widget hủy consent không ghi cloud). Analyzer không có issue. Việc thử trên thiết bị và APK cuối được ghi riêng trong `evidence/app/local-pdf-2026-11-04/`; không thay đổi hash của bằng chứng Remote Config cùng APK trước đó.

Thứ tự hoàn tất: xác minh local PDF/share trên máy; bổ sung Analytics DebugView và ảnh dashboard; khi người dùng tự bật billing/tạo bucket thì upload/metadata/download; khi đủ quota và tài khoản thử thì chạy ARTEMIS đủ số lượt; cuối cùng chốt evidence/tài liệu/video. Chưa commit/push/đổi branch.


### Xác minh bổ sung PDF và dashboard

APK PDF mới đã build/cài thành công. ARTEMIS hierarchy xác nhận consent 4 môn/0 task/0 note, tạo file 20,518 bytes, và Android “Sharing 1 file” với tên study_report_*.pdf. Chỉ mở chooser, không chọn người/app nhận. Trích PDF từ cache của app debug bằng run-as; pypdf đọc 1 trang, đủ 4 mã môn; render Poppler và kiểm tra trực quan chữ tiếng Việt/bố cục không bị cắt. File/ảnh/log/hash nằm trong `evidence/app/local-pdf-2026-11-04/`.

Đã chụp dashboard Crashlytics bằng tài khoản quản trị: `dashboard-native-crash-2026-11-04.png` có FirebaseCrashlyticsTestCrash và `dashboard-nonfatal-2026-11-04.png` có _testCrashlytics (2 events). Trạng thái “chưa ảnh dashboard” ở mốc trước nay đã được giải quyết. Không đóng/xóa các issue cũ.

Đã bật Analytics debug cho riêng com.example.prm323_lab3 qua ADB. Native FA log xác nhận export_report_local và Successful upload; lưu `evidence/firebase/analytics/debug-device-2026-11-04.txt`. Đây là bằng chứng SDK/network, chưa tự nhận là ảnh DebugView.


### Analytics DebugView đã nhận custom event

Sau khi refresh/chờ backend và chọn thiết bị sdk_gphone64_x86_64, DebugView hiện export_report_local. Đã mở Parameters và xác minh course_count=4; ảnh `evidence/firebase/analytics/debugview-export-local-2026-11-04.png` và `debugview-export-parameters-2026-11-04.png`. Đây là xác minh backend thực, thay thế trạng thái chưa có ảnh DebugView ở mốc trước. Chưa tuyên bố tất cả >=7 custom events đã được chạy/đối chiếu Console trong lượt này; tracking plan/callsite và runtime coverage là hai tiêu chí khác nhau.

Không còn thao tác cloud đang chờ trả Remote Config: cloud đã về 30. Không sửa IAM, không bật billing, không tự commit/push. Những phần chưa đạt: Storage upload/metadata/download; coverage Analytics đầy đủ; ARTEMIS >=10 ca x3 và exploratory; thử offline/account isolation bằng tài khoản riêng; hoàn tất tài liệu/video và 3 commit AI review theo rubric khi được người dùng cho phép commit.
