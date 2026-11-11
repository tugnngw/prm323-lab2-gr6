# Tính năng AI — StudyPilot (GR6)

## 1. Mục tiêu và phạm vi

StudyPilot dùng AI ở ba điểm:

| Tính năng | Đầu vào | Đầu ra | Nơi xử lý |
|---|---|---|---|
| Gợi ý kế hoạch học tập | Kỳ học 1–12 + ngữ cảnh đề cương các môn trong kỳ | `goal` + 1–4 `actions` | `lib/services/study_plan_ai.dart` |
| Cố vấn học tập | Câu hỏi + ngữ cảnh học vụ đã lọc | Câu trả lời có nguồn | `lib/viewmodels/advisor_viewmodel.dart` + `AiService` |
| Hỏi tài liệu | Câu hỏi + PDF/ảnh đính kèm | Câu trả lời từ tài liệu | `lib/services/ai_service.dart` (`askDocument`) |

Model mặc định `gemini-3.5-flash-lite`, đổi được qua Remote Config (`ai_advisor_model`, `study_plan_ai_model`). Firebase AI Logic chịu trách nhiệm gọi Gemini phía client; App Check bảo vệ endpoint.

## 2. Kiểm soát chất lượng và an toàn

- **Schema cứng**: `StudyPlanDraft.fromJson` từ chối JSON sai kiểu, `goal` rỗng/>120 ký tự, `actions` rỗng/>4 phần tử, mỗi action >100 ký tự.
- **Nhãn AI**: kết quả hiển thị trong card "Bản nháp do AI tạo"; người dùng bấm **Dùng** mới điền vào ô soạn thảo và vẫn phải **Gửi để duyệt**.
- **Zero-PII**: prompt chỉ chứa mã môn, tên môn, tín chỉ, số slot, giảng viên nếu có; không gửi tên/email/điểm/ảnh cá nhân.
- **Zero-Hallucination**: prompt yêu cầu bám đề cương, không bịa; nếu thiếu dữ liệu thì đưa phương pháp học chuẩn.
- **Remote Config**: cờ bật/tắt (`study_plan_ai_enabled` mặc định **tắt**, `feature_ai_advisor_enabled` mặc định bật), model và prompt đổi không cần phát hành app.
- **App Check**: Android dùng debug token ghim cho bản demo; production cần Play Integrity.
- **Fallback**: lỗi mạng/quota/model → hiện thông điệp tiếng Việt, form nhập tay vẫn hoạt động; Analytics ghi `ai_error`.

## 3. Ba input/output thật

Nguồn: `evidence/ai/study-plan-2026-11-10-valid.json`. Ba lượt gọi Gemini Developer API bằng **cùng model `gemini-3.5-flash-lite`** và cùng khuôn prompt/system instruction như `study_plan_ai.dart`, với ràng buộc độ dài rõ ràng. Đây là kiểm chứng **model-level**, không phải ảnh UI: thiết bị demo đang khoá nên chưa thể chạy E2E trong app.

### Input 1 — Kỳ 3

> Kỳ học: 3. Ngữ cảnh: PRF192 (Lập trình C, 3 tín chỉ, 30 slots); MAE101 (Toán cho kỹ thuật, 3 tín chỉ, 30 slots); CEA201 (Cơ sở điện toán, 3 tín chỉ, 30 slots).

**Output thật** (đã qua kiểm tra schema của app):

```json
{
  "goal": "Hoàn thành xuất sắc 3 môn PRF192, MAE101 và CEA201 trong kỳ học này.",
  "actions": [
    "Lập lịch ôn tập code C hàng ngày cho môn PRF192.",
    "Luyện tập các dạng bài tập toán kỹ thuật cho môn MAE101.",
    "Nghiên cứu kỹ kiến trúc máy tính và phần cứng cho môn CEA201."
  ]
}
```

### Input 2 — Kỳ 5

> Kỳ học: 5. Ngữ cảnh: PRJ301 (Java Web, 3 tín chỉ, 30 slots, có PE); SWE201c (Kỹ thuật phần mềm, 3 tín chỉ, 30 slots); DBI202 (Cơ sở dữ liệu, 3 tín chỉ, 30 slots).

