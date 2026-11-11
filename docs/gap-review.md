# Gap review — PRM393 Final (GR6 · StudyPilot)

Cập nhật: 2026-11-10. Tài liệu đối chiếu Lab 2 + Lab 3 hiện có với rubric Final. Mỗi dòng ghi **trạng thái thật** và đường dẫn bằng chứng; dòng chưa có bằng chứng không được tính là hoàn tất.

Nhóm GR6: Nguyễn Sỹ Thanh Tùng · Nguyễn Bá Thái Dương · Dương Quang Long · Võ Anh Duy. Sản phẩm đổi tên từ "FPTU Second Brain Mobile" thành **StudyPilot**; `applicationId` giữ nguyên `com.example.prm323_lab3` để không phá liên kết Firebase.

## 1. Tổng hợp theo rubric

| Tiêu chí | Điểm | Trạng thái | Bằng chứng / khoảng trống |
|---|---|---|---|
| **Mobile** — Lab 2 + Lab 3 hoàn chỉnh | 1,25 | Đạt phần lớn | 8 màn hình Lab 2 + các màn mở rộng nằm trong `lib/screens/` (18 file). 159 test pass, APK debug/release build được. Còn thiếu: lượt E2E trên **điện thoại thật** cho 26 kịch bản Final (máy đang khóa) và phiên exploratory ≥ 15 phút. |
| **Mobile** — dữ liệu Firestore + inbox | 0,75 | Đạt | Không còn mock/seed; môn, đề cương, bí kíp, thông báo đọc từ Firestore. `AnnouncementsViewModel` + listener realtime (`f2b2cb0`). |
| **Web** — 4 màn hình + form thông báo | 1,25 | Đạt trong code | `admin-web/`: đăng nhập, chuyên ngành (quản lý + import FLM), duyệt bí kíp, dashboard, thông báo. Loading/empty/error từng màn (`c9b9985`). 14/14 test Node pass. Chưa có ảnh checklist từng màn. |
| **Web** — design system + deploy | 0,75 | Đạt | Deploy Firebase Hosting tại <https://prm323-lab2-gr6.web.app/> (kiểm tra 10/11/2026, trang đăng nhập mở được). Dùng token/màu của Lab 2 và layout rộng. Ảnh checklist từng màn sau đăng nhập còn thiếu (G-02). |
| **Backend** — data model + rules | 1,0 | Đạt | `docs/data-model.md` đủ collection/trường/quyền/chuyển trạng thái. Rules deny-by-default, không `if true`; 15/15 test emulator pass. |
| **Backend** — cross-role flow | 1,0 | Đạt trong code | Mobile gửi bí kíp `pending` → web duyệt kèm lý do → mobile nhận snapshot realtime. `docs/cross-role-flow.md` có sequence diagram. Chưa đo 3 lượt trên hệ thống đã deploy. |
| **AI** — level 2 | 1,0 | Đạt phần lớn | Structured JSON → Dart model, người dùng sửa trước khi dùng; Remote Config 9 tham số; App Check; fallback thủ công; 3 input/output thật trong `evidence/ai/`. Chưa quay cảnh tắt cờ RC trên thiết bị. |
| **Testing** — tests | 0,5 | Một phần | Rules 15/15, web 14/14, Flutter 159/159. ARTEMIS: 10 ca × 3 lượt pass trên giả lập; TC_14 analytics và exploratory 15 phút chưa đạt; 26 ca Final chưa chạy trên máy thật. |
| **Testing** — kiến trúc + review | 0,5 | Đạt | MVVM + `packages/core`; CR-15…CR-26 đã sửa và có commit; CR-27 còn là nợ kỹ thuật, CR-28…CR-30 đã đóng hoặc xác nhận. |
| **Slides + video** | 2,0 | Một phần | Slide 14 trang đã sinh tại `slides/Final_GR6_slides.pdf` (nguồn `tool/generate_final_slides_pdf.dart`); báo cáo 12 trang tại `report/Final_GR6.pdf`. Video 8–12 phút chưa quay, nên hạng mục chưa đóng. |

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
| Sync Vault, xuất PDF cục bộ, lịch sử báo cáo | Đạt | PDF tạo trên thiết bị, metadata trong Firestore; upload cloud là tùy chọn. |
| Thông báo trong app + FCM | Đạt | 3 trạng thái app, Android 13 permission, deep link về môn. |

### 2.2 Yêu cầu Lab 3 và review findings

- Đã đóng CR-01…CR-26; chi tiết quyết định và commit trong `docs/code-review.md`.
- Gói dùng chung `packages/core` chứa model + Firestore service cho phần Final; mobile và web cùng đọc/ghi một hợp đồng dữ liệu.
- Nợ kỹ thuật còn mở: CR-27 (`CommunityTipsSection`, `MyTipsScreen`, `StudyPlanScreen` gọi thẳng `FinalFirestore`). CR-28 (event AI thiếu `feature`), CR-29 (test `AnnouncementsViewModel`) đã đóng; CR-30 đã xác nhận `uv.lock` ghim đúng commit ARTEMIS.

## 3. Web admin

