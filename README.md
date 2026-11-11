# StudyPilot — PRM393 Final (GR6)

Hệ thống học tập một backend Firebase, hai client: **ứng dụng Android cho sinh viên** và **web quản trị cho Staff/Admin**. Đề tài nối tiếp PRM323 Lab 2 (thiết kế) và Lab 3 (ứng dụng cloud), bổ sung luồng liên vai trò, inbox realtime và tính năng AI.

Nhóm GR6: Nguyễn Sỹ Thanh Tùng · Nguyễn Bá Thái Dương · Dương Quang Long · Võ Anh Duy.

Repo nộp: <https://github.com/quanglong68/PRM393_Final_GR6>. Web admin: <https://prm323-lab2-gr6.web.app/>.

| Tài liệu | Nội dung |
|---|---|
| [docs/gap-review.md](docs/gap-review.md) | Đối chiếu Lab 2/Lab 3 với rubric Final, phần đã đóng và còn mở |
| [docs/architecture.md](docs/architecture.md) | Kiến trúc mobile + web + Firebase, MVVM, package dùng chung |
| [docs/data-model.md](docs/data-model.md) | Collection, trường, quyền theo vai trò, chuyển trạng thái |
| [docs/cross-role-flow.md](docs/cross-role-flow.md) | Sinh viên gửi bí kíp → Staff duyệt → mobile cập nhật realtime |
| [docs/ai-feature.md](docs/ai-feature.md) | Tính năng Gemini, Remote Config, App Check, fallback, 3 input/output thật |
| [docs/test-report.md](docs/test-report.md) | Kết quả test, rules, review code và bằng chứng |
| [docs/test-plan.md](docs/test-plan.md) | Ma trận 26 kịch bản E2E và điều kiện thoát |
| [docs/code-review.md](docs/code-review.md) | Finding CR-01…CR-30, quyết định và commit sửa |
| [report/Final_GR6.pdf](report/Final_GR6.pdf) | Báo cáo Final 10–15 trang |
| [slides/Final_GR6_slides.pdf](slides/Final_GR6_slides.pdf) | Slide Final 12–15 trang |

## 1. Vai trò và tài khoản demo

| Vai trò | Client | Quyền chính |
|---|---|---|
| Sinh viên (`user`) | Android | Đọc chương trình/đề cương, quản lý việc/ghi chú, gửi bí kíp và kế hoạch, dùng AI, nhận thông báo |
| Cán bộ (`staff`) | Web admin | Quản lý chuyên ngành/môn, duyệt hoặc từ chối bí kíp kèm lý do, đăng thông báo, xem dashboard |
| Quản trị (`admin`) | Web admin | Quyền của Staff + đổi `role` của tài khoản khác |

- Vai trò lưu tại `users/{uid}.role`. Tài khoản mới luôn tạo với `role: "user"`.
- **Admin đầu tiên** được đặt thủ công trong Firebase Console → Firestore → `users/{uid}` → `role: "admin"` (quy trình trong [admin-web/README.md](admin-web/README.md)).
- Demo dùng **tài khoản Google test riêng** cho từng vai trò, không dùng tài khoản cá nhân. Email/UID thật không đưa vào repo; khi chấm, đăng nhập bằng bộ tài khoản demo đã chuẩn bị và kiểm tra `role` trong Console.
- Tài khoản sai vai trò bị client từ chối kèm thông báo và tự đăng xuất.

## 2. Web admin URL

**Đã deploy:** <https://prm323-lab2-gr6.web.app/>

Bản chạy cục bộ (không cần mạng tới production): `firebase emulators:start --only hosting,firestore,auth` rồi mở `http://127.0.0.1:5000/?emulator=true`.

Khi deploy lại, chạy `firebase deploy --only hosting` và giữ domain `prm323-lab2-gr6.web.app` trong **Authentication → Settings → Authorized domains**. Đây là hạng mục G-01 trong gap review.

## 3. Chạy mobile

Yêu cầu: Flutter 3.47.4 (Dart 3.13), Android SDK, `google-services.json` hợp lệ đặt tại `android/app/` (gitignored).

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <device-id>
```

- `applicationId`: `com.example.prm323_lab3` (giữ nguyên từ Lab 3 để không phá liên kết Firebase).
- App Check dùng debug token cố định cho bản sideload/demo; bản phát hành cần Play Integrity.
- Upload tệp/PDF qua Cloudinary Media API là tùy chọn:

```bash
adb reverse tcp:8788 tcp:8788
cd admin-web && npm run start:media
flutter run -d <device-id> --dart-define=REPORT_MEDIA_URL=http://127.0.0.1:8788
```

## 4. Chạy web admin

Yêu cầu Node.js ≥ 22.

```bash
cd admin-web
npm ci
npm run dev            # http://127.0.0.1:5000, dùng Firebase production
npm test               # 14 test parser + API server
```

Hoặc chạy toàn bộ emulator từ thư mục gốc:

```bash
firebase emulators:start --only auth,firestore,hosting
```

## 5. Backend: rules, indexes, Remote Config

```bash
# Kiểm thử rules trên emulator (project demo, không đụng dữ liệu thật)
cd firebase/tests
npm ci
npx --yes firebase-tools@13.35.1 emulators:exec --only firestore \
  --project demo-second-brain-final "npm test"

