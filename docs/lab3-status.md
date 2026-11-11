> Cập nhật tiếp 04/11: 114 Flutter tests, analyzer sạch, APK/PDF cục bộ và menu chia sẻ đã xác minh. FCM ba trạng thái + cold deep link, RC 31→30 cùng APK và dashboard Crashlytics đã có evidence. Upload Storage còn thiếu bucket/billing; ARTEMIS đủ số lượt chưa đạt (quota). Chi tiết: docs/implementation-verification-2026-11-04.md.

> Cập nhật tiếp hạng mục 1–2–3 ngày 04/11/2026: xem [báo cáo xác minh mới](implementation-verification-2026-11-04.md). Đã thêm nhập dữ liệu học tập riêng, Advisor/Strategy theo dữ liệu, tab môn và route FCM. Cloud evidence/E2E vẫn có blocker thực; checklist cũ không chứng minh hoàn tất.

> **Đính chính 04/11/2026:** Working tree có thay đổi chưa commit. Không dùng các tuyên bố “tree sạch” hoặc “100% code” phía dưới làm kết luận hiện hành. Xem [fix-verification-2026-11-04.md](fix-verification-2026-11-04.md): regression fixes và 100/100 Flutter tests; Console/E2E/submission vẫn cần evidence.

# PRM393 Lab 3 — Trạng thái task (đã xong / còn nợ)

> **Cập nhật:** 2026-11-03 (rev 4) · **HEAD `7d201f5` = origin/main, working tree sạch**
> (toàn bộ work 03/11 đã được bạn commit + push: `277f475..7d201f5`, 8 commit).
> Rev 4 ghi nhận: 4 nợ checklist đã trả bằng code (Semantics, logout rebuild-list,
> strategy events 12–13, DebugView→adb setprop), `docs/lab3-self-assessment.md`
> (rubric 13 dòng), suite **89/89 · analyze 0**.
> Rev 3 (đã commit): harness checklist §8.3 **26 cases**, mapping §1b, evidence tree
> §10.1, `.gitignore` Python, README 3 mục mới, `LAB3_CHECKLIST.md` re-tick, draft G2/G3
> (`docs/lab3-report-outline.md`, `docs/lab3-slides-outline.md`, `docs/lab3-video-script.md`).
> Code mới pull (`261e6dc`) thêm: FPT-domain gate (S-10), NoteModel parse Timestamp,
> SyncReloadService, **seed catalog đã xác minh trên device** — xem
> `docs/lab3-completion-progress.md` + `docs/lab3-final-requirement-audit.md`.
> Nguồn chéo: `docs/lab3-task-map-v5.md` (plan A–G) · `docs/test-plan.md` (TC-*) ·
> git log · `docs/t03-m*` · `flutter analyze` (0 issues) / `flutter test` (**89/89**).
> File này là snapshot; cập nhật lại mỗi khi xong một mục.

---

## ✅ ĐÃ XONG

### Phase A — Mở khoá + Persistence runtime
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| Firebase project, SHA-1, `google-services.json`, Google Sign-In (M1) | device verify | `d977c00`, `107a69f` |
| Rules owner-based + `storage.rules` path recursive `notes/{uid}/{allPaths=**}` (A2) | audit M7 code-confirmed | `firebase/firestore.rules`, `firebase/storage.rules` |
| Rules + Storage deploy (M2 — từng BLOCKED) | audit M10 xác nhận deployed rules khớp repo (71 dòng) | console `prm323-lab2-gr6` |
| Fix canonical task ID legacy + new format (M11D/E) | commit + docs | `decae72`, `docs/t03-m11d/e` |
| Root-cause update-task failure | phân tích M11B | `docs/t03-m11b` |

