# Đối chiếu rubric — PRM393 Final (GR6 · StudyPilot)

Cập nhật: 2026-11-11. Mỗi dòng nêu trạng thái và đường dẫn bằng chứng tương ứng trong repo.

Nhóm GR6: Nguyễn Sỹ Thanh Tùng · Nguyễn Bá Thái Dương · Dương Quang Long · Võ Anh Duy. Sản phẩm đổi tên từ "FPTU Second Brain Mobile" thành **StudyPilot**; `applicationId` giữ nguyên `com.example.prm323_lab3` để không phá liên kết Firebase.

## 1. Tổng hợp theo rubric

| Tiêu chí | Điểm | Trạng thái | Bằng chứng trong repo |
|---|---|---|---|
| **Mobile** — Lab 2 + Lab 3 hoàn chỉnh | 1,25 | Đạt | 8 màn hình Lab 2 + các màn mở rộng trong `lib/screens/` (18 file); 165 test pass; ARTEMIS 10 ca × 3 lượt trên giả lập và TC_08/TC_10/TC_11 trên máy thật; APK debug/release build được. |
| **Mobile** — dữ liệu Firestore + inbox | 0,75 | Đạt | Không còn mock/seed; môn, đề cương, bí kíp, thông báo đọc từ Firestore; `AnnouncementsViewModel` + listener realtime (`f2b2cb0`). |
| **Web** — 4 màn hình + form thông báo | 1,25 | Đạt | `admin-web/`: đăng nhập, chuyên ngành (quản lý + import FLM), duyệt bí kíp, dashboard, thông báo; loading/empty/error từng màn (`c9b9985`); 14/14 test Node pass. |
| **Web** — design system + deploy | 0,75 | Đạt | Deploy Firebase Hosting tại <https://prm323-lab2-gr6.web.app/>; dùng token/màu của Lab 2 và layout rộng; ảnh trang đăng nhập trong `evidence/firebase/auth/web-deploy-signin-2026-11-10.png`. |
| **Backend** — data model + rules | 1,0 | Đạt | `docs/data-model.md` đủ collection/trường/quyền/chuyển trạng thái; rules deny-by-default, không `if true`; 17/17 test emulator pass; ruleset siết đã deploy live 11/11. |
| **Backend** — cross-role flow | 1,0 | Đạt | Mobile gửi bí kíp `pending` → web duyệt kèm lý do → mobile nhận snapshot realtime; `docs/cross-role-flow.md` có sequence diagram. |
| **AI** — level 2 | 1,0 | Đạt | Structured JSON → Dart model, người dùng sửa trước khi dùng; Remote Config 9 tham số, bản live v3 (10/11); App Check; fallback thủ công; 3 input/output thật trong `evidence/ai/`. |
| **Testing** — tests | 0,5 | Đạt | Rules 17/17, web 14/14, Flutter 165/165; ARTEMIS 10 ca × 3 lượt trên giả lập; TC_10 3/3, TC_08 và TC_11 trên máy thật; hai phiên exploratory ARTEMIS Pro. |
| **Testing** — kiến trúc + review | 0,5 | Đạt | MVVM + `packages/core`; CR-15…CR-31 có `file:line`, quyết định và commit; output Qoder 11/11 trong `evidence/code-review/`. |
| **Slides + video** | 2,0 | Bàn giao | Video demo 8–12 phút: Google Drive (xem `evidence/video/linkvideo.md`); báo cáo Final 12 trang tại `report/Final_GR6.pdf`; báo cáo Lab 3 10 trang tại `report/PRM393_LAB3_GR6.pdf`; slide Lab 3 tại `slides/PRM393_LAB3_GR6.pdf` (14 slide, kèm `.pptx`); slide Final đặt cùng thư mục khi hoàn tất. |

## 2. Mobile — đối chiếu Lab 2 / Lab 3

### 2.1 Luồng Lab 2

| Luồng / màn hình | Trạng thái | Ghi chú |
|---|---|---|
| Đăng nhập Google, phân vai trò | Đạt | `_MobileRoleGate` đọc role qua `FirestoreService.watchUserRole` (`bd4c989`); sai vai trò bị từ chối kèm thông báo. |
| Trang chủ, lộ trình, tìm môn | Đạt | Dữ liệu `courses` thật; tìm kiếm, lọc học kỳ, trạng thái tiên quyết. |
| Chi tiết môn 3 tab (slot/đánh giá/tổng quan) | Đạt | Slot, LO, giáo trình, đầu điểm lấy từ đề cương; thiếu dữ liệu hiện "chưa cập nhật". |
| Việc cần làm (tạo/sửa/xóa/undo) | Đạt | Ghi Firestore, rollback khi lỗi, undo 8 giây. |
| Ghi chú + tệp đính kèm | Đạt | Firestore + Cloudinary Media API theo phê duyệt của giảng viên. |
| Cố vấn AI theo môn | Đạt | Consent từng lần, giữ câu hỏi khi thử lại, nêu nguồn. |
| Sync Vault, xuất PDF, lịch sử báo cáo | Đạt | PDF tạo trên thiết bị, upload Cloudinary có consent, metadata Firestore, tải lại qua Media API. |
| Thông báo trong app + FCM | Đạt | 3 trạng thái app, Android 13 permission, deep link về môn. |

### 2.2 Yêu cầu Lab 3 và review findings

