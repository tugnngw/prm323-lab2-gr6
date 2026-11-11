# Web quản trị học vụ, FCM server và media API

## Cổng quản trị học vụ (Firebase Hosting)

`admin-web/` là SPA tĩnh được deploy qua Firebase Hosting (`firebase.json` trỏ `public: admin-web`). Đăng nhập bằng Google; rules chỉ cho tài khoản `users/{uid}.role` là `staff` hoặc `admin`. Tài khoản sinh viên bị từ chối và tự đăng xuất.

- **Chuyên ngành**: danh sách chuyên ngành thật từ Firestore. Nút **Thêm chuyên ngành** có hai lựa chọn: nhập thủ công (form ngành + form môn với slot/đầu điểm/LO/giáo trình) hoặc nhập file HTML FLM (1 trang chương trình + N trang đề cương, xem trước rồi lưu batch).
- **Duyệt bí kíp**: hàng đợi realtime của `experience_notes` do sinh viên gửi từ mobile. Cán bộ nhập lý do rồi duyệt/từ chối; rules chỉ cho sửa `status/reason/reviewedBy/reviewedAt` trên bản ghi `pending`.
- **Thông báo**: đăng `announcements` bằng UID người đăng; mobile nhận realtime.
- **Dọn dữ liệu cũ**: gõ `XOA` để xóa `majors`, `courses`, `curriculums`. Không xóa người dùng, thông báo hay bí kíp.
- Không có seed/mock data. Dashboard dùng `getCountFromServer` cho số liệu tổng hợp và `onSnapshot` cho bảng/biểu đồ.
- Chạy thử cục bộ: `firebase emulators:start --only hosting,firestore,auth` rồi mở http://127.0.0.1:5000/?emulator=true (tham số này nối Auth/Firestore vào emulator). Deploy: `firebase deploy --only hosting`. Khi chạy với Firebase production trên domain khác, thêm domain đó vào **Authentication → Settings → Authorized domains**.

### Cấp quyền Admin đầu tiên

1. Đăng nhập web một lần bằng tài khoản Google cần cấp quyền (sẽ bị từ chối vì chưa có role).
2. Trong Firebase Console → Firestore → `users/{uid}`, đặt `role: "admin"` (hoặc `staff`).
3. Đăng nhập lại. Admin có thể cấp role cho tài khoản khác bằng cách sửa đúng trường `role` trên document của họ.

## Dashboard Crashlytics cũ (Node, tùy chọn)

Dashboard Node bên dưới vẫn dùng được cho báo cáo Crashlytics. Dev vẫn có thể xem Firebase Console. Dashboard lấy báo cáo `topIssues` từ Crashlytics REST API qua Node, sau đó hiển thị số sự kiện và số người bị ảnh hưởng. Mật khẩu web và OAuth của server là hai lớp riêng.

## Web admin

1. Dùng Node 22 trở lên. Trong thư mục này chạy `npm ci` và sao chép `.env.example` sang `.env`. Đặt `ADMIN_PASSWORD` riêng, ít nhất 24 ký tự.
2. Dùng Application Default Credentials (ADC) của tài khoản có quyền đọc báo cáo Crashlytics trên đúng project. Trên máy demo có gcloud, chạy `gcloud auth application-default login` và chọn tài khoản được cấp quyền. Kiểm tra quyền `firebasecrash.reports.get` cùng quyền đọc Crashlytics trong IAM. Có thể dùng `FIREBASE_ACCESS_TOKEN` ngắn hạn trong môi trường tiến trình cho buổi thử.
3. Chạy `npm start`, mở http://127.0.0.1:8787. Đăng nhập user `admin` với mật khẩu vừa đặt. Bấm **Tải lại báo cáo** sau khi mở lại app đã crash và Firebase xử lý.
4. Server chỉ lắng nghe loopback. Nếu cần nhiều admin từ xa, triển khai qua HTTPS với xác thực và phân quyền riêng thay cho Basic Auth local.