### Phase B — Hardening
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| `INTERNET` + `POST_NOTIFICATIONS` manifest (B1/T05) | grep manifest | `android/app/src/main/AndroidManifest.xml` |
| Bỏ mọi mock fallback — fail-loud (`FirebaseConfigErrorApp` chặn màn hình) (B2/T04) | audit M10 code-confirmed | `2116eaa` |
| Xóa no-op ternary, thống nhất 1 instance Crashlytics/RC (B3, S-08) | diff commit | `2116eaa` |

### Phase C — Instrumentation (code)
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| Analytics `setUserId`/`logLoginSuccess`/navigatorObservers, events 1 lần/action, `search_course` (C1/T08, S-07) | test suite pass | `2116eaa`, `e0c772d`, `test/services/analytics_wiring_test.dart` |
| Crashlytics `setUserIdentifier` + `setCustomKey` (C2/T09) | diff | `2116eaa`, `lib/services/crashlytics_service.dart` |
| Remote Config defaults + enforce `maintenance_mode`/`min_app_version` (C2/T10) | file có sẵn | `firebase/remote-config-defaults.json` |
| PII filter trong analytics | audit | `lib/services/firebase_analytics_service.dart` |

### Phase D — Features lớn
| Mục | Bằng chứng | Commit / file |
|---|---|---|
| PDF export: picker → generate data thật → **consent dialog** → upload progress `reports/{uid}/` → metadata → event `export_report` (D1/T11) | `sync_vault_screen.dart:134` consent + test pass | `2116eaa`, `lib/services/report_export_service.dart`, `test/services/report_export_service_test.dart` |
| FCM: token store + handlers 3 trạng thái + tap routing + Notification Center + rules `notifications` (D2/T12) | test pass | `d1ca8c1`, `lib/services/firebase_messaging_service.dart`, `lib/screens/notifications_screen.dart`, `test/viewmodels/notifications_test.dart` |
| Advisor retry + task edit UI + attachment upload thật (D3/F-05/F-07) | diff | `89405be` |
| Drop persona data / domain label khỏi UI (data minimization) | diff | `5be1db4`, `89405be` |

