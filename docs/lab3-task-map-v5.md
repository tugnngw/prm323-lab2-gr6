# PRM393 Lab 3 — Task Map đối chiếu Guide v5 (tối ưu từ roadmap T01–T16)

> Nguồn: `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` (14 tr.) quét chéo với
> `docs/lab3-takeover-audit.md` (roadmap T01–T16) và trạng thái code tại `107a69f`.
> Ngày rà soát: 2026-10-31.

## 0. Kết luận nhanh

- Roadmap T01–T16 **phủ đúng** các mục của guide v5, không thiếu hạng mục rubric nào.
- Guide v5 **bổ sung bắt buộc** những gì roadmap chưa nêu thành việc cụ thể:
  (1) `ai/ai-code-log.md` theo policy, (2) đặt tên evidence `SCR-/FLW-/TC-`,
  (3) cấu trúc thư mục `evidence/{firebase,artemis,code-review,report}/`,
  (4) Data minimization + consent dialog + PII filter (một phần đã có sẵn),
  (5) checklist tự đánh giá trước nộp, (6) yêu cầu repo `PRM393_Final_GR6`.
- Trạng thái: **T01, T02 xong; T03 xong M1 (device), M2 (deploy rules) còn BLOCKED.**
  T04–T16 chưa làm. Guide v5 sắp xếp lại thứ tự để **mở khoá ARTEMIS sớm** và
  **gom mọi evidence vào một batch chụp** thay vì rải rác.

## 1. Ma trận Guide v5 → Task hiện tại → Việc cụ thể còn lại

| Guide v5 | Yêu cầu | Task T- | Trạng thái code | Việc còn lại |
|---|---|---|---|---|
| §1 Firebase Project + Auth | project, SHA-1, google-services.json, Google Sign-In, rules | T03 | ✅ M1 xong (`prm323-lab2-gr6`, SHA-1 đã thêm, Google provider đã bật) | **Deploy rules** (M2, BLOCKED — cần `npx firebase-tools deploy` hoặc Console); verify sign-in trên device |
| §2 Firestore/Storage + offline | cấu trúc `users/{uid}`, Source.serverAndCache, rules, seed | T06, T13 | ✅ service + rules owner-based; ❌ rules chưa deploy | Deploy rules; sửa `storage.rules` path `notes/{u}/{f}` → recursive `**`; seed `courses`/`curriculums` lên Console (guide §2.4) |
| §3 FCM + Notification Center | token store, foreground/background/terminated, tap routing | T12 | ❌ chưa có `firebase_messaging` | Trọn gói: dep + service + `notifications` collection + rules + Notification Center screen + `POST_NOTIFICATIONS` (T05) |
| §4 Analytics/Crashlytics/RC | ≥7 events, setUserProperties, custom keys, ≥2 params, DebugView | T08–T10 | ⚠️ code có nhưng chưa wire đúng (events fire từ getter trong `build`, `setUserId`/`logLoginSuccess`/`setCustomKey` không được gọi, screen tracking off) | Wire lại theo interface; `remote-config-defaults.json`; tạo params trên Console; chụp **DebugView** (guide nhấn mạnh) |
| §5 PDF export + upload | pdf/printing, consent dialog, progress, `reports/{uid}/`, metadata | T11 | ❌ chưa có dep, chưa có gì | File picker → generate PDF từ data thật → DLG consent → upload có progress → doc metadata → event `export_report` |
| §6 ARTEMIS | env, 10–14 tests, 3 runs, traces, exploratory, evidence | T14 | ❌ chưa có gì | `e2e_test/` + `docs/test-plan.md` (ma trận TC ↔ §2.1–2.3) + chạy trên device thật + `evidence/artemis/` |
| §7 AI Code Review | PR + reviewer, 5 findings, 3 fix commits | T15 | ❌ chưa có gì | Mở PR, bật CodeRabbit/Copilot, `docs/code-review.md` + bảng decisions, 3 commit `fix(CR-0x)` |
| §8 Deliverables | report 8–12tr, slides 12–15tr, video 5–10′, README, public repo | T16 | ❌ README vẫn là Lab 2 design brief | Viết cuối kỳ; README thêm `flutter pub get / test / build apk` + ARTEMIS commands + link video |
| Policy | `ai/ai-code-log.md`, data minimization, consent, PII filter | MỚI (không có trong T-list) | ⚠️ PII filter đã có trong `firebase_analytics_service.dart`; consent dialog **chưa** | Tạo `ai/ai-code-log.md`; consent dialog gộp vào T11; log mọi phiên AI |
| Naming evidence | `SCR-`, `FLW-`, `TC-` | MỚI | ❌ chưa có `evidence/` | Áp dụng khi chụp ở T08–T16 |
| Repo naming | `PRM393_Final_GR6` | S-12 (audit) | ❌ repo đang là `prm323-lab2-gr6` | Quyết định sớm: rename repo trên GitHub hoặc xác nhận với thầy (ảnh hưởng link nộp bài) |

