# Lab 3 Report — Outline 8–12 trang (draft G2, 03/11)

> Khung nội dung cho `report/Lab3_Report_<StudentID>.pdf`. Quy ước: mọi chỗ **⏳** chỉ
> điền số liệu/ảnh SAU khi có evidence runtime thật (E3/Console) — guide §9.3, không bịa.
> Ảnh dẫn từ `evidence/` theo tên đã đặt (`TC-*_YYYY-MM-DD`, `SCR-*`, `FLW-*`).

## Trang 1 — Trang bìa + mục lục
Tên đề tài, sinh viên/mã SV, repo, Firebase project, ngày. Ảnh app (màn Home) — ⏳ chờ screenshot `SCR-01.0_Home`.

## §1 Context & Scope (~1 tr)
- FPTU Second Brain: từ Lab 2 (prototype offline, dữ liệu mẫu) → Lab 3 (cloud app Firebase, dữ liệu thật).
- 3 personas năm 1 / năm 3 / năm cuối (P01–P03, `ux/personas/`); 3 user flows chính giữ nguyên phạm vi Lab 2.
-范围 rubric: 6 dịch vụ Firebase, ARTEMIS E2E ≥10 cases ×3 runs, AI code review ≥5 findings, exploratory 15–30′.

## §2 Architecture (~1.5 tr)
- MVVM: View → ViewModel → Service → Firebase; bằng chứng tĩnh: 0 import `firebase_*` trong `lib/screens|widgets`.
- State model `AsyncViewState` 4 trạng thái; Provider DI; theme tokens Material 3 + 11 reusable widgets.
- Sơ đồ: kế thừa 2 diagram Mermaid từ `docs/architecture.md` (render PNG sang report/asset).
- **Kiến trúc fail-loud** (quyết định lớn nhất Lab 3): mọi mock fallback im lặng bị xóa; init fail → `FirebaseConfigErrorApp`; lỗi ghi → error snackbar + revert, không claim thành công.

## §3 Features & User Flows (~2 tr)
- 12 màn hình (bảng mapping route ↔ screen ↔ VM ↔ collection — cắt từ `docs/design-traceability.md`).
- Flow 1 Curriculum: seed `courses` + `passedCourses`, tiên quyết, chi tiết môn. **Đã verify đọc Firestore trên device 02/11.**
- Flow 2 Study Plan: task canonical-ID fix (BUG-01, `decae72`), undo 8s. ⏳ update-existing-task (TC-V1).
- Flow 3 Advisor: retry giữ câu hỏi, Strategy Simulator; `NoteModel` Timestamp fix (BUG-02, `261e6dc`). ⏳ offline/recovery ảnh.
- PDF export: consent → generate data thật (DejaVu tiếng Việt) → upload `reports/{uid}/` → URL. ⏳ progress + URL screenshots.

## §4 Firebase Integration (~1.5 tr)
- Project `prm323-lab2-gr6`; app ID; `google-services.json` ngoài repo (policy).
- Auth: Google + **gate `@fpt.edu.vn`** (`hostedDomain` + kiểm tra server-side `invalid-domain`, sign-out tài khoản ngoại domain — `261e6dc`).
- Firestore: collections + rules owner-scoped default-deny (đoạn rules chính in gọn, **đã cắt project number**); offline `Source.serverAndCache`.
- Storage: path `reports/{uid}`, `notes/{uid}/{allPaths=**}`; rules không `if true`. ⏳ bucket provisioning status.
- Analytics: 11 events, `setUserId`, PII `_sanitizeParameters`; ⏳ DebugView 2 param/event.
- Crashlytics: user id + custom key `auth_method`, non-fatal + test crash; ⏳ dashboard.
- Remote Config: `maintenance_mode`/`min_app_version` + defaults json; ⏳ before/after không rebuild.
- FCM: token `users/{uid}/tokens`, 3 trạng thái, tap-route Notification Center; ⏳ 6 ảnh.

## §5 Testing (~2 tr)
- Kim tự tháp: 68/68 unit+widget hermetic (04/11) — nêu rõ **hermetic ≠ runtime PASS** (guide tr.23).
- `docs/test-plan.md`: ma trận TC ↔ 3 flow + nhánh lỗi + TC-S per-service + TC-V (nợ M10).
- ARTEMIS: harness 26 cases (`e2e_test/`), Flash cho regression + Pro cho exploratory/export; assert **giá trị quan sát được** (logcat, doc ID, chuỗi trả lời) không chỉ SUCCESS; native interaction qua adb (wifi toggle, screencap, pm revoke).
- ⏳ Bảng pass rate ×3 runs, avg duration, flaky log; exploratory summary (≥15′).

## §6 AI Code Review (~1 tr)
⏳ Toàn bộ chờ PR + bot (Phase F): ≥5 findings ≥2 nhóm, bảng Accepted/Modified/Rejected + lý do; 3 commit `fix(CR-0x)` độc lập dẫn link. (Chính sách AI minh bạch: `ai/ai-code-log.md` — 12 phiên, chỉ dẫn bởi guide §7.2.)

## §7 Challenges & Lessons (~1 tr)
- BUG-01 legacy doc-ID (spread Dart ghi đè `id`) — debug bằng log capture có kiểm soát rồi gỡ (M11C→M11E).
- BUG-02 Firestore `Timestamp` vs `DateTime` parse.
- Stash/merge conflict làm hỏng `test-plan.md` trong commit nhóm — bài học pre-push check (`docs/pre-push-repair.md`).
- Spark plan giới hạn (bucket) + evidence audit nội bộ (M10) hạ nhãn runtime PASS từng NOT TESTED — liêm chính bằng chứng.
- ⏳ Test flaky phát hiện ở E3.

## §8 Deliverables & Appendix (~0.5–1 tr)
Cấu trúc repo, cách chạy (trích README), link video/slides, cây `evidence/`, bảng traceability rubric → evidence file.
