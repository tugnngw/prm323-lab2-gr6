# Engagement & Academic UX (2026-11)

## Understanding Lock

Người dùng đã xác nhận 6 quyết định:

1. **Chọn lại ngành**: nút trong Hồ sơ học tập, xóa `major` để gate onboarding mở lại. Đổi ngành bình thường vẫn ở tab Lộ trình.
2. **Cố vấn**: luôn trả lời lớp local (tính trên dữ liệu máy); Gemini là lớp bổ sung khi cấu hình Firebase AI Logic/App Check hoạt động. Lỗi AI phải nêu lý do thật và vẫn hiển thị câu trả lời local.
3. **Nhắc việc**: badge/banner/số ngày còn lại trong app + local notification khi app đóng.
4. **Tiến độ slot & giảng viên**: lưu riêng từng sinh viên dưới `users/{uid}`, không sửa catalog dùng chung.
5. **Mô phỏng GPA**: giữ màn hình, giải thích rõ là sandbox what-if không lưu, làm rõ mốc 8.0.
6. **Thời khóa biểu**: đã bỏ (2026-11-10). App chỉ hiển thị lịch theo slot trong đề cương FLM; xem `docs/design/advisor-offline-and-ai.md`.

## Data model

### `users/{uid}/courseProgress/{courseDocId}`

```
completedSlotNumbers: [int]   // số slot đã học xong
courseCompleted: bool         // đánh dấu "đã xong môn"
lecturer: string              // giảng viên sinh viên tự ghi
room?: string
updatedAt: serverTimestamp
```

Chỉ chủ sở hữu đọc/ghi. Catalog `courses/{id}.completedSlots` vẫn là dữ liệu chung, không bị ghi đè.

### Thời khóa biểu — đã xóa

`TimetableEntry`, `AcademicProfile.timetable`, tab "Thời khóa biểu", nhắc lớp học và
phần đối chiếu trùng lịch đã được gỡ khỏi model, viewmodel, màn hình và test.
Dữ liệu `users/{uid}.timetable[]` cũ (nếu có) bị bỏ qua khi đọc hồ sơ; app không
còn ghi trường này.

### Bí kíp cộng đồng

`experience_notes/{id}` thêm `title` (3–120 ký tự). Form gửi chỉ còn **tên bí kíp + nội dung**; các trường `lecturerTip`, `examTip`, `rating` của bản cũ vẫn đọc được nhưng không còn nhập mới.

`tip_ratings/{tipId}__{uid}` — mỗi người một đánh giá cho mỗi bí kíp:

```
tipId, courseDocId, uid, stars (1–5), displayName, createdAt
```

`tip_comments/{commentId}` — bình luận không kiểm duyệt:

```
tipId, courseDocId, courseCode, uid, authorName, content (1–1000), createdAt
```

Điểm trung bình/số lượt đánh giá được tính client-side từ `tip_ratings` (không cần Cloud Functions).

### Thông báo

- Bell đọc `users/{uid}/notifications` **hợp nhất**:
  - announcements toàn server (`announcements`),
  - deadline sắp tới (task chưa xong, hạn trong 3 ngày hoặc quá hạn),
  - thông báo đánh giá bí kíp do người khác ghi vào `users/{authorUid}/notifications`.
- Đã đọc announcement lưu ở `users/{uid}.readAnnouncementIds`.
- Local notification: nhắc lớp học (trước giờ bắt đầu 15 phút, lặp tuần) và nhắc task (09:00 ngày đến hạn / trước 3 ngày), dùng `flutter_local_notifications` + timezone `Asia/Ho_Chi_Minh`.

## UX changes

- **Onboarding**: Hồ sơ → "Chọn lại ngành" (xác nhận) → xóa major → gate mở lại.
- **Lộ trình / chi tiết môn**:
  - mỗi slot có nút "Đã học xong slot này" / hoàn tác;
  - "Đã xong môn" đánh dấu toàn bộ slot; "Đặt lại" xóa tiến độ môn;
  - tiến độ hiển thị theo dữ liệu cá nhân;
  - nhập/sửa giảng viên cá nhân, hiển thị ở header + roadmap;
  - app bar có thêm nút tạo ghi chú và thêm việc cần làm cho môn.
  - tab Slots có thẻ "Hôm nay" và danh sách lịch cá nhân kèm giờ/phòng.
- **Tiên quyết**: nêu rõ điều kiện dựa trên **điểm ≥ 5 trong bảng điểm**, không dựa trên slot. Mỗi môn tiên quyết chưa đạt có nút "Nhập điểm" nhanh; nút này ghi transcript rồi refresh roadmap.
- **Việc cần làm**: chọn ngành → tìm/chọn môn; chọn ngày bằng date picker; nút "Đánh dấu đã xong"/"Làm lại" rõ ràng; chip số ngày còn lại; banner việc đến hạn ≤ 3 ngày; hoàn tác 4 giây.
- **Ghi chú**: bỏ nhập syllabus FLM; chọn ngành + tìm môn khi soạn; bỏ mặc định PRM323; nhận đúng mã môn từ màn hình môn học.
- **Cố vấn**: thẻ giới thiệu chức năng; badge cho biết đang dùng AI hay dữ liệu máy; lỗi Gemini có giải thích + fallback local.
- **Mô phỏng GPA**: banner "what-if, không lưu", giải thích mốc 8.0; bỏ số liệu trùng lặp ở Cố vấn.
- **Bí kíp**: form tên + nội dung; sao đánh giá của người khác (1 lượt/người); bình luận thu gọn; trạng thái duyệt + lý do từ chối; màn "Bí kíp của tôi"; thông báo khi có người đánh giá; sửa tràn chữ.
- **Thông báo**: hợp nhất announcement + deadline + notification; badge chuông cập nhật realtime với announcement.

