# PRM393 Lab 3 — FPTU Second Brain

Bản nội dung báo cáo ngày 07/11/2026. Trang bìa và tên file nộp chờ tên và MSSV. Android package là `com.example.prm323_lab3`.

## 1. Mục tiêu và phạm vi

Ứng dụng giúp sinh viên tra lộ trình, theo dõi công việc, lưu ghi chú, nhập bảng điểm và lịch cá nhân, hỏi Cố vấn và xuất PDF. Dự án triển khai trên nền Flutter của Lab 2. Firebase Spark phục vụ Auth, Firestore, FCM, Analytics, Crashlytics và Remote Config. Media API kết nối Cloudinary cho file và Gemini cho hỏi đáp.

## 2. Kiến trúc

Flutter tách Screen, ViewModel và Service. ViewModel biểu diễn trạng thái tải, dữ liệu, rỗng và lỗi. Firebase Auth cung cấp UID. Firestore Rules kiểm soát đọc/ghi hồ sơ, task, note, token, notification và metadata dưới UID tương ứng. Danh mục môn tách khỏi dữ liệu cá nhân. Advisor và Strategy dùng danh mục và hồ sơ nhập thật, giữ trạng thái thiếu dữ liệu khi chưa có lịch hoặc điểm.

Web admin đọc báo cáo Crashlytics qua Node và OAuth phía server. Trình duyệt chỉ nhận danh sách sự cố đã lọc. Dev có thể đối chiếu với Firebase Console. Media API riêng xác thực Firebase ID token của client rồi dùng Cloudinary key của server. Hai tiến trình phục vụ hai mục đích và dùng hai kiểu xác thực.

## 3. Luồng chính và nguyên lý

- Roadmap hiển thị catalog Firestore, đối chiếu môn tiên quyết và mở ba tab chi tiết. Bảng điểm và lịch là dữ liệu riêng do sinh viên nhập.
- Tasks xử lý sửa, toggle, lỗi ghi và Hoàn tác. Notes dùng Firestore và phục hồi dữ liệu từ cache khi có bản đọc trước đó.
- FCM SDK nhận registration token từ Firebase. App ghi bản sao theo UID. Server đọc bản ghi gần nhất, gọi HTTP v1 có OAuth, và gửi dữ liệu `route` cùng `courseId`. Client xử lý callback khi app mở, khi chạm thông báo từ nền và khi mở từ trạng thái process đã dừng.
- Nút test crash gọi native SDK sau khi xác nhận. Lần mở lại cho phép SDK gửi báo cáo. Admin xem kết quả trên web, dev xem console. Nút non-fatal ghi lỗi trong khi app tiếp tục chạy.
- Remote Config fetch/activate thay tham số ở runtime. Đã xác minh 31 rồi trả 30 trên cùng APK.
- Cố vấn xin xác nhận trước khi gửi câu hỏi, cấp tư vấn và dữ kiện danh mục tới Gemini. Điểm, lịch và ghi chú cá nhân được xử lý trên thiết bị.
- PDF được tạo từ dữ liệu đang hiển thị, có consent trước upload. Cloudinary nhận asset raw authenticated. Firestore chỉ lưu metadata sau khi dịch vụ trả thành công. Người dùng tải lại qua Media API với UID hợp lệ.

## 4. Kết quả và bằng chứng

| Mục | Kết quả quan sát |
|---|---|
| Flutter | 124 unit/widget tests pass. |
| FCM | Đã gửi và nhận trên emulator ở ba trạng thái, cold deep link mở PRM323. Script server mới gọi HTTP v1 validate_only thành công. |
| Crashlytics | Native test crash và non-fatal đã có trong dashboard. API của web admin trả báo cáo thật và chặn truy cập chưa xác thực. |
| Remote Config | App hiển thị 31 rồi 30 phút trên cùng APK, đọc lại 30 phút sau khi mở emulator. |
| PDF, tệp đính kèm và Gemini | Pixel 7 giả lập đã mở báo cáo từ lịch sử. Cloudinary trả 404 cho đúng tệp thử sau khi gỡ và Firestore giữ ghi chú. Gemini thật trả lời đúng PRM323 có 3 tín chỉ. |
| Analytics | DebugView xác nhận tám loại event trong lượt ngày 07/11. Log SDK đối chiếu `export_report` có `status=success`. Lượt trước đã thấy `export_report_local` và `course_count=4`. |
| ARTEMIS | TC_11 pass 3/3 lượt ngày 07/11, trung bình 31,66 giây theo pytest. Xem mục lục minh chứng để theo dõi batch. |
| AI review | Review local trên baseline `b69dc71` bổ sung năm findings. Ba sửa lỗi đã tách theo nhóm file và qua kiểm thử. PR và hash commit còn chờ. |

Xem [mục lục bằng chứng](../evidence/README.md), [DebugView](../evidence/firebase/analytics/debugview-2026-11-07.json) và [hướng dẫn demo](../docs/lab3-oral-defense.md).

## 5. Quyền truy cập và dữ liệu

Firestore chỉ cho owner dùng dữ liệu cá nhân theo UID. Hosted domain của Google Sign-In và kiểm tra email trong app là hai phần của luồng đăng nhập. Kiểm tra domain trên thiết bị và cách ly giữa hai tài khoản demo cần thu riêng. Media API xác minh chữ ký ID token và từ chối UID khác. Đường dẫn báo cáo chỉ nhận PDF tối đa 10 MiB. Đường dẫn ghi chú nhận tệp thuộc danh sách định dạng được hỗ trợ và nhỏ hơn 10 MiB. Cloudinary key, OAuth token và mật khẩu web lưu ngoài source. Dữ liệu cá nhân và key cần ẩn khỏi hình chụp.

## 6. Kiểm thử trên máy thật và bàn giao

Chọn serial máy thật qua ADB. Dùng app cùng project, tài khoản FPT demo và APK có SHA phù hợp. Thu kết quả crash trước/sau trên web admin, ba trạng thái FCM, upload/tải lại Cloudinary, Analytics DebugView và batch ARTEMIS. Chốt MSSV và đổi tên file khi xuất bản nộp. Slide để sau theo yêu cầu. Video quay khi có thiết bị thật.
