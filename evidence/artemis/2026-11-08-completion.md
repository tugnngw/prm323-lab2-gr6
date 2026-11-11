# ARTEMIS trên Pixel 7 — 08/11/2026

## Kết quả pytest E2E

Đạt mốc 10 ca khác nhau, mỗi ca có ít nhất 3 lượt pass trên Pixel 7 API 35 giả lập. Chín ca trước được ghi trong [lượt Flash-Lite 07/11](2026-11-07-flash-lite.md) và [regression 07/11](2026-11-07-regression.md). Một lượt timeout TC_02 vẫn được giữ trong lịch sử.

TC_13 xác minh SDK đăng ký token qua log `Registered FCM token` sau cold start. Pytest trả `3 passed in 57.51s`.

| Lượt | Trace | Kết quả |
| --- | --- | --- |
| 1 | `a23c7a10-5e4f-4d87-9adc-60732ce39c09` | Pass |
| 2 | `034ff4e6-2153-4571-bbce-a735ecfff491` | Pass |
| 3 | `4b13c8b5-68b0-4df6-aaaa-70865aa82a71` | Pass |

TC_14 Analytics dừng ở trace `da4a9901-e55c-4a56-97d2-2b9274934fdc` sau nhiều lần Gemini trả HTTP 429 do chạm giới hạn theo phút của Flash-Lite. Lượt này chưa pass. [Firebase DebugView](../firebase/analytics/debugview-2026-11-07.json) xác nhận riêng 8 loại sự kiện.

Thời gian ARTEMIS trung bình riêng TC_13 là 13,59 giây/lượt. Tổng thời gian pytest gồm chuẩn bị thiết bị và kiểm tra log.

## Exploratory với ARTEMIS Pro

Lượt đầu `c9ba73e3-cba2-45ca-80b9-03f1a5a859f1` đi qua 10 luồng. Checker xác nhận khoảng 9 phút thao tác và đánh dấu chưa đạt ngưỡng 15 phút. Không tính lượt này đạt rubric.

Lượt hai `c60b3464-271b-4cbf-a106-600789510380` xác minh thêm chi tiết nhiều môn, bộ lọc công việc, Ghi chú, Hồ sơ học tập, Cố vấn, Chiến lược và điều hướng từ thông báo. Trace có 28 bước. Tiến trình dừng thêm bước sau khoảng 7 phút rưỡi và log daemon có HTTP 429. Đã hủy lượt chạy; thời gian chờ không tính vào 15 phút khám phá. Mục exploratory theo rubric còn mở.

APK debug dùng cho các lượt kiểm tra nằm tại `build/app/outputs/flutter-apk/app-debug.apk`. Lượt này thay đổi prompt TC_13 và cập nhật evidence. Điện thoại thật do người dùng kiểm tra sau. Cloudinary và Gemini trên APK này cần Media API và ADB reverse như trong [hướng dẫn admin-web](../../admin-web/README.md).
