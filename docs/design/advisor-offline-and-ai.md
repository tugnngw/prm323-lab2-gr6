# Cố vấn học tập: trạng thái AI, hỏi local có chọn lựa, bỏ lịch học

## 1. Vấn đề

- Cố vấn hiện báo `Gemini báo lỗi unknown.` dù AI Logic đã bật.
- Khi AI lỗi/offline, người dùng chỉ thấy một đoạn văn dài, không biết
  trên thiết bị hỏi được gì, cũng không chọn được câu hỏi local.
- Thời khóa biểu cá nhân (tự nhập thứ/slot/giờ/phòng) không mang lại giá trị
  so với lịch slot của đề cương, lại kéo theo nhắc lịch, trùng lịch, tab nhập
  liệu và một loạt test.

## 2. Nguyên nhân lỗi "unknown"

Log thật trên máy ảo:

```
[Advisor] askQuestion failed: FirebaseException:
[firebase_app_check/unknown] -14: Integrity API error (-14):
The Play Store needs to be updated.
```

Chuỗi này không phải lỗi Gemini. Nó là App Check:

1. APK release chọn `AndroidPlayIntegrityProvider` (`lib/main.dart`).
2. APK cài tay/emulator không có Play Integrity hợp lệ (Play Store trên emulator
   quá cũ hoặc bản build không được Play Store chứng thực).
3. `firebase_app_check` trả code `unknown`, message `-14`.
4. `describeAskFailure` (nay là `describeAiFailure` trong
   `lib/utils/ai_failure_messages.dart`) chỉ map các code quen
   (`unauthenticated`, `permission-denied`, ...), nên rơi vào nhánh mặc định
   `Gemini báo lỗi unknown.`.

## 3. Cách xử lý

### 3.1 Chẩn đoán đúng

- Map `firebase_app_check` + `unknown` + `-14` thành thông điệp riêng, nêu rõ
  Play Integrity và cách khắc phục. Cùng hàm này được màn "Hỏi AI về ghi chú"
  dùng lại để không còn câu lỗi chung chung.
- Một nguồn model duy nhất: `gemini-3.5-flash-lite` cho cố vấn, kế hoạch học tập,
  hỏi ghi chú và admin-web. Lý do thực đo trên dự án:
  `gemini-2.5-flash` bị API trả "no longer available to new users";
  `gemini-3.8-flash` chạy nhưng vượt quá 45 giây với prompt đề cương 10k ký tự
  (kể cả khi hạ thinking), còn `gemini-3.5-flash-lite` trả lời trong ~9 giây.
- Lưu `lastRawError` và hiển thị trong mục "Chẩn đoán" của trợ giúp.
- Sau một lần AI lỗi, chuyển `AiStatus.unavailable`; các câu hỏi tiếp theo
  không gọi Gemini nữa (tránh chờ hết thời gian timeout) cho đến khi người dùng
  bấm "Thử lại AI".

### 3.2 App Check cho bản cài tay

Thêm cờ build `APP_CHECK_DEBUG`:

```
flutter build apk --release --dart-define=APP_CHECK_DEBUG=true
```

- `true` → dùng `AndroidDebugProvider` / `AppleDebugProvider` kể cả ở release.
- Token debug được **cố định trong code** (`AppCheckService._debugToken`) và đã
  đăng ký sẵn ở Firebase Console → App Check → Apps → Manage debug tokens.
  Nhờ vậy rebuild, cài lại, gỡ app hay đổi giữa bản debug và release đều dùng
  cùng một token — không cần thêm token mới trên Console.
- App chỉ hiển thị "token OK" trong Chẩn đoán sau khi trao đổi thành công,
  không hiển thị token.
- Bản phát hành thật vẫn dùng Play Integrity / App Attest (mặc định). Lưu ý
  APK cài tay trên máy thật cũng không qua Play Integrity, nên bản demo dùng
  debug provider là đúng; chỉ bỏ cờ này khi phát hành qua Play Store.

