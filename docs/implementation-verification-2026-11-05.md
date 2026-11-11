# Tiếp tục ngày 05/11/2026

Người dùng quyết định giữ Firebase Spark. Không nâng Blaze, không liên kết thẻ, không tạo bucket tính phí. Giữ nhánh upload sẵn có nhưng chưa coi upload/metadata/download cloud là hoàn thành. Dùng PDF cục bộ và Android share sheet đã xác minh ngày 04/11; đây không thay thế yêu cầu Storage trong rubric.

Giữ nguyên branch và toàn bộ thay đổi chưa commit. Mốc kiểm tra app gần nhất: 114 Flutter tests, analyzer sạch, APK build/cài; FCM ba trạng thái/cold deep link, RC 31→30 cùng APK, dashboard Crashlytics và DebugView export_report_local đã có evidence. Tiếp tục từ trạng thái này, không tạo lại dự án.

Công cụ Windows ban đầu không thấy emulator trong danh sách cửa sổ; ADB cũng không có device. Đã gọi ARTEMIS diagnose và launch đúng AVD Pixel_7_API_35_Google_Play theo lựa chọn trước của người dùng; không wipe data.

Sau khi host khởi động lại, ADB mất thiết bị. Khởi chạy lại đúng AVD và xác nhận app vẫn mở với phiên đã lưu. Kiểm tra nhẹ bằng ADB và ARTEMIS hierarchy: Sync Vault hiển thị 30 phút, Trung tâm Thông báo đọc được các bản tin đã lưu, mở bản tin liên kết vào PRM323 với Lịch slot, Đánh giá và Tổng quan. [Ảnh và kết quả](../evidence/app/smoke-2026-11-05/verification.json).

Người dùng chọn chỉ kiểm tra nhẹ trong lúc Delta Force chạy. Batch pytest ARTEMIS và exploratory được để lại. Chẩn đoán ARTEMIS xác nhận ADB và key hợp lệ, scrcpy còn thiếu. Lượt này chưa đo lại quota thực thi mô hình. Coverage Analytics đầy đủ và hồ sơ bàn giao cuối còn lại.

## Bổ sung theo yêu cầu giảng viên

- Web admin localhost, Basic Auth, gọi Crashlytics REST từ server bằng Google OAuth. Smoke thật: không có đăng nhập trả 401, dashboard HTML 200, API 200, có 5 nhóm gồm native fatal và demo non-fatal. Chưa xác minh một crash mới từ điện thoại thật.
- FCM có lệnh server trong `admin-web/send-fcm.mjs`. Đọc registration mới nhất từ Firestore và gọi HTTP v1 với OAuth. `validate_only` thành công, lượt này không gửi push. Bằng chứng gửi/nhận ba trạng thái vẫn là lượt 04/11.
- Thêm Cloudinary theo cấu hình tùy chọn `REPORT_MEDIA_URL`. App dùng Firebase ID token đến Media API, server kiểm tra UID, MIME và giới hạn 10 MB trước khi upload private. Metadata Firestore chỉ lưu sau khi có phản hồi thành công. Tải lại PDF qua cùng kiểm tra UID. PDF cục bộ vẫn có trong Sync Vault.
- 114 Flutter tests, analyzer sạch, APK debug cấu hình USB reverse build và cài/mở trên emulator. Consent hiện đúng Cloudinary và số dữ liệu, đã Hủy trước upload. Hai test Node HTTP kiểm tra web auth và hợp đồng media với adapter thử. Chưa dùng credential Cloudinary thật, chưa kiểm chứng asset hoặc metadata thực qua phương án mới.
- ARTEMIS TC_11 pass một lượt trên emulator, tổng thời gian pytest 116.31 giây. Trace `cc6378c0-a0d2-4c0b-8c2a-f728025f6ecc`. Ảnh gốc để ngoài repo vì có phần đầu tài khoản. Kết quả có hierarchy đã ẩn thông tin và terminal report. Batch theo rubric và exploratory còn thiếu.
- Đã cập nhật nội dung báo cáo, kịch bản video trên điện thoại thật và ghi chú trả lời FCM/Crashlytics. User chưa có điện thoại thật và yêu cầu để slide sau. Bản ghi này giữ nguyên trạng thái tại thời điểm kiểm tra; định danh nộp bài sau đó chuyển sang nhóm GR6.

Xem [bằng chứng lượt này](../evidence/README.md), [hướng dẫn triển khai](../admin-web/README.md) và [tài liệu giải thích](lab3-oral-defense.md).
