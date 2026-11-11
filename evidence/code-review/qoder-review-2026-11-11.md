# AI code review — Qoder, 11/11/2026

- **Công cụ:** Qoder (agent trong IDE), không phải reviewer bên ngoài và không phải PR review độc lập.
- **Phạm vi:** working tree của nhánh `main`, so với `HEAD` (`052e975`). 23 tệp, +302/−109 dòng, tập trung vào luồng xuất PDF/Cloudinary, Sync Vault, Home/Tasks và tài liệu Lab 3.
- **Cách làm:** đọc diff, đối chiếu từng điểm sửa với code hiện tại, chạy `flutter analyze` và `flutter test`. Không dùng dữ liệu giả hay kết quả tự sinh.

## 1. Phát hiện mới

| ID | Mức | Vị trí | Nội dung | Quyết định |
|---|---|---|---|---|
| CR-31 | High | `lib/services/report_export_service.dart:187-222` | `saveReportMetadata` được await không có timeout. Firestore chỉ hoàn tất Future khi backend xác nhận; khi DNS/mạng hỏng, UI đứng ở "Đang tải lên… 100%" dù PDF đã lên Cloudinary. | Accepted — bọc `.timeout(12s)`, trả `metadataSynced=false`. |
| CR-31b | Medium | `lib/screens/sync_vault_screen.dart:972-977` | Khi metadata chưa đồng bộ, màn hình không phân biệt với lỗi tải lên và người dùng không biết bản ghi vẫn nằm trong hàng đợi. | Accepted — hiện cảnh báo riêng, giữ kết quả upload thành công. |
| CR-31c | Low | `test/services/report_export_service_test.dart` | Chưa có test cho nhánh Firestore không xác nhận. | Accepted — thêm test dùng `Completer` chưa hoàn tất, timeout 20 ms. |

## 2. Đối chiếu các finding cũ

Đã kiểm tra vị trí code của CR-15…CR-30 trong `docs/code-review.md`; các dòng tham chiếu (ví dụ `lib/services/ai_service.dart:10`, `firebase/firestore.rules:101-102`, `lib/screens/study_plan_screen.dart:55`) tồn tại đúng nội dung đã sửa. Không phát hiện hồi quy mới ngoài CR-31.

## 3. Kiểm chứng

| Lệnh | Kết quả |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 164/164 pass |
| `flutter build apk --debug --dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788` | Thành công, `build/app/outputs/flutter-apk/app-debug.apk` |

## 4. Giới hạn

Không có PR trên GitHub trong thời điểm review (máy không có `gh`, chưa cấu hình token), nên review chạy trên working tree thay vì diff PR. Báo cáo không trình bày đây là review của người ngoài.
