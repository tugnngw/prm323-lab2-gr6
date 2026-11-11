> Cập nhật tiếp 04/11: 114 Flutter tests, analyzer sạch, APK/PDF cục bộ và menu chia sẻ đã xác minh. FCM ba trạng thái + cold deep link, RC 31→30 cùng APK và dashboard Crashlytics đã có evidence. Upload Storage còn thiếu bucket/billing; ARTEMIS đủ số lượt chưa đạt (quota). Chi tiết: docs/implementation-verification-2026-11-04.md.

> Cập nhật tiếp hạng mục 1–2–3 ngày 04/11/2026: xem [báo cáo xác minh mới](implementation-verification-2026-11-04.md). Đã thêm nhập dữ liệu học tập riêng, Advisor/Strategy theo dữ liệu, tab môn và route FCM. Cloud evidence/E2E vẫn có blocker thực; checklist cũ không chứng minh hoàn tất.

# PRM Lab 3 Completion Progress

**Updated:** 2026-11-04 (defect fixes pass)
**Checkout:** `main` — no Git operations performed.

## Fixes applied 2026-11-04

| File | Defect | Fix |
|---|---|---|
| `lib/models/notification_model.dart` | `receivedAt` cast to `String?` while Firestore stores `FieldValue.serverTimestamp()` → `type 'Timestamp' is not a subtype of type 'String?'` crashed the whole Notification Center on any persisted doc | `_formatReceivedAt` accepts `Timestamp` / `DateTime` / ISO string / legacy text; `route` carried on the model and through `toMap`/`copyWith`/`fromPush` |
| `lib/viewmodels/notifications_viewmodel.dart` | Foreground push dropped `route`, so a Notification Center tap could not navigate | `route` persisted with the doc; `banner` + `dismissBanner()` expose the foreground push to the shell |
| `lib/widgets/app_components.dart` | No in-app banner for a foreground push (T12 wants 3 states × banner + center) | `ForegroundPushBanner` widget |
| `lib/main.dart` | `maintenance_mode` only printed in Demo Area — never enforced | `AuthGate` renders `MaintenanceScreen` when the flag is on; "Thử lại" re-fetches and leaves the screen when maintenance ends |
| `lib/main.dart` | Shell had no banner surface | `AppShell` stacks the banner over `IndexedStack`; tap routes to the push's destination |
| `lib/screens/notifications_screen.dart` | Center cards marked read but never navigated | Card tap navigates to `item.route` when present |
| `e2e_test/conftest.py` | `require_artemis(func)` invoked a `pytest.mark.skipif` MarkDecorator as a function → `TypeError` on import of every test module | alias `require_artemis = skip_without_adb` |
| `e2e_test/test_exploratory.py` | used `pytest.mark.e2e` without `import pytest` → collection error | import added |
| `lib/services/remote_config_service.dart` | `min_app_version` displayed in Demo Area only — never enforced (M-09 gap) | `kAppVersion`, `compareVersions`, `isOutdatedVersion` (fails open on malformed input), `isVersionBelowMinimum` getter, `overrides` map for hermetic tests; in-code default `vault_sync_interval_mins` aligned to the committed JSON (was 15 vs 30) |
| `lib/main.dart` | No version gate at all | `AuthGate` is stateful: `min_app_version` block → `VersionBlockedScreen`, checked before sign-in and before `maintenance_mode`; "Thử lại" re-fetches via `fetchAndActivate()` with a spinner and a SnackBar when still blocked. `MaintenanceScreen` shares the same `onRecheck`, removing the duplicated fetch logic |

Regression coverage: `test/models/notification_model_test.dart` (7 cases: Timestamp / DateTime / ISO / legacy / missing, route in `toMap`/`copyWith`/`fromPush`) and one banner+route case in `test/viewmodels/notifications_test.dart`.

Version-gate coverage: `test/services/version_gate_test.dart` (16 cases) — below / equal / above minimum for `compareVersions`, `isOutdatedVersion`, `RemoteConfigService.isVersionBelowMinimum`; fail-open on empty and malformed `min_app_version`; in-code defaults asserted against the committed `firebase/remote-config-defaults.json`; `kAppVersion` asserted against `pubspec.yaml`; and widget tests that an outdated build is blocked before sign-in, an equal/newer build reaches the shell, sign-in still renders when nothing blocks, `maintenance_mode` still gates, and the version block wins over maintenance.

## Completed in code

- Firebase initialization fails loud with `FirebaseConfigErrorApp`; no silent mock composition.
- Authenticated UID drives user-owned reads/writes; unauthenticated writes fail closed.
- Task/note create, update, delete failures revert optimistic state and surface errors.
- PDF report generation, consent dialog, Storage upload path, Firestore metadata, progress, and analytics are wired.
- Analytics uses interface calls; rebuild-time course/prerequisite lookups are pure.
- FCM permission/token registration, token refresh persistence, foreground handling, background persistence, terminated tap routing, and Notification Center are wired.
- Notification persistence uses deterministic IDs when FCM supplies `notificationId` or `messageId`, preventing duplicate foreground rows.
- Demo Area manual sync reloads Roadmap, Tasks, and Notes from Firestore through `SyncReloadService`; success and `sync_triggered` only occur when all three stores leave reload without `ViewState.error`.
- Roadmap catalog diagnosis and safe idempotent seed procedure are documented in `docs/firestore-catalog-seed.md`; no Firebase writes were executed.
- Storage rules cover recursive note paths and PDF-only reports.
- `NoteModel.fromMap` handles Firestore `Timestamp`, `DateTime`, and legacy `String` values for `updatedAt` field.
- Google Sign-In applies `hostedDomain: 'fpt.edu.vn'` and checks the signed-in email after credential exchange; non-domain accounts are signed out and rejected (runtime rejection path not yet tested).

