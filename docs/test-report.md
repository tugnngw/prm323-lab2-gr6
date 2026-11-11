# Kiểm thử và review — StudyPilot (GR6)

Cập nhật: 2026-11-10. Chỉ ghi kết quả đã chạy và nơi lưu bằng chứng; kịch bản chưa chạy để trạng thái "Chưa chạy".

## 1. Lệnh tái hiện

```powershell
# Mobile
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release

# Firestore Rules (Emulator, project demo tách khỏi project thật)
cd firebase/tests
npm ci
npx --yes firebase-tools@13.35.1 emulators:exec --only firestore `
  --project demo-second-brain-final "npm test"

# Web (parser + API server)
cd admin-web
node --test
```

## 2. Kết quả tự động (10/11/2026)

| Lệnh | Kết quả | Ghi chú |
|---|---|---|
| `flutter analyze` | **0 issue** | Toàn bộ `lib/`, `packages/`, `test/`, `tool/` |
| `flutter test` | **159/159 pass** | Hermetic, fake service, không cần Firebase |
| `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | **PASS** | `build/app/outputs/flutter-apk/app-release.apk` |
| Rules Emulator | **15/15 pass** | `firebase/tests/final.test.mjs` |
| `node --test` (web) | **14/14 pass** | 9 parser FLM + 5 API server |
| `node --check admin-web/app.js` | **PASS** | Cú pháp ES module |

> **Phạm vi rules:** 15/15 là kết quả trên Firestore Emulator với project demo. Bản rules remote đang chạy vẫn là release 04/11; bản siết 10/11 (commit `e5256c1`) chưa deploy — hạng mục G-09. Không dùng kết quả emulator để nói rules mới đã live.

### 2.1 Rules — phạm vi 15 test

1. Tạo hồ sơ lần đầu: role mặc định `user`, chặn tự đặt `admin`, giới hạn 40 trường.
2. Hồ sơ riêng tư: chỉ chủ sở hữu đọc; Admin chỉ sửa trường `role`.
3. Đơn kế hoạch: chủ sở hữu tạo `pending`, không sửa nội dung sau khi gửi.
4. Duyệt một lần: Staff chỉ chuyển `pending → approved/rejected`, bắt buộc lý do, `reviewedBy` trùng UID.
5. Sinh viên không đọc hàng đợi duyệt; Staff không nộp bài như sinh viên.
6. Thông báo: chỉ Staff/Admin tạo, payload đúng schema.
7. Catalog: giữ mã môn bất biến, hỗ trợ archive, học kỳ 0–12, mã `*`.
8. Curriculum chỉ đọc khi đăng nhập; audit log append-only đúng chủ.
9. `experience_notes`: sinh viên gửi `pending`, Staff duyệt, bản đã duyệt công khai.
10. Bốn subcollection legacy chỉ chủ sở hữu đọc.
11. Fixture bí kíp có `title` hợp lệ (CR-26), tránh test đỏ giả.

### 2.2 AI — bằng chứng model thật

| Tệp | Nội dung |
|---|---|
| `evidence/ai/study-plan-2026-11-10-valid.json` | 3/3 output Kỳ 3/5/8 đúng schema `goal` + `actions`, model `gemini-3.5-flash-lite` |
| `evidence/ai/study-plan-2026-11-10.json` | Ca lỗi thật: một output lặp vô hạn (vi phạm schema, app ném `FormatException`) và hai lần HTTP 503 |

Hai tệp dùng cùng system instruction/prompt với `lib/services/study_plan_ai.dart`. Đây là bằng chứng ở tầng model, không phải ảnh UI trên thiết bị.

## 3. ARTEMIS E2E

### 3.1 Đã chạy

- **10 ca × 3 lượt pass** trên Pixel 7 API 35 (giả lập), ghi trong `evidence/artemis/2026-11-07-flash-lite.md`, `2026-11-07-regression.md`, `2026-11-08-completion.md`.
- TC_13 (FCM token sau cold start): `3 passed in 57.51s`, trace `a23c7a10…`, `034ff4e6…`, `4b13c8b5…`.
- TC_11 (Remote Config): pass 3/3 trên giả lập, đối chiếu giá trị trước/sau.
- Lượt timeout TC_02 được giữ trong lịch sử, không tính pass.

### 3.2 Chưa đạt