# Deploy rules/indexes/Remote Config khi có quyền project
firebase deploy --only firestore:rules,firestore:indexes,remoteconfig
```

- Rules: `firebase/firestore.rules` — deny mặc định, phân quyền theo `users/{uid}.role`, kiểm tra schema và chuyển trạng thái.
- Remote Config: 9 tham số trong `firebase/remote-config-template.json` (model AI, prompt, cờ bật/tắt, bảo trì, phiên bản tối thiểu…).
- App Check bật cho Firestore và AI Logic.
- Không dùng Cloud Functions/Cloud Storage/App Hosting theo phạm vi đề.

> **Trạng thái deploy:** bản rules đã pass 15/15 test trên emulator là bản siết ngày 10/11 nhưng **chưa deploy** — release remote hiện tại vẫn là 04/11 (`evidence/firebase/firestore/rules-api-verification-2026-11-04.json`). Việc deploy nằm trong hạng mục G-09 của [gap review](docs/gap-review.md).

## 6. Kiến trúc

```text
Flutter Android ─┐
                 ├─ Firebase Auth · App Check · Firestore · AI Logic
Web admin (SPA) ─┘        │
                          └─ Firebase Hosting (tĩnh)
```

- MVVM + Provider ở cả hai client; widget không gọi SDK trực tiếp.
- Model và truy cập Firestore dùng chung nằm trong [`packages/core`](packages/core) (`study_pilot_core`).
- Trạng thái UI 4 nhánh: loading / empty / data / error, có nút thử lại.
- Không có server tùy chỉnh; Rules và App Check quyết định quyền.

Chi tiết: [docs/architecture.md](docs/architecture.md).

## 7. Phiên bản

| Thành phần | Phiên bản |
|---|---|
| Flutter / Dart | 3.47.4 / 3.13 |
| Node.js | 24.21.0 (yêu cầu ≥ 22) |
| firebase_core / auth / firestore | 5.1.0 / 7.0.1 / 7.1.0 |
| firebase_ai / app_check | 5.1.0 / 0.5.1 |
| firebase_messaging / analytics / crashlytics / remote_config | 17.0.1 / 13.0.1 / 6.0.1 / 7.0.1 |
| firebase-tools | 13.35.1 |
| Gemini model | `gemini-3.5-flash-lite` (dự phòng `gemini-3.7-flash`) |
| ARTEMIS | commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, Python 3.12 qua `uv` |

## 8. Kiểm thử

| Lớp | Kết quả | Bằng chứng |
|---|---|---|
| `flutter analyze` | 0 issue | — |
| `flutter test` | 159/159 pass | — |
| Rules emulator | 15/15 pass | `firebase/tests/final.test.mjs` |
| Web Node | 14/14 pass | `admin-web/*.test.mjs` |
| Build APK | debug + release pass | `build/app/outputs/flutter-apk/` |
| ARTEMIS | 10 ca × 3 lượt pass trên giả lập; TC_14 và exploratory chưa đạt | `evidence/artemis/` |
| AI model | 3 output hợp lệ + 1 ca lỗi | `evidence/ai/` |

Trạng thái đầy đủ và các mục còn chờ: [docs/test-report.md](docs/test-report.md).

## 9. AI tools đã dùng

- **Gemini qua Firebase AI Logic** (`gemini-3.5-flash-lite`) cho tính năng gợi ý kế hoạch học tập.
- **Qoder / Claude Code** hỗ trợ đọc code, review, viết tài liệu và sinh báo cáo/slide; mọi finding review được ghi rõ là AI hỗ trợ trong `docs/code-review.md`.
- **Google ARTEMIS** chạy E2E trên Android.
- **Firebase CLI + Emulator Suite** cho rules và hosting.

Không có API key hay service-account key trong repo. Khóa đặt trong `.env` (gitignored) hoặc Console.

## 10. Video demo

```text
<dán link video 8–12 phút>
```

Kịch bản quay: [docs/lab3-video-script.md](docs/lab3-video-script.md) — mobile flows → từng màn web → cross-role hai màn song song → AI bật/tắt bằng Remote Config → chạy test.

## 11. Cấu trúc repo

```text
├── lib/                # Mobile Flutter (screens, viewmodels, services)
├── packages/core/      # study_pilot_core: model + Firestore service dùng chung
├── admin-web/          # Web admin SPA + Media API + FCM script
├── firebase/           # rules, indexes, Remote Config template, tests
├── e2e_test/           # ARTEMIS harness
├── test/               # Unit/widget test Flutter
├── tool/               # Sinh báo cáo/slide PDF
├── docs/               # Tài liệu Final
├── evidence/           # Ảnh, JSON, trace, log
├── report/             # Final_GR6.pdf
└── slides/             # Final_GR6_slides.pdf
```

## 12. Ghi chú nộp bài

- Repo GitHub: `PRM393_Final_GR6` (đã đổi tên, hạng mục G-08).
- Web admin đã deploy tại <https://prm323-lab2-gr6.web.app/> (hạng mục G-01).
- Báo cáo và slide được sinh bằng `dart run tool/generate_final_report_pdf.dart` và `dart run tool/generate_final_slides_pdf.dart`.
- `google-services.json` và khóa bí mật không commit; clone mới cần cấu hình Firebase riêng.
- Ảnh/log trong `evidence/` đã lọc email, UID và token trước khi lưu.

## 13. Hồ sơ thiết kế Lab 2

| Hạng mục | Nội dung |
|---|---|
| Figma | [PRM323 Lab 2 — FPTU Second Brain](https://www.figma.com/design/0gpT8zQmaDiCmcklbFuTSq/PRM323_Lab2_FPTU_Second_Brain) |
| Personas | [ux/persona.md](ux/persona.md) · [ux/personas/](ux/personas/) |
| User flow | [ux/user-flow.md](ux/user-flow.md) |
| Academic workflows | [ux/academic-workflows.md](ux/academic-workflows.md) |
| Design system | [design/DESIGN.md](design/DESIGN.md) · [design/screen-spec.md](design/screen-spec.md) |
| AI design log | [ai/ai-design-log.md](ai/ai-design-log.md) |
| Flutter handoff | [handoff/flutter-handoff.md](handoff/flutter-handoff.md) |
