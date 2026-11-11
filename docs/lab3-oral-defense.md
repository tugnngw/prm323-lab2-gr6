# Ôn giải thích Lab 3 theo yêu cầu chấm mới

## FCM hoạt động thế nào?

FCM registration token là địa chỉ định tuyến của một **lần cài app**. SDK Firebase Messaging đăng ký app instance với FCM, nhận token từ hạ tầng Firebase. Token có thể đổi khi cài lại, xóa dữ liệu hoặc khi SDK làm mới registration. Token định tuyến khác Firebase Auth ID token. ID token dùng xác thực người dùng với backend.

Client giữ registration trong SDK. Sau đăng nhập, app lấy token, ghi bản sao vào Firestore dưới `users/{uid}/tokens/{tokenId}`, kèm thời điểm cập nhật. App nghe token refresh và cập nhật lại. Server tra token theo UID. Firestore rules giới hạn client đọc/ghi token theo chủ tài khoản. Code lấy token ở `FirebaseMessagingService.getToken`, điều phối ở `AuthViewModel._registerPushToken`, ghi ở `FirebaseFirestoreService.registerToken`.

```text
App Android + FCM SDK  →  FCM cấp registration token
App đã đăng nhập      →  Firestore lưu token theo UID
Máy chủ tin cậy       →  đọc token, lấy OAuth, gọi FCM HTTP v1
FCM                   →  thiết bị đích nhận notification + data
Client                →  lưu thông báo, mở màn theo route được phép
```

Code gửi nằm ở [send-fcm.mjs](../admin-web/send-fcm.mjs). Nó tạo payload, gọi `POST /v1/projects/{project}/messages:send`, dùng OAuth phía server. Quyền Android `POST_NOTIFICATIONS` quyết định việc hiển thị thông báo hệ thống. Khi app ở foreground, `onMessage` hiển thị banner trong app. Khi người dùng bấm thông báo lúc app ở nền, `onMessageOpenedApp` nhận sự kiện. Khi app khởi động từ notification, `getInitialMessage` nhận payload. `fcmBackgroundHandler` chạy isolate nền và lưu dữ liệu khi có phiên auth. `NotificationsViewModel` đọc `route` và `courseId`, điều hướng theo danh sách route hợp lệ. Android force-stop trong Settings có thể chặn giao FCM đến khi mở lại app, nên đừng dùng nó để mô phỏng cold start khi chấm.

Câu trả lời ngắn khi thầy hỏi: “FCM cấp token cho instance app. App lưu token theo UID trong Firestore. Backend giữ quyền OAuth và gửi qua HTTP v1. Client xử lý ba đường nhận, rồi mở môn từ payload `courseId`.” [Kiến trúc FCM](https://firebase.google.com/docs/cloud-messaging/fcm-architecture) · [FCM server và credentials](https://firebase.google.com/docs/cloud-messaging/server-environment).

## Crashlytics và web admin

Nút **Gây test crash (đóng ứng dụng)** nằm ở Sync Vault. Sau xác nhận, `CrashlyticsService.testCrash` bật collection rồi gọi SDK native crash. Khởi động lại app để gửi báo cáo đã lưu và đợi Firebase xử lý. Nút non-fatal gọi `recordError` và app tiếp tục chạy. Dev dùng Firebase Console. Admin đăng nhập web riêng, Node gọi Crashlytics REST API và chỉ trả dữ liệu báo cáo cần hiển thị. Trình duyệt không giữ Google OAuth credential.

Cách chứng minh là ghi nhận số event hiện tại trên web, bấm crash trên máy thật, mở app lại, sau đó refresh và đối chiếu số event tăng của nhóm test crash. Số event có thể cập nhật chậm. [Hướng dẫn test crash Android](https://firebase.google.com/docs/crashlytics/android/test-implementation).

## PDF, Firebase Spark và phân quyền

App tạo PDF từ danh sách thật đang hiển thị. Consent quyết định file có rời khỏi thiết bị. Với Cloudinary, app gửi PDF và Firebase ID token đến Media API. API kiểm tra chữ ký token và UID, rồi upload tài sản private bằng key server. Firestore giữ đường dẫn và metadata theo người dùng. Tải lại đi qua cùng kiểm tra quyền. Trên Spark có thể demo tạo/chia sẻ local khi Cloudinary chưa được cấu hình. Demo local chỉ xác minh tạo file và mở share sheet.

## Remote Config, Analytics và Firestore

- **Remote Config** đọc mặc định trong app trước rồi fetch và activate cấu hình. Evidence 31 → 30 lấy từ cùng APK. Admin không cần phát hành APK mới để đổi tham số sync.
- **Analytics** dùng event theo hành động người dùng. DebugView có `export_report_local` với `course_count=4`. Các tham số dùng mã/số lượng, tránh ghi nội dung ghi chú và email. Thời gian nhận có thể trễ.
- **Firestore** đặt dữ liệu cá nhân dưới UID. Firebase Auth xác thực danh tính, Firestore Rules mới quyết định quyền. Cache giữ dữ liệu đã đọc khi mất mạng. Đồng bộ lại khi có mạng. Kiểm tra được hành vi cache không tự động chứng minh hai tài khoản bị cách ly.

## Trình tự chấm trên máy thật

1. Cắm điện thoại Android có Google Play Services, bật USB debugging và chấp thuận máy tính. `adb devices -l` phải hiện serial thật ở trạng thái `device`. Dùng `-s SERIAL` và `-d SERIAL` để tránh chọn emulator. Dùng tài khoản FPT demo đúng domain, cấu hình Android package và SHA của APK demo đúng Firebase project.
2. Mở app, xác minh danh mục, tab môn và thử nhập dữ liệu riêng của tài khoản demo. Ghi model Android, phiên bản APK và bằng chứng theo ca.
3. Mở web admin và xem số event trước thử. Bấm test crash trên điện thoại, mở lại app, chuyển sang FCM/PDF trong lúc đợi, rồi refresh web.
4. Với FCM, chọn đúng UID demo và dùng lệnh server ở trên. Thử foreground, background và cold start, ghi riêng bằng chứng hiển thị và route.
5. Thử consent, upload, metadata và tải lại từ lịch sử Cloudinary. Dùng tài khoản thứ hai để kiểm tra quyền. Mở Cố vấn, xác nhận gửi câu hỏi mẫu về số tín chỉ PRM323 rồi chỉ phần đối chiếu trên thiết bị.
6. Chạy ARTEMIS với `DEVICE_SERIAL` là máy thật, tài khoản thử riêng và quota đủ cho batch. Ca TC_11 đã pass 3/3 lượt trên Pixel 7 giả lập. Thu riêng kết quả và quay demo khi có điện thoại thật.

Tham chiếu setup và lệnh chạy ở [admin-web/README.md](../admin-web/README.md). Slide được để sau theo yêu cầu.
