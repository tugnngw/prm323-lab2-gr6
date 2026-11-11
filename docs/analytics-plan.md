# Kế hoạch Analytics — StudyPilot (GR6)

Mục tiêu: chứng minh **≥ 7 custom event** theo Lab 3 và bộ event AI theo Final Assignment, đồng thời trả lời được câu hỏi sản phẩm. Tài liệu này khớp 1-1 với `lib/services/analytics_service.dart` (15 helper) và các call site thực tế.

## 1. Nguyên tắc

1. **Một cửa ghi**: mọi event đi qua `AnalyticsService.logEvent`; helper có tên chỉ gọi lại hàm này. Không có `FirebaseAnalytics` nào bị gọi trực tiếp từ View/ViewModel.
2. **Không PII**: `FirebaseAnalyticsService._sanitizeParameters` loại bỏ `email`, `user_email`, `name`, `user_name`, `full_name`, `student_name`, `phone`, `phone_number`, `address`. Body thông báo, nội dung ghi chú, token FCM và điểm mô phỏng **không bao giờ** vào tham số.
3. **Không fire trong `build()`**: `course_view` và `prerequisite_check` chỉ fire trong `initState`/hành động người dùng, đúng một lần cho mỗi lần mở.
4. **Đơn vị số nguyên**: kích thước `KB`, thời lượng `ms`, boolean mã hoá `0/1` — hạn chế cardinality và tránh log chuỗi tự do.
5. **Analytics lỗi không làm hỏng tính năng**: mọi call site bọc `try/catch` hoặc `unawaited`, ví dụ PDF vẫn được tạo dù ghi event thất bại.

## 2. Danh sách event

### 2.1 Event Lab 3

| # | Event | Trigger | Parameters | Câu hỏi sản phẩm |
|---|---|---|---|---|
| 1 | `login_success` | Google sign-in thành công | `method` (string) | Bao nhiêu người quay lại mỗi tuần? |
| 2 | `logout` | Người dùng chủ động đăng xuất | — | Tần suất kết thúc phiên? |
| 3 | `course_view` | Mở chi tiết môn (một lần/lần mở) | `course_id`, `code` (string) | Môn nào được xem nhiều sau tìm kiếm? |
| 4 | `prerequisite_check` | Người dùng bấm kiểm tra tiên quyết | `course_id` (string), `is_eligible` (0/1) | Môn nào hay bị kiểm tra điều kiện? |
| 5 | `search_course` | Chốt một truy vấn tìm môn | `query_length` (int) | Truy vấn ngắn hay dài? |
| 6 | `task_create` | Task lưu thành công | `category` (string) | Nhóm việc nào được tạo nhiều? |
| 7 | `task_complete` | Task chuyển sang hoàn thành | `task_id` (string) | Mỗi tuần hoàn thành bao nhiêu việc? |
| 8 | `note_create` | Ghi chú lưu thành công | `content_length` (int) | Mức độ ghi chú mỗi tuần? |
| 9 | `advisor_query` | Gửi câu hỏi cho Advisor | `topic` (id mức học vụ) | Chủ đề tư vấn phổ biến? |
| 10 | `sync_triggered` | Đồng bộ thủ công hoàn tất | `trigger_type` (string) | Tần suất đồng bộ? |

### 2.2 Event mở rộng (PDF, push, strategy)

| # | Event | Trigger | Parameters | Câu hỏi sản phẩm |
|---|---|---|---|---|
| 11 | `export_report_local` | Tạo PDF cục bộ sau khi người dùng đồng ý | `file_size_kb`, `course_count`, `task_count`, `note_count` (int) | Có bao nhiêu báo cáo được tạo? (không hàm ý đã upload) |
| 12 | `export_report` | Xuất PDF lên kho lưu thành công/thất bại | `status` (`success`/`failed`), `file_size_kb`, `duration_ms` (int) | Tỉ lệ xuất thành công? |
| 13 | `notification_received` | Push được xử lý (banner foreground hoặc tap) | `type`, `action` (`foreground`/`tap`) — không có nội dung | Push có kéo người dùng quay lại? |
| 14 | `strategy_view` | Mở Strategy Simulator | `source` (`advisor`/`direct`) | Người xem tư vấn có chuyển sang mô phỏng? |
| 15 | `strategy_preset_applied` | Áp dụng kịch bản mẫu | `preset` (slug) | Kịch bản nào được dùng? (điểm mô phỏng không log — PII) |