## Phases

A. Models + service + Firestore rules/indexes + fakes.
B. ViewModels: roadmap progress/lecturer, academic reset/quick grade, tasks due-date, notifications merge.
C. Screens: onboarding reset, academic tabs, course detail, roadmap, tasks, notes/editor, home.
D. Advisor/strategy/tips + admin-web + local notifications.
E. Tests, analyze, APK.

## Local notifications (implementation)

- Plugin: `flutter_local_notifications` **22.3.3** (compileSdk 36; bản 23 đòi compileSdk 37 mà SDK hiện tại chỉ có `android-37.0` nên Gradle không resolve được) + `timezone`, `Asia/Ho_Chi_Minh`.
- `lib/services/local_notification_service.dart`: tạo channel `study_reminders`, xin quyền `POST_NOTIFICATIONS`/iOS một lần mỗi phiên, `syncReminders()` hủy toàn bộ lịch cũ rồi lập lịch mới:
  - lớp: thứ + `startTime` do sinh viên nhập, nhắc trước 15 phút, lặp hằng tuần (`dayOfWeekAndTime`); bỏ qua lớp chưa nhập giờ.
  - task: 09:00 trước hạn 3 ngày và 09:00 ngày đến hạn; bỏ qua task đã xong/không có ngày; tối đa 40 lời nhắc.
  - dùng `inexactAllowWhileIdle` để không cần quyền exact-alarm.
- `lib/widgets/reminder_sync.dart` bọc `AuthGate`: so dấu vân tay (giờ lớp + task) và đồng bộ debounce 800 ms; uid null (đăng xuất/mở app chưa đăng nhập) thì `clearAll()` để không lộ lịch của người trước. Chạm thông báo mở `/course-detail` (payload `class|<mã môn>`) hoặc `/tasks`.
- Android: bật core-library desugaring (`desugar_jdk_libs` 2.1.4), thêm `RECEIVE_BOOT_COMPLETED` + 2 receiver của plugin để lịch vẫn chạy sau reboot/cập nhật app.
- Trong app: thẻ deadline 3 ngày, badge số việc đến hạn trên tab "Việc cần làm" và trong Trung tâm thông báo.

## Fix pass — phản hồi sau khi cài APK

- **Toast tự tắt**: thay `SnackBar` + `SnackBarAction` bằng `lib/widgets/app_toast.dart` (Overlay + `Timer` 5 giây). SnackBar có action bị OS giữ mãi khi bật accessibility timeout; toast tự gỡ khỏi Overlay nên luôn tắt sau 5 giây. Dùng cho task, "Đã xong môn", slot, giảng viên; lỗi vẫn là SnackBar đỏ.
- **Đổi nhãn**: "Thông báo từ nhà trường" → "Thông báo hệ thống" ở AppBar announcement, tooltip, empty state và tiêu đề mục trong Trung tâm thông báo.
- **Ghi tiến độ / giảng viên thất bại**: `RoadmapViewModel.lastError` giờ ghi mã lỗi Firestore thật (`permission-denied`, `unavailable`, …) và màn hình môn hiển thị đúng lỗi đó thay vì câu chung. Nguyên nhân trên máy thử: ruleset đã deploy chưa có block `courseProgress` (rules trong repo đã có). Cần chủ dự án chạy:
  `npx firebase-tools deploy --only firestore:rules --project prm323-lab2-gr6`
  rồi kiểm tra `npx firebase-tools firestore:rules:get --project prm323-lab2-gr6`.
- **Bỏ "Tải tệp lên"** ở màn Ghi chú (nút không mở luồng nào hữu ích).
- **Cố vấn**: lỗi Gemini được map theo mã thật (`ServiceApiNotEnabled`, `InvalidApiKey`, `QuotaExceeded`, `ServerException`, `unauthenticated`/`permission-denied` của App Check, timeout) thay cho câu chung. Khung lỗi đổi sang màu cảnh báo + ghi rõ câu trả lời trên thiết bị vẫn dùng được. Cố vấn local bổ sung: tra môn theo mã, tiên quyết, môn học lại, GPA từng kỳ + tích lũy, gợi ý môn đủ điều kiện trong kỳ, bí kíp đã duyệt (danh mục câu hỏi chọn sẵn xem `docs/design/advisor-offline-and-ai.md`).
- **Mô phỏng GPA**: còn đúng 2 chế độ.
  1. **GPA kỳ**: chỉ tính kỳ đang chọn; môn đã có điểm trong bảng điểm tự lấy (read-only), môn chưa có mới được nhập điểm dự kiến.
  2. **GPA tích lũy**: cộng mọi điểm thật trong bảng điểm (mọi kỳ) + điểm dự kiến; cho nhập điểm dự kiến cho kỳ bất kỳ.
  Đã bỏ phần nhập điểm theo kế hoạch cũ, đối chiếu thời khóa biểu và danh sách lịch khỏi màn này.
- **Bỏ thời khóa biểu**: màn Hồ sơ chỉ còn tab Thông tin + Bảng điểm; thông báo chỉ nhắc deadline việc cần làm.