## Verified on emulator / device (2026-11-02)

- **Google Sign-In**: thành công, điều hướng đến HomeScreen.
- **Roadmap Firestore read**: hiển thị courses từ collection `courses`; `passedCourses` hoạt động.
- **Manual sync**: `SyncReloadService` reload cả 3 store thành công sau khi sửa `NoteModel` để parse `Timestamp`.
- **Task CRUD**: tạo task → ghi Firestore `users/{uid}/tasks/{taskId}`; toggle `isCompleted` cập nhật đúng.
- **Note CRUD**: tạo note → ghi Firestore `users/{uid}/notes/{noteId}`.
- **Delete CRUD**: hai bản ghi test đã xóa thành công.
- **Firebase project binding**: emulator sign-in and Firestore reads/writes used project `prm323-lab2-gr6`; `google-services.json` was present out-of-band and remains gitignored.

## Files changed in implementation pass

- `lib/models/note_model.dart` — `_formatUpdatedAt` xử lý Firestore `Timestamp`
- `lib/services/firestore_service.dart`
- `lib/services/firebase_firestore_service.dart`
- `lib/services/firebase_messaging_service.dart`
- `lib/viewmodels/notifications_viewmodel.dart`
- `lib/viewmodels/auth_viewmodel.dart`
- `lib/screens/sync_vault_screen.dart`
- `lib/services/sync_reload_service.dart`
- `test/models/note_model_test.dart` — NoteModel Timestamp parsing tests
- `test/helpers/fake_firestore_service.dart`
- `test/helpers/mock_firestore_service.dart`
- `test/viewmodels/notifications_test.dart`
- `test/services/sync_reload_service_test.dart`
- `docs/firestore-catalog-seed.md`
- `docs/analytics-plan.md`
- `docs/test-plan.md`
- `docs/lab3-completion-progress.md`
- `docs/lab3-final-requirement-audit.md`
- `docs/test-plan.md` — replaced stale merge-conflicted content with one consistent plan; ARTEMIS rows are explicitly planned/not run.
- `README.md` — corrected Firebase, S-10, test-count, and ARTEMIS statements; linked draft deliverables.
- `report/Lab03_DRAFT.md` — factual report source draft with evidence placeholders.
- `slides/Lab03_DRAFT.md` — 14-slide outline with runtime items marked pending.

## Progress & grading status

Rubric gốc chấm trên thang 10 điểm: Functional 2.50, Firebase 2.00, Architecture 0.75, UI/UX 0.75, ARTEMIS E2E 1.50, AI Code Review 0.50, Slides 1.00, Video 1.00. Report là tài liệu bắt buộc để mang evidence nhưng không có điểm riêng. Điểm tổng hiện **chưa chốt** vì còn tiêu chí cần runtime/Console evidence và reviewer evaluation; không dùng readiness phần trăm tự đặt làm điểm rubric.

| Tiêu chí | Max | Trạng thái evidence hiện tại |
|---|---:|---|
| Functional requirements | 2.50 | Code và một số runtime checks có ghi nhận; chưa có evidence đủ mọi flow/error path |
| Firebase integration and analytics | 2.00 | Code/local rules có; một số Console/device checks còn thiếu hoặc cần xác minh lại |
| Architecture | 0.75 | Code/docs có; analyzer phải pass trên working tree hiện tại |
| UI/UX | 0.75 | Tokens/widgets có; Figma và accessibility/device evidence còn thiếu |
| ARTEMIS E2E | 1.50 | 26 test functions có; chưa có lần chạy ARTEMIS/evidence |
| AI-assisted code review | 0.50 | Chưa có review output đáp ứng rubric và 3 linked fix commits |
| Slides | 1.00 | 15 trang; runtime evidence còn placeholder |
| Demo video | 1.00 | Chưa quay |
| **Total** | **10.00** | **Not scored yet** |

Mã nguồn local: `flutter test` gần nhất pass 89/89; analyzer vừa phát hiện và cần xử lý lỗi trong PDF extraction helper. Chạy lại analyze/test/build sau khi sửa rồi cập nhật bằng kết quả mới.
## Checks run

- `flutter analyze` — PASS, no issues (0 errors, 0 warnings).
- `flutter test` — PASS, **89 tests** (2026-11-04; version gate 16, remote config 12, PDF export 10, advisor 9, auth 8, tasks/notes 18, widgets 16).
- `flutter pub get` — PASS on 2026-11-02.
- `flutter build apk --debug` — PASS on 2026-11-02 / 2026-11-04.
- `dart run tool/verify_pdfs.dart` — PASS (Report PDF: 10 pages; Slides PDF: 15 slides).

## Submission gaps

- `report/PRM393_LAB3_GR6.pdf` (10 trang) và `slides/PRM393_LAB3_GR6.pdf` (14 slide) đáp ứng giới hạn độ dài rubric (8–12 trang và 12–15 slide).
- Định danh nộp bài dùng nhóm GR6: repo `PRM393_Final_GR6`, báo cáo `report/PRM393_LAB3_GR6.pdf`, slide `slides/PRM393_LAB3_GR6.pdf`.