Nếu không muốn dùng debug provider: cập nhật Play Store trên thiết bị, hoặc
chạy trên máy thật có Play Services hợp lệ.

### 3.3 Hỏi local có chọn lựa

Thêm `LocalQuestionKind` (mã, nhãn, mô tả, cấp tư vấn, cần môn/kỳ). UI mở
bottom sheet chia nhóm, có dropdown chọn môn/kỳ. Mỗi câu trả lời local là
Markdown có cấu trúc, gắn nhãn nguồn "Trên thiết bị".

Danh mục local:

| Nhóm | Câu hỏi | Dữ liệu dùng |
| --- | --- | --- |
| Môn học | Tóm tắt môn | tín chỉ, kỳ, GV, tiên quyết, số slot, đầu điểm, CLO |
| Môn học | Đầu điểm & trọng số | `CourseLab` (weight, duration, criteria) |
| Môn học | Nội dung từng slot | `CourseSlot` (topic, materials, tasks) |
| Môn học | Tiên quyết của môn | `missingPrerequisites` + bảng điểm |
| Môn học | Điểm & điểm thành phần | transcript + `componentScores` |
| Môn học | Bí kíp đã duyệt | `ExperienceNote` đã duyệt |
| Môn học | Chiến lược ôn thi | đầu điểm trọng số cao + slot có task |
| Kỳ học | Tổng quan kỳ | số môn, tín chỉ, môn đủ/thiếu tiên quyết |
| Chương trình | Môn vướng tiên quyết | toàn bộ danh mục |
| Chương trình | Môn cần học lại | transcript `passed = false` |
| Chương trình | Môn có thể đăng ký | đủ tiên quyết, chưa qua |
| Điểm số | GPA từng kỳ + tích lũy | transcript |
| Điểm số | Tín chỉ đã qua | transcript |

Câu hỏi gõ tay vẫn đi qua bộ định tuyến từ khóa cũ (đã bỏ nhánh lịch học).
Nếu câu hỏi chứa mã môn không có trong danh mục ngành (regex `[A-Z]{2,4}\d{3,4}`),
app trả lời thẳng "Chưa thấy môn ..." thay vì tóm tắt một môn khác.

### 3.4 Giao diện

- Banner trạng thái AI ngay dưới AppBar:
  - `đang kiểm tra` / `sẵn sàng` / `không hoạt động` + lý do ngắn.
  - Nút "Thử lại AI" khi unavailable.
- Bỏ dải lỗi lặp ở đáy màn hình; lỗi nằm trong bong bóng trả lời với nút
  "Thử lại câu này".
- Tin nhắn AI render Markdown (`MarkdownBody`), có badge nguồn:
  `Gemini + thiết bị`, `Trên thiết bị`, `Không kết nối AI`.
- Nút "Hỏi nhanh trên thiết bị" thay 3 chip hardcode.
- Trợ giúp viết lại: AI làm gì, local làm gì, vì sao AI lỗi, cách sửa App Check.

### 3.5 Bỏ thời khóa biểu

Xóa toàn bộ `TimetableEntry`, `AcademicProfile.timetable`, tab "Thời khóa biểu",
card "Hôm nay học gì", mục lịch cá nhân trong chi tiết môn, nhắc lịch lớp, và
nhánh lịch trong cố vấn. Giữ nguyên lịch slot của đề cương (dữ liệu FLM) và
nhắc deadline công việc.

## 4. Kiểm thử

- `describeAiFailure` với `FirebaseException(firebase_app_check, unknown,
  -14)` phải chứa "Play Integrity" và "-14".
- AI unavailable: câu hỏi thứ hai không gọi Gemini, vẫn trả lời local.
- `askLocalPrompt` trả Markdown đúng dữ liệu cho từng kind.
- Không còn tham chiếu timetable trong model/VM/màn hình/test.
- `flutter analyze`, `flutter test`, parser/admin tests, build APK.