**Output thật**:

```json
{
  "goal": "Hoàn thành xuất sắc học kỳ 5 với ba môn trọng tâm gồm PRJ301, SWE201c và DBI202.",
  "actions": [
    "Lên lịch ôn tập cơ sở dữ liệu DBI202 và chuẩn bị cho bài kiểm tra thực hành PE của PRJ301.",
    "Tham gia đầy đủ các buổi học kỹ thuật phần mềm SWE201c và làm bài tập nhóm đúng hạn.",
    "Thực hành code Java Web thường xuyên để đạt kết quả cao trong môn PRJ301."
  ]
}
```

### Input 3 — Kỳ 8

> Kỳ học: 8. Ngữ cảnh: PRM393 (Lập trình di động, 3 tín chỉ, 30 slots, có PE); SWD392 (Kiến trúc phần mềm, 3 tín chỉ, 30 slots); PRU213 (Xác suất thống kê, 3 tín chỉ, 30 slots).

**Output thật**:

```json
{
  "goal": "Hoàn thành xuất sắc học kỳ 8 với các môn chuyên ngành và xác suất thống kê",
  "actions": [
    "Lập lịch ôn tập PE và bài tập cho môn PRM393",
    "Nghiên cứu tài liệu kiến trúc phần mềm cho SWD392",
    "Giải các dạng bài tập xác suất thống kê của PRU213"
  ]
}
```

Cả ba output đều qua `StudyPlanDraft.fromJson` (kiểm tra kiểu, độ dài, số action) và hiển thị được dưới nhãn AI, người dùng có thể sửa trước khi gửi duyệt.

## 4. Failure case thật

### 4.1 Model trả JSON lặp vô hạn

Lượt gọi đầu tiên (cùng prompt nhưng **không** đặt giới hạn độ dài chặt) trả về `goal` dài hàng nghìn ký tự, lặp câu "Chúc bạn học thật tốt..." và không có `actions` đúng schema. App sẽ ném `FormatException('Invalid study plan fields')`, hiện thông điệp fallback và cho nhập tay. Raw output lưu tại `evidence/ai/study-plan-2026-11-10.json` (case kỳ 3).

**Bài học**: schema của Gemini API không thay thế kiểm tra phía app; `StudyPlanDraft.fromJson` là hàng rào bắt buộc. Prompt cần nêu rõ giới hạn ký tự/số action thay vì chỉ dựa vào `responseSchema`.

### 4.2 Model quá tải (HTTP 503)

Hai lượt kỳ 5 và kỳ 8 nhận `503 UNAVAILABLE: This model is currently experiencing high demand`. App map lỗi này thành thông điệp "AI chưa khả dụng. Bạn vẫn có thể nhập kế hoạch trực tiếp." và ghi `ai_error`; không treo spinner, không tạo dữ liệu giả. Lượt chạy lại sau đó thành công (mục 3).

## 5. Cấu hình và cách chạy

- Remote Config: `study_plan_ai_enabled=true`, `study_plan_ai_model=gemini-3.5-flash-lite`, `study_plan_ai_prompt` (xem `firebase/remote-config-template.json`).
- App Check: đăng ký debug token của thiết bị demo trong Firebase Console trước khi bật enforcement.
- Chạy app: đăng nhập tài khoản test → **Duyệt kế hoạch học tập** → chọn kỳ → **Gợi ý bằng AI** → **Dùng** → **Gửi để duyệt**.
- Kiểm tra Analytics: `ai_request`, `ai_result_accepted`, `ai_error` trong DebugView.

## 6. Giới hạn đã biết

- Chưa có ảnh UI ba lượt AI trong app vì thiết bị demo đang khoá; bằng chứng hiện tại là model-level với đúng model/prompt.
- `study_plan_screen` ghi `ai_request`/`ai_error` qua `logEvent` thô, chưa có `feature`; xem CR-28 trong `code-review.md`.
- Chưa có quota/rate limit phía server cho endpoint AI dùng chung; demo chạy loopback và tài khoản test.