| Mục | Trạng thái | Ghi chú |
|---|---|---|
| TC_14 Analytics `search_course`/`course_view` | **Fail** | Gemini trả HTTP 429 do giới hạn theo phút; trace `da4a9901…` |
| Exploratory ≥ 15 phút | **Chưa đạt** | Lượt dài nhất ~9 phút; lượt thứ hai dừng ở 7,5 phút vì HTTP 429 |
| 26 kịch bản Final trên **điện thoại thật** × 3 lượt | **Chưa chạy** | Thiết bị đang khóa (MIUI chặn ADB input); kịch bản nằm trong `docs/test-plan.md` |
| Cross-role 3 lượt trên hệ thống deploy | **Chưa chạy** | Web đã deploy 10/11 (G-01); còn đo độ trễ khi demo |

Ma trận 26 ca, tiền điều kiện và kết quả mong đợi: `docs/test-plan.md`. Không dùng kết quả giả lập thay cho yêu cầu thiết bị thật.

## 4. Web admin

- 14/14 test Node pass (parser FLM, API server).
- Đã kiểm tra thủ công trên trình duyệt: sign-in render, empty state không có dữ liệu mẫu, luồng thêm chuyên ngành thủ công, import 5 file HTML FLM thật (49 môn, 4 đề cương).
- **Chưa có** ảnh checklist 5 màn sau đăng nhập trên URL deploy. Ngày 10/11 đã xác nhận `https://prm323-lab2-gr6.web.app/` trả trang đăng nhập (`evidence/firebase/auth/web-deploy-signin-2026-11-10.png`); phần chụp trong app cần tài khoản staff/admin thử.

## 5. Review code mới (AI hỗ trợ)

Review chạy trên working tree và lịch sử Git nhánh `main`; không giả lập reviewer độc lập. Sáu finding tiêu biểu, đầy đủ trong `docs/code-review.md`:

| ID | Phát hiện | Quyết định | Kiểm chứng |
|---|---|---|---|
| CR-15 | `AdvisorViewModel` import trực tiếp `cloud_firestore`, `firebase_ai` | Tách `AiService`/`GeminiAiService`, inject qua Provider | Analyze sạch, 159 test pass (`bd4c989`) |
| CR-16 | Role gate đọc Firestore SDK trong widget | Thêm `watchUserRole` ở service layer | Test role gate pass (`bd4c989`) |
| CR-17 | Một dịch vụ Firebase lỗi chặn toàn app | Cô lập từng bước trong `try/catch`, lỗi cốt lõi vẫn chặn | Build/run ổn định (`bd4c989`) |
| CR-18 | Sync Vault để lại task "Connectivity check" | Ghi marker, đọc lại, xóa đúng bản ghi vừa tạo | Chạy lại sync không còn rác (`f2b2cb0`) |
| CR-20 | Rules cho phép hồ sơ tự khai `admin`, audit log nhận mọi trường | Chặn `admin != false`, giới hạn 40 trường; audit log 3 trường | Rules 15/15 (`e5256c1`) |
| CR-21 | Listener web lỗi chỉ log console, màn trắng | Banner lỗi + nút thử lại từng màn; thêm Analytics/RC/App Check | `node --check` + test web pass (`c9b9985`) |

Nợ kỹ thuật còn mở: CR-27 (ba widget gọi thẳng `FinalFirestore`). CR-28 (event AI thiếu `feature`) và CR-29 (test `AnnouncementsViewModel`) đã đóng ở `4142399`; CR-30 đã xác nhận `uv.lock` ghim commit ARTEMIS.

## 6. Điều kiện thoát

- [x] Analyze 0 issue, 159 test pass, build debug/release.
- [x] Rules 15/15 trên emulator.
- [x] Web 14/14 test.
- [x] AI có 3 output thật + 1 ca lỗi được xử lý.
- [x] ≥ 3 finding review có quyết định và commit.
- [ ] Ảnh checklist web trên URL deploy.
- [ ] ARTEMIS 26 ca Final trên thiết bị thật × 3 lượt + exploratory ≥ 15 phút.
- [ ] Cross-role 3 lượt trên hệ thống deploy, có số đo độ trễ.
- [ ] Ảnh Console: RC tắt cờ AI, App Check, Analytics DebugView, Crashlytics.