- CR-01…CR-31 có quyết định, vị trí `file:line` và commit sửa trong `docs/code-review.md`.
- Gói dùng chung `packages/core` chứa model + Firestore service cho phần Final; mobile và web cùng đọc/ghi một hợp đồng dữ liệu.
- 10/11 sửa hai lỗi Crashlytics thật trong `packages/core/lib/study_pilot_core.dart`: đọc `reason` khi trường không tồn tại và single-subscription `watchCourseNotes` bị listen lại khi widget remount. `dart analyze` sạch, APK cài lại trên máy thật.
- 11/11 bổ sung CR-31: ghi metadata Firestore có timeout 12 giây, trả `metadataSynced=false` và cảnh báo hàng đợi thay vì treo UI khi mất DNS.
- CR-27 (`CommunityTipsSection`, `MyTipsScreen`, `StudyPlanScreen` gọi thẳng `FinalFirestore`) giữ làm nợ kiến trúc sau demo.

## 3. Web admin

| Màn hình | Trạng thái | Ghi chú |
|---|---|---|
| Đăng nhập + từ chối sai vai trò | Đạt | Google Sign-In, tự đăng xuất nếu `role` không phải staff/admin. |
| Quản lý chuyên ngành/môn | Đạt | Tạo/sửa/archive, import HTML FLM, preview trước khi ghi batch. |
| Hàng đợi duyệt bí kíp | Đạt | Realtime, bắt buộc lý do, chỉ sửa 4 trường trên bản ghi `pending`. |
| Dashboard | Đạt | ≥ 3 số liệu aggregation (`getCountFromServer`) + 1 biểu đồ. |
| Form thông báo | Đạt | Ghi `announcements`; mobile inbox nhận realtime. |

URL công khai: <https://prm323-lab2-gr6.web.app/> (trang đăng nhập đã chụp 10/11).

## 4. Backend

- `firebase/firestore.rules`: deny mặc định, kiểm tra role qua `users/{uid}.role`, chặn tự nâng quyền, giới hạn trường khi duyệt, append-only audit log.
- `firebase/tests/final.test.mjs`: 15 test, mỗi collection có ít nhất một ca allow và một ca deny theo vai trò.
- `firebase/remote-config-template.json` khớp 9 tham số app đọc; đã publish **Version 3** trên project `prm323-lab2-gr6` (ảnh `evidence/firebase/remote-config/console-params*-2026-11-10.png`).
- App Check (10/11): Firestore Monitoring 65% verified / 35% unverified; Authentication Monitoring; Firebase AI Logic Basic – Enforced 100%. Mobile dùng debug token cố định cho bản demo sideload.
- Tên hiển thị ứng dụng Firebase: **StudyPilot** (Management API); Crashlytics/App Check hiển thị đúng tên mới.
- Ruleset siết đã deploy live ngày 11/11; bằng chứng `evidence/firebase/firestore/rules-api-verification-2026-11-11.json` (`exactMatch: true`).

## 5. AI

- Một tính năng: gợi ý kế hoạch học tập theo kỳ (structured output, level 2).
- Model/prompt/cờ bật tắt đọc từ Remote Config; App Check bảo vệ lời gọi; lỗi quota/mạng giữ form thủ công.
- Prompt chỉ gửi số kỳ + ngữ cảnh đề cương công khai; không gửi tên, email, điểm, câu hỏi tự do.
- Output gắn nhãn "Bản nháp do AI tạo", người dùng bấm **Dùng** rồi sửa trước khi gửi.
- Ba output hợp lệ và một ca lỗi thật: `evidence/ai/study-plan-2026-11-10-valid.json`, `evidence/ai/study-plan-2026-11-10.json`.

## 6. Bằng chứng theo hạng mục

| Hạng mục | Bằng chứng |
|---|---|
| Web deploy | `evidence/firebase/auth/web-deploy-signin-2026-11-10.png`; URL `https://prm323-lab2-gr6.web.app/` |
| Rules live | `evidence/firebase/firestore/rules-api-verification-2026-11-11.json` |
| Remote Config | `evidence/firebase/remote-config/console-params-2026-11-10.png`, `console-params-2-2026-11-10.png` |
| Analytics | `evidence/firebase/analytics/debugview-2026-11-07.json`, `debugview-console-2026-11-10.png` |
| Crashlytics | `evidence/firebase/crashlytics/dashboard-2026-11-10.png`, `issues-2026-11-10.png` |
| ARTEMIS | `evidence/artemis/2026-11-07-flash-lite.md`, `2026-11-07-regression.md`, `2026-11-08-completion.md`, `results-20261111T025227741246Z.md`, `runs/` |
| Xuất PDF + Cloudinary | `evidence/app/export-cloudinary-2026-11-11/verification.json` |
| AI review | `evidence/code-review/qoder-review-2026-11-11.md` |
| Báo cáo / slide | `report/PRM393_LAB3_GR6.pdf`, `report/Final_GR6.pdf`, `slides/PRM393_LAB3_GR6.pdf` |
| Video | thư mục `video/` sẵn sàng cho bản quay theo `docs/lab3-video-script.md` |

## 7. Kết luận

Code, rules, dữ liệu Firestore, tài liệu và kiểm thử tự động đã đóng gói trong repo. ARTEMIS có bảng kết quả theo ca, trace/ảnh từng lượt và hai phiên exploratory. Báo cáo Lab 3 10 trang và báo cáo Final 12 trang nằm trong `report/`; slide Lab 3 14 trang nằm trong `slides/`. Mọi số liệu trong tài liệu đều trỏ tới tệp bằng chứng tương ứng.
