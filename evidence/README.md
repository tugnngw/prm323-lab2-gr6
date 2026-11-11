> **Bổ sung 11/11/2026.** Luồng xuất PDF + upload Cloudinary đã tái hiện và xác minh trên máy thật; nguyên nhân lỗi cũ là Firebase Storage 404 do gói Spark. Xem mục "Bằng chứng đã xác minh" bên dưới.
>
> **Bổ sung 05/11/2026.** [Web admin đọc Crashlytics](firebase/crashlytics/admin-web-live-2026-11-05.json), [FCM server validate_only](firebase/fcm/server-http-v1-validation-2026-11-05.json), [ARTEMIS TC_11 trên giả lập](artemis/results-20261105T103204181722Z.md). Firebase giữ gói Spark. Cloudinary Free đã được kiểm tra trên giả lập. Lượt chấm trên điện thoại thật còn lại.

# Evidence — PRM393 Lab 3

## Bằng chứng đã xác minh

- [Tạo và chia sẻ PDF cục bộ](app/local-pdf-2026-11-04/verification.json)
- [Upload và tải lại qua Cloudinary, đối chiếu metadata Firestore](app/cloudinary-2026-11-05/verification.json)
- [Gemini thật, mở PDF từ lịch sử và gỡ tệp đính kèm trên Pixel 7 giả lập](app/advisor-vault-2026-11-06.json)
- [Đọc ghi chú offline và tải lại Firestore sau khi có mạng](app/offline-reconnect-2026-11-07.json)
- [Remote Config 31 → 30 trên cùng APK](firebase/remote-config/same-apk-2026-11-04.json)
- [FCM mở đúng môn học khi khởi động từ notification](firebase/fcm/deep-link-persistence-2026-11-04.json)
- [Crashlytics test crash](firebase/crashlytics/dashboard-native-crash-2026-11-04.png) và [non-fatal](firebase/crashlytics/dashboard-nonfatal-2026-11-04.png)
- [Analytics DebugView cho event tạo PDF](firebase/analytics/debugview-export-parameters-2026-11-04.png). Đối chiếu các event còn lại theo tracking plan.
- [Log SDK Analytics cho export cloud và tạo ghi chú](firebase/analytics/native-cloudinary-events-2026-11-05.json) từ lượt 05/11.
- [Tám loại event trên DebugView và tham số đối chiếu từ SDK](firebase/analytics/debugview-2026-11-07.json), gồm xuất PDF cloud và tạo ghi chú.
- [Lượt chạy ARTEMIS tìm môn, kết quả từng trace và lỗi quota](artemis/2026-11-05-search-run.md)
- [ARTEMIS TC_11 pass 3/3 lượt ngày 07/11](artemis/2026-11-07-regression.md)
- [Web deploy live, trang đăng nhập](firebase/auth/web-deploy-signin-2026-11-10.png) — `https://prm323-lab2-gr6.web.app/`, kiểm tra 10/11.
- [Remote Config bản live Version 3, 9 tham số — ảnh 1](firebase/remote-config/console-params-2026-11-10.png) và [ảnh 2](firebase/remote-config/console-params-2-2026-11-10.png) — publish từ `firebase/remote-config-template.json`.
- [App Check — tab APIs](firebase/app-check-console-2026-11-10.png) và [tab Apps sau khi đổi tên StudyPilot](firebase/app-check-apps-2026-11-10.png).
- [Crashlytics dashboard sau đổi tên](firebase/crashlytics/dashboard-2026-11-10.png) và [danh sách issue](firebase/crashlytics/issues-2026-11-10.png) — hai lỗi `reason`/`_StreamImpl.listen` được sửa cùng ngày.
- [Analytics DebugView trên Console](firebase/analytics/debugview-console-2026-11-10.png) — chụp lúc chưa có event debug.
- [Tổng hợp 10 ca ARTEMIS và phiên exploratory 08/11](artemis/2026-11-08-completion.md)
- [Xuất PDF và upload Cloudinary trên máy thật 11/11](app/export-cloudinary-2026-11-11/verification.json) — consent trước upload, 37.273 byte, Firestore ghi metadata, tải lại được; kèm [ảnh màn hình upload](app/export-cloudinary-2026-11-11/upload-success.png).
- [Tái hiện lỗi Firebase Storage 404 trên device](artemis/logs/TC-10-manual-repro-2026-11-11.log) và [chẩn đoán batch ARTEMIS 11/11](artemis/2026-11-11-diagnosis.md) — bucket không tồn tại trên gói Spark; batch dừng vì quota Gemini free tier.
- [AI review Qoder 11/11](code-review/qoder-review-2026-11-11.md) — phát hiện CR-31 (thiếu timeout khi ghi metadata Firestore), đối chiếu CR-15…CR-30, 164/164 test pass. Không có PR độc lập; công cụ và phạm vi được ghi rõ.
- Batch 5 ca ARTEMIS lúc 09:52 ngày 11/11 dừng ngay ca đầu vì thiết bị rớt khỏi ADB (`adb devices` trống); chưa có lượt nào được tính, sẽ chạy lại sau khi cắm lại cáp.


Cấu trúc theo checklist §10.1. Naming guide v5: `SCR-` (màn hình), `FLW-` (flow),
`TC-` (test case), kèm ngày `YYYY-MM-DD` trong tên file hoặc caption.
**Không** đưa `google-services.json`, API key, project number, email thật vào
screenshot/log (guide §9.3) — che trước khi lưu.

| Thư mục | Nội dung | Nguồn |
|---|---|---|
| `app/` | SCR- ảnh 11 màn hình thật trên device | checklist §6.1 |
| `firebase/auth/` | Sign-in success, Auth user Console, domain-gate reject | TC-01, TC-S-01 |
| `firebase/firestore/` | rules deployed, docs users/{uid}/…, seed catalog | TC-V1..V4 |
| `app/cloudinary-2026-11-05/` | Upload PDF báo cáo và tệp đính kèm, tải lại, metadata Firestore | Pixel 7 và Media API |
| `firebase/analytics/` | DebugView ≥7 events × ≥2 params | TC-14, TC-X-03 |
| `firebase/crashlytics/` | non-fatal + test crash, User ID + custom key | TC-X-05 |
| `firebase/remote-config/` | before/after Console, giá trị Demo Area | TC-11, TC-X-04 |
| `firebase/fcm/` | 3 trạng thái × (banner + center) = 6 ảnh + notifications doc | TC-13, TC-X-06 |
| `artemis/` | `TC-*_<run>.png`, `logs/*.log` (pass rate + trace ID), `exploratory-summary.md`, `FLW-01..03` | Phase E |
| `code-review/` | Output AI review, finding CR-xx kèm `file:line` và commit sửa | Phase F |
| `figma/` | ảnh Figma screens + dialog đã cập nhật | checklist §1.2 |
| `report/` | `report/Lab03_<StudentID>.pdf`, `slides/Lab03_<StudentID>_slides.pdf` (bản cuối đặt trong repo) | Phase G |
| `video/` | link + thumbnail video 5–10′ | Phase G |

Kết quả ARTEMIS lưu theo từng lượt. Ảnh chứa email, UID hoặc dữ liệu riêng cần được loại bỏ hoặc che trước khi đưa vào repo.