## 2. Plan tối ưu (đã đổi thứ tự so với T-list gốc)

**Nguyên tắc tối ưu:**
1. Việc blocking (rules deploy) làm **ngay** — mọi test Firestore đều chết permission-denied nếu thiếu.
2. Gộp T04+T05+T06残留 vào **1 commit hardening** (guide §1.4: "fail loudly, không mock im lặng").
3. Dựng ARTEMIS harness **song song** với instrumentation (không đợi xong hết mới test) —
   guide §6.2 yêu cầu test plan là "living document", và mỗi feature xong là có test chạy được ngay.
4. **Gom toàn bộ screenshot/evidence vào 1 batch** khi app chạy thật (DebugView, Crashlytics,
   RC before/after, FCM 3 trạng thái, PDF) — chụp một lần trên 1 device, đúng naming `SCR-/FLW-/TC-`.
5. AI Code Review áp vào code **đã đóng băng tính năng**, trước khi viết report (guide §7:
   findings phải được resolve trước khi tổng kết).

### Phase A — Mở khoá (0.5 ngày) [BLOCKING, làm trước tiên]
- **A1** = T03-M2: `npx firebase-tools deploy --only firestore:rules,storage --project prm323-lab2-gr6` *(user chạy tay — đã BLOCKED từ 29/10)*
- **A2** = T13: sửa `storage.rules` path `notes/` thành recursive trước khi deploy (làm luôn 1 lần với A1)
- **A3** = Seed `courses`/`curriculums` lên Firestore (guide §2.4) để Roadmap đọc dữ liệu thật
- **A4** = Verify Google Sign-In trên device với APK hiện tại (lỗi "không xác định" phải hết)

### Phase B — Hardening (0.5 ngày, 1 commit)
- **B1** = T05: `INTERNET` + `POST_NOTIFICATIONS` vào `main/AndroidManifest.xml`
- **B2** = T04: Firebase init fail → màn hình lỗi chặn, **không** fallback mock im lặng
- **B3** = Xóa no-op ternary `main.dart:94`, thống nhất 1 instance Crashlytics/RemoteConfig (S-08)
- Acceptance: `flutter build apk --release` chạy được; `aapt dump permissions` liệt kê đủ (guide §9.1)

### Phase C — Instrumentation (1 ngày, 2 commits)
- **C1** = T08: Analytics — `setUserId` + `logLoginSuccess` sau sign-in, `navigatorObservers`,
  events gọi 1 lần/action (bỏ khỏi getter/`build`), thêm `search_course`; gọi qua interface thay `is` check (S-07)
- **C2** = T09+T10: Crashlytics `setUserIdentifier` + ≥1 `setCustomKey`; Remote Config
  `firebase/remote-config-defaults.json`, enforce `maintenance_mode` + `min_app_version`
- **Evidence batch 1**: DebugView từng event, Crashlytics test crash, RC before/after *(guide §4.4, §9.2)*

### Phase D — Features lớn (2–3 ngày, song song được)
- **D1** = T11 PDF: dep `pdf`/`printing` + file picker → generate từ data thật → **consent dialog**
  (guide §5.1 + policy) → upload `reports/{uid}/study_report_<ts>.pdf` có progress → metadata → `export_report`