### Test + nền tảng tài liệu
| Mục | Bằng chứng |
|---|---|
| Unit/widget/model suite xanh **59/59** | `flutter test` 03/11 trên `261e6dc` |
| **Runtime device 02/11**: sign-in, Roadmap read sau seed, Task create/toggle, Note create/delete, manual sync | `docs/lab3-completion-progress.md` (commit `261e6dc`) |
| FPT-domain gate S-10 (`hostedDomain` + check server-side, sign-out if ngoại domain) | `261e6dc` `firebase_auth_service.dart` |
| **ARTEMIS harness 26 cases** (rev 3: đổi tên file theo checklist §8.3 + thêm TC-05/13/14) — code-side xong (E2): 3 flows + TC-V1/V5 + error branch × dịch vụ + native ADB + exploratory. CHƯA chạy (chờ E1) | `e2e_test/` 03/11, mapping §1b test-plan |
| `docs/firestore-catalog-seed.md` · `docs/analytics-plan.md` · `docs/lab3-final-requirement-audit.md` | `261e6dc` |
| Repair test sau merge (FakeFirestoreService, imports, contracts) | `d41eb74`, `90554bb`, `docs/pre-push-repair.md` VERDICT READY |
| Gỡ debug capture blocks M11C (nợ trước code freeze) | commit `dae9ad9` |
| `docs/test-plan.md` living doc — dọn conflict markers stash, cập nhật verify 02/11, thêm nhóm TC-S | 03/11 |
| `ai/ai-code-log.md` — policy, 12 phiên (F4) | commit `dae9ad9` + rev 3 |
| `evidence/` cây đủ §10.1 (app/ firebase×7/ artemis/logs/ code-review/ figma/ report/ video/) + README naming | `evidence/` 03/11 (rev 3) |
| Draft G2/G3: outline report 8–12tr, slides 12–15tr, kịch bản video 7′30″ (chỗ chờ evidence đánh dấu ⏳, không bịa) | `docs/lab3-{report,slides}-outline.md`, `docs/lab3-video-script.md` 03/11 |
| `LAB3_CHECKLIST.md` re-tick theo thực tế + §14/§15 (DEC-01..05, BUG-01/02) | `docs/LAB3_CHECKLIST.md` 03/11 |
| **Nợ checklist trả hết (03/11, rev 3+):** Semantics Checkbox+tooltips; logout rebuild-list theo auth-state (+2 test); `strategy_view`/`strategy_preset_applied` wire vào AdvisorVM/sim screen (+3 test, plan 13 events); DebugView = adb setprop (firebase_analytics 13 bỏ API — ghi README); `curriculums` giải thích reserved; **tự đánh giá 13 dòng rubric** `docs/lab3-self-assessment.md`. Suite **89/89**, analyze 0 | `lib/` + `test/` + docs 03/11 |
| README draft Lab 3: build/run/test + bảng link tài liệu (G4 một phần) | commit `dae9ad9` |
| Audit banner T03-M8 ↔ M10 (M10 recommend #5) | commit `dae9ad9` |

---

## ❌ CÒN NỢ

### N-1 · Runtime verify TC-V (đóng nợ audit M10 — **làm trước tiên**)
| ID | Nợ gì | Ai |
|---|---|---|
| ~~N-1.1~~ | ~~Seed catalog~~ ✅ DONE 02/11 (Roadmap đọc `courses` + `passedCourses` — `lab3-completion-progress.md`) | — |
| N-1.2 | TC-V1: **UPDATE task có sẵn** + verify Console + log sạch — phần còn lại của nợ M11E (create/toggle mới pass) | Bạn + em |
| N-1.3 | TC-V2: offline persistence cycle (toggle wifi) — M10 NOT TESTED | Bạn (hoặc ARTEMIS TC-F3-02 sau E1) |
| N-1.4 | TC-V3: Note **attachment nested path** — create/delete note đã pass 02/11 | Bạn |
| N-1.5 | TC-V5: capture `adb logcat` — M10 NOT TESTED | Bạn/em (hoặc ARTEMIS TC-V5 sau E1) |
| N-1.6 | TC-V6: cross-account UID isolation — **cần Google account 2**; account phụ nên @fpt.edu.vn để test S-10 | Bạn |
| N-1.7 | Re-run T03-M8 full pass với ADB + nâng verify 02/11 lên **3 runs + ảnh** (guide tr.23) | sau N-1.2..5 |

### N-2 · Evidence batch Firebase (chụp 1 lần khi app chạy — guide §4.4/§9.2)
DebugView ≥7 events × ≥2 params · Crashlytics test crash · RC before/after ·
FCM 3 trạng thái + tap · PDF consent→progress→metadata · `evidence/firebase/` naming `SCR-/TC-`.

### N-3 · Phase E — ARTEMIS
| ID | Nợ gì |
|---|---|
| E1 | **Setup (Bạn)**: cài `uv`, clone+`./start.sh` google/artemis host, điền `e2e_test/.env` (GEMINI_API_KEY…), `uv sync`, emulator chạy — xem `e2e_test/README.md` |
| ~~E2~~ | ✅ Harness 16 cases đã dựng (`e2e_test/` 03/11) — API client có thể phải chỉnh theo README repo artemis bản bạn cài |
| E3 | 3 runs/test, bảng pass rate + avg duration vào `test-plan.md` §3, điều tra flaky |
| E4 | Exploratory 15–30′ + AI summary → `evidence/artemis/exploratory-summary.md` |
| — | Chụp `FLW-01..03` (3 flows) trên device → `evidence/artemis/` |
| — | **Storage bucket**: verify provisioning trên Console; nếu Spark chặn → quyết định nhóm (blocker PDF upload + attachment, rubric tr.25) |

### N-4 · Phase F — AI Code Review (cần code freeze + TC-V sạch)
| ID | Nợ gì |
|---|---|
| F1 | Push branch → mở PR → bật CodeRabbit/Copilot — **Bạn** (quyền repo) |
| F2 | `docs/code-review.md`: ≥5 findings `file:line` + severity + decisions + bảng decisions |
| F3 | 3 commit `fix(CR-01..03)` độc lập, **không squash** |
| — | Điền decision phiên S-10 vào `ai/ai-code-log.md` khi bạn review diff |

### N-5 · Phase G — Đóng gói & nộp
| ID | Nợ gì |
|---|---|
| G2 | Report PDF 8–12 tr — **outline xong** `docs/lab3-report-outline.md`; chờ ⏳ evidence để viết bản đầy đủ |
| G3 | Slides 12–15 tr — **outline xong** `docs/lab3-slides-outline.md`; **kịch bản video 7′30″ xong** `docs/lab3-video-script.md`; bản final chờ evidence + quay |
| G4 | README: bổ link video + mô tả evidence khi có (draft + 3 mục mới 03/11) |
| G5 | Checklist tự đánh giá 12 dòng guide §10 + re-tick `LAB3_CHECKLIST.md` — ✅ **rev re-tick 03/11** (theo thực tế, ⏳ đánh dấu rõ) |
| G6 | Cắt `google-services.json`/project number khỏi mọi screenshot (§9.3) + **quyết định rename repo** `PRM393_Lab03_<StudentID>` (S-12) |

### N-0 · Việc hành chính
- ~~Commit working tree~~ ✅ **XONG 03/11** — 8 commit `277f475..7d201f5` đã push `origin/main`, tree sạch.
- Còn treo: Student ID (trống ở bìa report/checklist) + quyết định rename repo khi nộp (G6).

---

## Tổng quan tiến độ & Mô hình 3 Chỉ số Minh bạch (Reconciled Metrics)

Dự án phân định rõ ràng 3 chỉ số tiến độ riêng biệt theo đúng chuẩn kỹ thuật và liêm chính học thuật:

### 1. Mức hoàn thiện mã nguồn (Code Implementation Completeness): 100%
- **Định nghĩa**: Tỷ lệ các tính năng, màn hình, dịch vụ và ràng buộc kỹ thuật quy định trong rubric đã được cài đặt đầy đủ trong mã nguồn Flutter và test harness.
- **Tiêu chí**:
  + 11/11 màn hình (8 màn hình Lab 2 + SignIn + CourseDetail + SyncVault/Profile)
  + Cố vấn học tập (Advisor) đủ 4 cấp độ (`course`, `semester`, `program`, `score`), bộ chọn UI ChoiceChips, hộp thoại `_askConsent()` fail-closed, cơ chế error/retry, disclaimer minh bạch
  + State model chuẩn 4 nhánh `AsyncViewState` (Loading, Empty, Error/Retry, Data) trên toàn bộ data screens
  + Chuẩn hóa Design Tokens (`AppColors`, `AppSpacing`, `AppElevation`, `AppFontSize`) và gán nhãn trợ năng `Semantics`
  + Version Gate chặn qua `min_app_version`, `maintenance_mode` đóng băng app, tách pure utility `lib/utils/version_utils.dart`
  + Firestore schema phân cấp owner-scoped, `firestore.rules` và `storage.rules` không có `allow true`, có default-deny
  + 13 custom events Analytics (lọc bỏ PII), Crashlytics custom keys, FCM 3 trạng thái + tap navigation
  + 89 ca kiểm thử hermetic trong `test/`, 26 kịch bản kiểm thử E2E trong `e2e_test/`
- **Kết quả**: **100% hoàn thiện code** (không còn tính năng nào chưa viết code).

### 2. Mức kiểm thử / xác minh (Testing & Verification Completeness): 75.0% (Trung bình) / 70.0% (Trọng số)
- **Định nghĩa**: Tỷ lệ các bài kiểm tra chất lượng phần mềm đã thực sự chạy thành công và có kết quả được xác nhận độc lập.
- **Tiêu chí & Kết quả thành phần**:
  + `flutter analyze`: **100%** (0 errors, 0 warnings, ran in 16.0s)
  + `flutter test`: **100%** (89/89 tests passed, 0 failed, 0 skipped, hermetic unit & widget suites)
  + `flutter build apk --debug`: **100%** (Exit 0, biên dịch thành công APK debug)
  + `ARTEMIS E2E`: **0% thực thi** (26 cases authored hoàn chỉnh tại `e2e_test/`, nhưng bị chặn bởi Gemini API HTTP 429 quota exhaustion; tuân thủ liêm chính học thuật KHÔNG giả mạo kết quả PASS)
- **Công thức tính toán minh bạch**:
  + **Cách 1 — Trung bình số học 4 trụ cột**: `(100% + 100% + 100% + 0%) / 4` = **75.0%**.
  + **Cách 2 — Trọng số kỹ thuật theo phạm vi & rủi ro**:
    * Static Analysis (`flutter analyze`): 20% × 100% = **20.0%**
    * Unit & Widget Tests (`flutter test` 89 tests): 30% × 100% = **30.0%**
    * Build Verification (APK debug): 20% × 100% = **20.0%**
    * Runtime E2E Automation (ARTEMIS trên device): 30% × 0% = **0.0%**
    * **Tổng điểm kiểm thử có trọng số**: 20.0% + 30.0% + 20.0% + 0.0% = **70.0%**.

### 3. Trạng thái theo rubric gốc (thang 10 điểm)

Rubric gốc chấm trực tiếp theo tám tiêu chí. Report là tài liệu bắt buộc để làm bằng chứng cho các tiêu chí khác, không có điểm riêng. Không cộng thành một tỷ lệ readiness nội bộ và không dự đoán điểm tổng khi chưa xác minh đủ evidence.

| Tiêu chí rubric | Điểm tối đa | Bằng chứng hiện có | Còn thiếu / trạng thái |
|---|---:|---|---|
| Functional requirements | 2.50 | Code 11 màn hình bắt buộc, các flow và state/error handlers; có ghi nhận một số emulator checks cũ | Chưa có evidence đầy đủ cho mọi flow, error path và yêu cầu dữ liệu; điểm cuối chưa xác định |
| Firebase integration and analytics | 2.00 | Service code, local rules và một số runtime checks trước đây | FCM delivery, Analytics DebugView, Crashlytics dashboard, Remote Config before/after, Storage upload và deployed Rules cần evidence hiện hành |
| Architecture (MVVM + Provider/Riverpod) | 0.75 | Architecture docs, Provider wiring và UI boundary trong source | Cần analyzer pass trên working tree hiện tại |
| UI/UX and application quality | 0.75 | Design tokens, reusable widgets và Semantics trong source | Figma comparison, accessibility và kích thước 360/412 dp cần evidence trực tiếp |
| Automated E2E testing (Google ARTEMIS) | 1.50 | Test plan và 26 test functions đã viết | 0 ARTEMIS runs có trace; cần ≥10 cases, mỗi case ≥3 runs, error path/native interaction/exploratory và bảng kết quả |
| AI-assisted code review | 0.50 | AI coding activity log | Chưa có review output đủ điều kiện, findings gắn file:dòng với quyết định/lý do, hoặc 3 commit fix liên kết |
| Presentation slides | 1.00 | PDF 15 trang đã sinh | Các claim “đã chạy/hoạt động” còn placeholder runtime; điểm chưa xác định |
| Demo video | 1.00 | Có kịch bản demo | Chưa có video 5–10 phút |
| **Tổng** | **10.00** |  | **Chưa chốt điểm; không tính các mục chưa xác minh là đã đạt.** |

Report PDF 10 trang và Slides PDF 15 trang đáp ứng giới hạn độ dài theo `pdfinfo`; placeholder Student ID và runtime evidence phải được thay bằng thông tin/evidence thật trước khi nộp.