### 2.3 Event AI (Final Assignment §8)

| # | Event | Trigger | Parameters | Câu hỏi sản phẩm |
|---|---|---|---|---|
| 16 | `ai_request` | Bắt đầu gọi AI (Advisor, Study Plan, Hỏi tài liệu) | `feature` (`advisor`/`study_plan`/`document`), `model` (tùy chọn, chỉ khi có) | Tính năng AI nào được dùng, model nào? |
| 17 | `ai_result_accepted` | Người dùng chấp nhận/lưu kết quả AI | `feature` (string) | Tỉ lệ kết quả AI được chấp nhận? |
| 18 | `ai_error` | Lỗi/timeout/quota/model xử lý được | `feature`, `error_type` (string) | Lỗi AI nào phổ biến để cải thiện fallback? |

> Ghi chú: `ai_request`/`ai_error` trong lần chạy Study Plan hiện gọi qua `logEvent` trực tiếp; Advisor dùng helper có tham số `feature`. Cả hai đều funnel qua `logEvent` và chịu bộ lọc PII.

## 3. Ánh xạ luồng người dùng

| Luồng | Event | Chỉ số |
|---|---|---|
| Đăng nhập | `login_success`, `logout` | Người dùng hoạt động tuần, độ dài phiên |
| Tìm & xem môn | `search_course`, `course_view`, `prerequisite_check` | Chủ đề phổ biến, mức độ quan tâm tiên quyết |
| Kế hoạch học tập | `task_create`, `task_complete`, `note_create` | Mức độ gắn kết |
| Cố vấn & mô phỏng | `advisor_query`, `strategy_view`, `strategy_preset_applied` | Chuyển đổi từ tư vấn sang lập kế hoạch |
| AI | `ai_request`, `ai_result_accepted`, `ai_error` | Tỉ lệ chấp nhận và lỗi |
| Xuất báo cáo | `export_report_local`, `export_report` | Tỉ lệ tạo/xuất thành công |
| Đồng bộ & push | `sync_triggered`, `notification_received` | Độ tin cậy cloud, hiệu quả push |

## 4. DebugView — quy trình kiểm chứng thủ công

1. Cài **debug APK** cấu hình đúng Firebase; đăng nhập bằng tài khoản Google test chuyên dụng.
2. Bật DebugView cho thiết bị:
   ```bash
   adb shell setprop debug.firebase.analytics.app com.example.prm323_lab3
   ```
   (firebase_analytics 13.x không còn `enableDebugMode()`.)
3. Thực hiện từng trigger ở mục 2, mỗi event một lần.
4. Trong Firebase Console → Analytics → DebugView, xác nhận **tên event + tham số**.
5. Xoay/rebuild màn hình không thao tác; xác nhận `course_view`/`prerequisite_check` **không** nhân đôi.
6. Lưu ảnh chụp vào `evidence/firebase/analytics/` (không lộ email/tên tài khoản).

## 5. Trạng thái bằng chứng

- **Đã xác minh trên DebugView**: `export_report_local` (Pixel_7_API_35) với `course_count=4`, `file_size_kb=21`; ngày 07/11/2026 quan sát được 8 loại event theo kế hoạch, gồm `export_report` (`status=success`, `duration_ms=2648`) và `note_create`. Ảnh/log: `evidence/firebase/analytics/`, JSON: `debugview-2026-11-07.json`.
- **Chưa xác minh đầy đủ**: toàn bộ 18 event, đặc biệt nhóm AI (`ai_request`, `ai_result_accepted`, `ai_error`) và `login_success`/`logout` trên phiên đăng nhập mới. Khi chạy lại, cập nhật mục này bằng bằng chứng thật; **không** ghi nhận kết quả chưa quan sát.
- Kiểm thử mã nguồn (`flutter test`) chỉ chứng minh call wiring, không chứng minh phân phối tới Firebase Console.