| Màn hình | Trạng thái | Ghi chú |
|---|---|---|
| Đăng nhập + từ chối sai vai trò | Đạt trong code | Google Sign-In, tự đăng xuất nếu `role` không phải staff/admin. |
| Quản lý chuyên ngành/môn | Đạt trong code | Tạo/sửa/archive, import HTML FLM, preview trước khi ghi batch. |
| Hàng đợi duyệt bí kíp | Đạt trong code | Realtime, bắt buộc lý do, chỉ sửa 4 trường trên bản ghi `pending`. |
| Dashboard | Đạt trong code | ≥ 3 số liệu aggregation (`getCountFromServer`) + 1 biểu đồ. |
| Form thông báo | Đạt trong code | Ghi `announcements`; mobile inbox nhận realtime. |

Khoảng trống: đã có URL công khai trong README và xác nhận trang đăng nhập mở được; còn thiếu ảnh checklist các màn sau đăng nhập (G-02) — cần tài khoản staff/admin thử khi chụp.

## 4. Backend

- `firebase/firestore.rules`: deny mặc định, kiểm tra role qua `users/{uid}.role`, chặn tự nâng quyền, giới hạn trường khi duyệt, append-only audit log.
- `firebase/tests/final.test.mjs`: 15 test, mỗi collection có ít nhất một ca allow và một ca deny theo vai trò.
- `firebase/remote-config-template.json` khớp 9 tham số app đọc.
- App Check bật cho Firestore và AI Logic; mobile dùng debug token cố định cho bản demo (không thể qua Play Integrity trên APK sideload).

## 5. AI

- Một tính năng: gợi ý kế hoạch học tập theo kỳ (structured output, level 2).
- Model/prompt/cờ bật tắt đọc từ Remote Config; App Check bảo vệ lời gọi; lỗi quota/mạng giữ form thủ công.
- Prompt chỉ gửi số kỳ + ngữ cảnh đề cương công khai; không gửi tên, email, điểm, câu hỏi tự do.
- Output gắn nhãn "Bản nháp do AI tạo", người dùng bấm **Dùng** rồi sửa trước khi gửi.
- Ba output hợp lệ và một ca lỗi thật: `evidence/ai/study-plan-2026-11-10-valid.json`, `evidence/ai/study-plan-2026-11-10.json`.

## 6. Việc còn mở và điều kiện đóng

| # | Việc | Cách đóng | Phụ thuộc |
|---|---|---|---|
| G-01 | Deploy web lên Firebase Hosting | **Đã đóng 10/11/2026**: `https://prm323-lab2-gr6.web.app/` trả trang đăng nhập; ảnh lưu tại `evidence/firebase/auth/web-deploy-signin-2026-11-10.png` | — |
| G-02 | Ảnh checklist web (5 màn + lỗi/rỗng/sai vai trò) | Chụp trên URL đã deploy | G-01 (đã xong), cần tài khoản staff/admin thử |
| G-03 | 3 lượt cross-role trên hệ thống deploy, đo độ trễ | Quay màn hình hai client, ghi số giây | G-01 (đã xong) |
| G-04 | ARTEMIS 26 ca Final trên điện thoại thật × 3 lượt | Mở khóa máy, chạy `e2e_test`, lưu trace/ảnh | Thiết bị: HyperOS chặn `adb shell input tap` (SecurityException) — cần bật **Gỡ lỗi USB (Cài đặt bảo mật)** và **Cài đặt qua USB** |
| G-05 | TC_14 Analytics + exploratory ≥ 15 phút | Chạy lại khi hết giới hạn quota | Thiết bị + quota |
| G-06 | Ảnh Console: RC tắt cờ, App Check, Analytics, Crashlytics | Chụp khi demo | Tài khoản chủ project |
| G-07 | Video 8–12 phút | Quay theo `docs/lab3-video-script.md` | G-01, G-04 |
| G-08 | Đổi tên repo GitHub `PRM393_Final_GR6` | **Đã đóng 10/11/2026**: repo đổi tên, remote `personal` và README cập nhật | — |
| G-09 | Deploy rules Firestore bản siết 10/11 | `firebase deploy --only firestore:rules`, kiểm tra lại release; bản remote hiện tại vẫn là release 04/11 | Cần đăng nhập Firebase CLI |

## 7. Kết luận

Phần **code, rules, tài liệu và kiểm thử tự động** đã đóng. Các mục còn mở chủ yếu là bằng chứng runtime cần tài khoản Firebase, thiết bị mở khóa hoặc quota AI. Ngày 10/11 đã đóng G-01 (web deploy) và G-08 (đổi tên repo); ảnh checklist web (G-02), cross-role trên hệ thống deploy (G-03), ARTEMIS (G-04/G-05), ảnh Console (G-06), video (G-07) và rules deploy (G-09) vẫn chờ. Báo cáo và slide chỉ khẳng định những gì có bằng chứng tương ứng. Riêng rules, `evidence/firebase/firestore/rules-api-verification-2026-11-04.json` cho thấy bản remote là release 04/11 (`remoteCharacters: 2230`), chưa phải bản siết ngày 10/11 đã qua 15/15 test emulator — không được mô tả là đã live cho tới khi G-09 đóng.
