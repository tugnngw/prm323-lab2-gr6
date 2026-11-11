# Nội dung thuyết trình Final — FPTU Second Brain

14 slide. Mỗi mục có nội dung đặt trên slide, hình minh họa và lời nói. Dòng **chờ evidence** cần thay bằng ảnh hoặc số liệu thật sau khi ghép web và chạy demo. Thời lượng video theo đề là 8–12 phút.

## 01 — FPTU Second Brain

- **Trên slide:** Lộ trình học, công việc, ghi chú và duyệt kế hoạch học tập. PRM393 Final · Nhóm GR6.
- **Hình:** Trang chủ Android và màn web khi đã deploy.
- **Lời nói:** “Nhóm em nối thiết kế Lab 2 và ứng dụng Lab 3 thành một hệ thống. Sinh viên dùng Android để quản lý việc học và gửi kế hoạch. Staff dùng web để xử lý yêu cầu trên cùng dữ liệu.”

## 02 — Vấn đề và người dùng

- **Trên slide:** Sinh viên cần biết môn nào học trước, việc nào sắp đến hạn và kế hoạch đang ở trạng thái nào. Staff cần một danh sách yêu cầu để xử lý. Admin quản lý vai trò.
- **Hình:** Ba thẻ persona, mỗi thẻ một nhiệm vụ.
- **Lời nói:** “Persona chính là sinh viên FPTU. Điểm và lịch cá nhân do sinh viên tự nhập. Staff chỉ xem phần kế hoạch sinh viên chủ động gửi duyệt.”

## 03 — Từ Lab 2 đến Final

- **Trên slide:** Lab 2 có Figma, token và luồng mẫu. Lab 3 có Flutter, Firestore, FCM, Analytics, Crashlytics, Remote Config và PDF. Final thêm vai trò, duyệt kế hoạch, inbox và AI Logic.
- **Hình:** Ba mốc thời gian. Đánh dấu web và luồng deploy là chờ evidence.
- **Lời nói:** “Nhóm giữ lại luồng học tập đã có. Mục tiêu của Final là ghép các client và xác minh hành vi thực tế trên cùng backend.”

## 04 — Kiến trúc hai client

- **Trên slide:** Flutter Android → Firebase Auth, App Check, Firestore, AI Logic. Web Admin → Firebase Auth, App Check, Firestore. Firebase Hosting phục vụ web tĩnh. Flutter sử dụng MVVM. Gói Dart `packages/core` chứa model và truy cập Firestore của phần mới.
- **Hình:** Hai client hai bên, Firebase ở giữa. Vẽ mũi tên ghi và mũi tên snapshot riêng.
- **Lời nói:** “Auth xác định người dùng. App Check chứng thực client. Rules quyết định thao tác trên từng tài liệu. Firestore đẩy snapshot mới về client đang theo dõi. Sơ đồ mô tả đường chạy Final; các tiện ích server của Lab 3 được trình bày riêng nếu được hỏi.”

## 05 — Luồng sinh viên trên Android

- **Trên slide:** Đăng nhập → Trang chủ → Lộ trình → chi tiết môn và tiên quyết. Việc cần làm, Ghi chú và Hồ sơ học tập dùng dữ liệu tài khoản. PDF tạo trên thiết bị và chia sẻ bằng hệ điều hành.
- **Hình:** Bốn ảnh từ APK trên máy thật khi có.
- **Lời nói:** “Mã môn và danh mục đến từ Firestore. Điểm được nhập vào hồ sơ riêng. Khi xuất PDF, file ở thiết bị. Firestore ghi tên file, dung lượng và thời điểm tạo.”

## 06 — Web Staff/Admin

- **Trên slide:** Google Sign-In theo vai trò · Quản lý môn · Hàng đợi duyệt · Dashboard · Đăng thông báo.
- **Hình:** Chờ evidence URL Firebase Hosting và ảnh từng màn. Dashboard dùng ba số liệu tổng hợp và một biểu đồ.
- **Lời nói:** “Sinh viên vào web sẽ thấy thông báo sai vai trò. Staff quản lý danh mục và quyết định hồ sơ. Admin cấp vai trò. Khi demo, mở URL ở cửa sổ ẩn danh rồi đăng nhập tài khoản Staff.”

## 07 — Một lần gửi, hai màn hình cập nhật

- **Trên slide:** Mobile tạo `pending` → Web duyệt hoặc từ chối kèm lý do → Mobile hiển thị kết quả qua snapshot listener. Thông báo chung dùng collection `announcements`.
- **Hình:** Sequence diagram; đặt hai màn cạnh nhau khi quay.
- **Lời nói:** “Sinh viên chọn kỳ, kiểm tra nội dung rồi gửi. Staff mở bản ghi pending, nhập lý do và duyệt. Mobile đang mở màn sẽ cập nhật từ Firestore. Nhóm đo độ trễ từ lúc ghi được xác nhận trên web đến lúc mobile đổi trạng thái.” **Chờ evidence:** 3 lượt trên bản deploy, ghi số giây thực đo.

## 08 — Dữ liệu và Security Rules

- **Trên slide:** `users/{uid}` chứa vai trò và hồ sơ riêng. `courses` là danh mục. `study_plan_submissions` chứa kỳ, nội dung, trạng thái và lý do. `announcements` chứa nội dung công bố.
- **Hình:** Bảng quyền rút gọn hoặc một cặp allow/deny.
- **Lời nói:** “Rules ràng buộc UID chủ hồ sơ. Sinh viên chỉ tạo trạng thái pending. Staff chỉ chuyển pending sang approved hoặc rejected và không đổi chủ sở hữu. Admin chỉ đổi trường role của tài khoản khác. Không dựa vào việc ẩn nút trên UI để bảo mật.”