Xem [Crashlytics REST API](https://firebase.google.com/docs/reference/crashlytics/rest/v1alpha/projects.apps.reports/get) và [quyền IAM Crashlytics](https://docs.cloud.google.com/iam/docs/roles-permissions/firebasecrash).

## Gửi FCM từ server

Dùng môi trường server có quyền đọc registration trong Firestore và gửi FCM HTTP v1 trên project. Mở app bằng tài khoản demo trên thiết bị đích để registration được cập nhật. Dùng UID của tài khoản demo, không dùng email.

```powershell
npm run send:fcm -- DEMO_UID PRM323
npm run send:fcm -- DEMO_UID PRM323 --send
```

Lệnh đầu kiểm tra request với FCM qua `validate_only`. Lệnh thứ hai gửi thật. Script chọn registration cập nhật gần nhất trong `users/{uid}/tokens`, từ chối token cũ quá 24 giờ và không in token. Payload gồm nội dung ngắn cùng `route=/course-detail` và `courseId`. Chỉ chọn tài khoản demo có một thiết bị đang dùng, vì lệnh chọn bản ghi mới nhất. Server chỉ gửi mã môn và thông báo chung, tránh đưa dữ liệu cá nhân vào thông báo hệ thống.

## Lưu báo cáo và tệp đính kèm trên Cloudinary Free

Sao chép `.env.example` sang `.env` nếu chưa có. Điền ba biến `CLOUDINARY_*` ở server. Trong Cloudinary Console, mở **Settings → Security** và bật **Allow delivery of PDF and ZIP files**. Chạy `npm run start:media` từ thư mục này. Media API xác minh Firebase ID token và đối chiếu UID trước khi truy cập tài sản `raw` có chế độ `authenticated`. Firebase Spark tiếp tục phục vụ đăng nhập và Firestore.

Kết nối Android qua USB. Chạy từ thư mục gốc và thay `ANDROID_SERIAL` bằng serial từ ADB. Nếu bạn đổi `MEDIA_PORT` thì cập nhật cổng ở cả hai lệnh.

```powershell
adb devices -l
adb -s ANDROID_SERIAL reverse tcp:8788 tcp:8788
flutter run -d ANDROID_SERIAL --dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788
```

- Trong **Ghi chú → Tải tệp lên**, chọn Markdown, PDF, DOCX, TXT, PNG hoặc JPEG dưới 10 MB. Đợi tiến độ kết thúc, kiểm tra tiêu đề và mã môn rồi lưu. Mở lại ghi chú để tải tệp xuống hoặc hỏi AI với nguồn hỗ trợ. Firestore giữ tên và đường dẫn dưới `notes/{uid}/cloudinary/`. Tệp đã lưu bằng Firebase Storage vẫn tải qua adapter Firebase.
- Trong **Sync Vault**, chọn **Xuất & Tải PDF lên Cloudinary** rồi xác nhận. Kiểm tra metadata Firestore và dùng **Tải lại PDF từ cloud** để tải bản đã upload. Địa chỉ Media API cần phiên đăng nhập của app. Server giữ URL ký Cloudinary.
- Mở **Lịch sử báo cáo** trong Sync Vault để tải lại tối đa 30 báo cáo gần đây. App chọn kho tải theo metadata Firestore của từng báo cáo.
- Khi lưu ghi chú sau khi gỡ hoặc thay tệp, app đối chiếu đính kèm hiện tại trên Firestore rồi cập nhật liên kết. App xóa tệp cũ sau khi lưu thành công. Nếu kho lưu trữ từ chối xóa, app báo lại sau khi lưu.
- Xem **Media Library** để đối chiếu file raw của hai luồng. Kiểm tra trong giới hạn gói Free và bằng tệp thử trước khi dùng dữ liệu thật.

Trên bản phát hành, dùng URL HTTPS cho Media API và đặt dịch vụ sau reverse proxy HTTPS. Bản debug cho phép HTTP chỉ tới loopback để chạy USB. Không chép `.env`, token hoặc Cloudinary key vào APK hay Git. Kiểm tra product environment Cloudinary đã cho phép delivery PDF trước khi chấm. [Tài liệu Cloudinary về asset riêng và tải có chữ ký](https://cloudinary.com/documentation/control_access_to_media).

`npm test` kiểm tra xác thực web, upload PDF và tải lại tệp đính kèm qua HTTP local, gồm các nhánh sai chủ tài khoản và giới hạn kích thước. Xem [kết quả kiểm tra Cloudinary thật](../evidence/app/cloudinary-2026-11-05/verification.json).

## Cố vấn học tập với Gemini

Điền `GEMINI_API_KEY` từ Google AI Studio vào `admin-web/.env` và khởi động lại `npm run start:media`. Có thể đặt `GEMINI_MODEL` nếu tài khoản dùng model khác. App dùng cùng `REPORT_MEDIA_URL` với Media API.

Sau khi người dùng đồng ý, app gửi câu hỏi, cấp tư vấn và dữ kiện danh mục môn qua endpoint có kiểm tra Firebase ID token. Điểm, lịch và nội dung ghi chú được xử lý trên thiết bị. Hộp thoại nhắc người dùng tránh nhập thông tin riêng vào câu hỏi. Backend giữ key Gemini và trả trạng thái để app hiện lỗi cấu hình hoặc giới hạn lượt hỏi. [Gemini API](https://ai.google.dev/api/generate-content).