- **D2** = T12 FCM: `firebase_messaging` + token store `users/{uid}/tokens` + handlers 3 trạng thái
  + tap routing + Notification Center screen + collection `notifications` + rule
- **D3** = F-05/F-07 còn tồn: error branch + retry cho Advisor, task edit UI (guide §2.3 "Error branch")

### Phase E — ARTEMIS (1.5–2 ngày) [bắt đầu dựng harness từ đầu Phase C]
- **E1** = Setup: Python ≥3.12, `uv sync`, `adb devices`, API key qua `.env` (không commit) — guide §6.1
- **E2** = `docs/test-plan.md`: ma trận **TC ↔ Flow 1/2/3** (guide §6.2), 10–14 cases phủ
  happy path + error branch + recovery (guide §2.3)
- **E3** = Chạy 3 lần/test, bảng pass rate + avg duration, điều tra flaky (guide §6.3)
- **E4** = Exploratory session 15′ + AI summary → `evidence/artemis/` naming `TC-` (guide §6.4)
- **Evidence batch 2**: `FLW-` screenshots 3 flows trên device

### Phase F — AI Code Review (1 ngày)
- **F1** = Push branch → mở PR → bật CodeRabbit/Copilot (guide §7.1)
- **F2** = `docs/code-review.md`: ≥5 findings `file:line` + severity + decision Accepted/Modified/Rejected
  + **bảng decisions** (guide §7.2)
- **F3** = 3 commit `fix(CR-01..03)` độc lập, **không squash**
- **F4** = `ai/ai-code-log.md`: mọi phiên AI tool/model/prompt/output/decision *(policy bắt buộc)*

### Phase G — Đóng gói (1–1.5 ngày)
- **G1** = `evidence/` tree chuẩn guide §8: `firebase/`, `artemis/`, `code-review/`, `report/` + `README.md`
- **G2** = Report PDF 8–12tr (context, architecture, features, Firebase, testing, review, challenges)
- **G3** = Slides 12–15tr + video demo 5–10′ (sign-in → flows → sync → notification → PDF export)
- **G4** = README Lab 3: setup + run/test/build commands + ARTEMIS commands + video link + mô tả evidence
- **G5** = Checklist tự đánh giá guide §10 (12 dòng) + re-tick `LAB3_CHECKLIST.md` đúng thực tế (§2.6 audit)
- **G6** = Cắt `google-services.json` khỏi evidence (guide §9.3); quyết định rename repo §0

## 3. Tổng effort ước tính

| Phase | Effort | Phụ thuộc |
|---|---|---|
| A (mở khoá) | 0.5 ngày | **user chạy tay A1/A3** |
| B (hardening) | 0.5 ngày | A |
| C (instrumentation) | 1 ngày | B |
| D (PDF + FCM) | 2–3 ngày | B |
| E (ARTEMIS) | 1.5–2 ngày | C, D (tính năng phải xong mới test được) |
| F (AI review) | 1 ngày | code freeze sau E |
| G (đóng gói) | 1–1.5 ngày | tất cả |
| **Tổng** | **7.5–9.5 ngày** | |

## 4. Những gì guide v5 nói rõ hơn roadmap (đã merge vào plan)

1. **DebugView là evidence chuẩn của Analytics** (§4.4) — roadmap chỉ ghi "evidence"; nay chốt: chụp DebugView từng event.
2. **Test plan phải là living document** (§6.2) — cập nhật liên tục, không viết một lần cuối kỳ → E2 bắt đầu từ Phase C.
3. **Exploratory testing 15′ có AI tổng hợp** (§6.4) — mục riêng trong `evidence/artemis/`, roadmap cũ gộp chung.
4. **AI-code log theo policy** — roadmap cũ không có task này; nay là F4 (bắt buộc, thiếu là vi phạm policy nộp bài).
5. **Không commit credential/JSON** (§9.3) — `.gitignore` đã đúng, giữ nguyên; khi chụp evidence che project number/API key.
6. **Checklist tự đánh giá 12 dòng** (§10) — thêm vào G5 trước khi nộp.
7. **Repo naming `PRM393_Final_GR6`** — guide không nêu nhưng checklist Lab cũ có (S-12); quyết ở A0/G6.