## 09 — Gemini hỗ trợ lập kế hoạch

- **Trên slide:** Chọn kỳ → Firebase AI Logic → JSON `goal` và `actions` → validate → nhãn AI → người dùng chọn dùng và chỉnh sửa → gửi.
- **Hình:** Một input thật và JSON thật sau khi đã kiểm tra cloud. Thêm ảnh bản nháp editable.
- **Lời nói:** “Prompt chỉ nhận số kỳ học. Không gửi câu hỏi tự do, tên, email, điểm hay lịch. AI đề xuất nội dung, sinh viên quyết định. Khi quota hoặc mạng lỗi, người dùng vẫn nhập thủ công và gửi.”

## 10 — Remote Config và Analytics

- **Trên slide:** Remote Config lưu model, prompt và cờ bật/tắt. Analytics ghi `ai_request`, `ai_result_accepted`, `ai_error`.
- **Hình:** Firebase Console cạnh màn app. Chờ ảnh đổi cờ trên cùng APK và DebugView các event mới.
- **Lời nói:** “Remote Config được fetch và activate. Khi tắt cờ, nút AI biến mất và form thủ công vẫn hoạt động. Analytics dùng để kiểm tra số lượt yêu cầu, lượt chấp nhận và lỗi, với payload không chứa nội dung nhập.”

## 11 — FCM và Crashlytics

- **Trên slide:** FCM SDK lấy registration token và đồng bộ bản ghi thiết bị. Firebase chuyển push đến token. App xử lý trạng thái chạy và dùng payload để điều hướng. Crashlytics thu thập crash và non-fatal.
- **Hình:** Sơ đồ FCM và ảnh Crashlytics đã che thông tin.
- **Lời nói:** “Token do dịch vụ FCM cấp cho bản cài đặt. Client lấy qua SDK, lưu bản đăng ký trong Firestore và cập nhật khi token đổi. Luồng Lab 3 có script FCM HTTP v1 trong `admin-web/send-fcm.mjs`. Inbox Final dùng Firestore listener. Với crash, nhấn nút demo, mở lại app và chờ dashboard nhận báo cáo.”

## 12 — Kiểm thử và review

- **Trên slide:** Mốc Lab 3 có 124 Flutter test, 4 HTTP test và 10 ca ARTEMIS có ít nhất 3 lượt pass. Final bổ sung test Rules, checklist web, ARTEMIS và 3 lượt liên vai trò trên bản deploy.
- **Hình:** Bảng có cột phạm vi, thiết bị, pass rate và trace. Thêm tối thiểu 3 finding review mới cùng quyết định.
- **Lời nói:** “Các số Lab 3 được ghi riêng. Final chỉ tính những lượt đã chạy trên phiên bản tương ứng. TC_14 và exploratory Lab 3 có giới hạn đã ghi trong evidence. Nhóm sẽ trình bày test deny quan trọng nhất và một lần chạy thực tế.”

## 13 — Trình tự demo live

- **Trên slide:** Android thật → mỗi màn web → gửi và duyệt song song → đăng announcement → AI thành công và tắt bằng Remote Config → chạy test.
- **Hình:** Timeline khoảng 10 phút, có hai ô quay song song.
- **Lời nói:** “Chuẩn bị hai tài khoản riêng và một kỳ chưa có hồ sơ demo. Khi duyệt, giữ app mở để quan sát thời gian thực. Sau khi AI chạy, đổi Remote Config, fetch lại và nhập thủ công để chứng minh fallback.”

## 14 — Kết quả, bài học và Q&A

- **Trên slide:** Phân quyền ở backend. Snapshot listener giảm thao tác làm mới. AI có schema và người dùng giữ quyền quyết định. [Repo] · [Web URL] · [Video].
- **Hình:** QR hoặc ba link đã kiểm tra bằng cửa sổ ẩn danh.
- **Lời nói:** “Bài học chính là kiểm tra đường đi của dữ liệu và quyền trên cả hai client. Độ trễ, pass rate và kết quả review sẽ lấy từ phiên demo đã ghi.”

## Câu hỏi dễ gặp

- **FCM token khác ID token thế nào?** FCM token định tuyến push tới bản cài đặt. Firebase Auth ID token xác thực danh tính và phiên đăng nhập. FCM token không chứng minh quyền.
- **Vì sao người dùng không tự làm Staff?** Rules chặn tạo tài khoản với role đặc quyền và chặn tự sửa role. Admin đổi role của tài khoản khác qua write giới hạn trường.
- **Vì sao app đổi trạng thái ngay?** Màn mobile đăng ký snapshot của yêu cầu thuộc UID đang đăng nhập. Sau khi web ghi trạng thái, Firestore gửi snapshot cập nhật về app.
- **App Check và Rules khác nhau thế nào?** App Check kiểm tra nguồn ứng dụng. Rules kiểm tra tài khoản có quyền thực hiện thao tác với tài liệu cụ thể.
- **Nếu AI trả JSON sai hoặc hết quota?** App kiểm tra kiểu, số lượng hành động và độ dài. Nếu lỗi thì ghi event và giữ form thủ công.
- **PDF ở đâu?** Byte PDF tạo tại thiết bị, hệ điều hành chia sẻ file. Firestore chỉ lưu metadata.
