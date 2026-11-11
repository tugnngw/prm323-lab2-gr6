# ARTEMIS — chẩn đoán và khắc phục 11/11/2026

Thiết bị thật: `GQDIV8HUPJWK79XC` (Redmi rodin_global). Host: `C:/Users/ADMIN/tools/artemis`,
SDK pin commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`. APK debug build từ working tree
sau các sửa đổi dưới đây, cài bằng `adb install -r` trước khi chạy.

## Nguyên nhân gốc các lượt fail trước đó

1. **TC_11 batch 10/11 17:13 (3 fail):** hạ tầng — host Artemis chưa chạy
   (`urllib` không kết nối được `/api/sessions/.../steps`) và device offline
   (`wait_for_app_entry` fail sau 0.01–0.03 s). Không phải lỗi app hay logic test.
   Bằng chứng: `results-20261110T171329048291Z.md`; khi hạ tầng khỏe TC_11 pass
   (`results-20261110T163132022648Z.md`, 41.5 s).
2. **TC_08 run2 (10/11):** test cũ assert `'tín chỉ'` trên trường `reply` do model
   paraphrase bằng tiếng Anh. Test trong working tree đã chuyển sang assert trên
   `native_visible_text` (UIAutomator hierarchy độc lập) — không phụ thuộc paraphrase.
3. **TC_08 run3 (10/11):** `TimeoutError: LLM call timed out after 180 seconds`
   (trace `f6b84536-b425-4dcd-a862-83f6ba18c7ad`, stdout.log của host). Lỗi hạ tầng model.
4. **TC_10 run1 (11/11, batch đầu):** device không phân giải được DNS.
   Logcat: `[AppCheck] Unable to resolve host firebaseappcheck.googleapis.com`,
   `[RemoteConfig] fetchAndActivate error`, Firestore chỉ đọc cache.
   `dumpsys connectivity`: `DnsAddresses: [ ]` — hotspot ICS của PC (192.168.137.x)
   không cấp DNS; `nslookup google.com 192.168.137.1` không trả lời.
   Ping IP (8.8.8.8) vẫn thông → chỉ hỏng DNS. Private DNS (dns.google) không ăn
   (DoT bị chặn), đã restore `private_dns_mode=opportunistic`.
   **Khắc phục:** người dùng đổi WiFi trên device; `ping google.com` và
   `ping firebasestorage.googleapis.com` phân giải bình thường trở lại.

## Sửa đổi app đã duyệt và áp dụng 11/11

- `lib/screens/sync_error_screen.dart`: nhận `onRetry` thật; thêm cam kết giữ dữ liệu cục bộ.
- `lib/screens/sync_vault_screen.dart`: overlay xác nhận D-01 trước đồng bộ;
  nhánh lỗi chuyển sang `SyncErrorScreen`, "Thử lại" chạy lại đồng bộ.
- `lib/main.dart`: `/sync-vault` luôn hiện khối upload PDF cloud (yêu cầu Storage Lab 3,
  không phải legacy media); `AppShell` bọc `PopScope` — Back từ tab con về Home.
- `lib/screens/tasks_screen.dart`: snackbar Undo 8 s đúng Flow 2 (SN-01).
- `lib/screens/home_screen.dart`: trạng thái loading/error/empty/data cho khối deadline.
- Accessibility: `advisor_screen.dart` IconButton ≥48 dp; `AppFontSize.caption/label/dense`
  sàn 14 sp; nhãn navigation bar 14 sp; `course_picker.dart` 14 sp; blockquote advisor 14 sp.
- Test: `test/regression_widget_test.dart` cập nhật mốc 8 s; thêm
  `test/sync_vault_flow_test.dart` (D-01 hủy/xác nhận, SyncError + Thử lại, Back về Home).
- E2E: `test_study_plan_flow.py` (TC_V1) và `test_notes_flow.py` (TC_F3_03) thêm
  "tap Xác nhận on the sync confirmation dialog if prompted" khớp D-01 mới.

## Kiểm chứng trên host

- `flutter analyze`: 0 issues.
- `flutter test`: 163/163 pass (gồm 4 test mới).
- Smoke test trước batch: TC_11 pass 35.88 s trên device thật, APK mới.

## Batch hiện tại

72 lượt (24 ca regression × 3) chạy nền sau khi DNS khôi phục; kết quả tự ghi
`results-*.json/md`. Ca exploratory (pro, 15–20 phút) chạy sau batch regression.
Lượt fail do hạ tầng (429/timeout/DNS) không tính là PASS; chẩn đoán trước khi chạy lại.

## Batch dừng vì quota Gemini (11/11 08:25)

Trace `35284c16-d019-4c6b-8b3d-5cd442ccd976` (TC_10 run1) fail sau 145.8 s, `error: null`.
`stdout.log` của host cho thấy `429 RESOURCE_EXHAUSTED`, metric
`generate_content_free_tier_requests`, **limit 20/ngày, model `gemini-3.8-flash`**,
`retryDelay 23689s` (~6 h 35 → khoảng 15:00 giờ VN). Đây là lỗi hạ tầng, không phải lỗi app;
harness dừng batch theo `session.shouldstop`.

Kết quả thật đã ghi nhận trước khi hết quota: TC_11 pass 35.86 s
(`results-20261111T011500601086Z.md`); TC_10 run1 `completed` nhưng
`upload_status: error` (`runs/test_TC_10_pdf_export_consent_upload_run1__1794359739530259400/`).

Key dự phòng: 8 key dạng `AQ.…` người dùng gửi trước đó đều gọi
`v1beta/models` trả HTTP 200 (còn sống); key AIza thứ hai trả `INVALID_ARGUMENT`;
key đang nằm trong host `.env` là key đã cạn quota. Sẽ luân chuyển key khi 429.

### Đính chính 09:15 — lỗi không phải quota ngày

Trace `2385965f-…` (08:19) in rõ metric `generate_content_free_tier_requests`,
**limit 15, mô tả "requests per minute limit", retry sau ~42 s** cho
`gemini-3.1-flash-lite` — đây là giới hạn **15 request/phút**, không phải 20/ngày
(con số 20/ngày thuộc `gemini-3.8-flash` ở trace `35284c16-…`). Vì vậy thủ phạm
chính là các call nền song song của ARTEMIS: step summarizer + video analyzer +
lens chuyển màn hình + memory, cộng thêm call chính, vượt 15 RPM ngay từ vài bước đầu.

Đã chỉnh `C:/Users/ADMIN/tools/artemis/config/artemis.jsonc` (backup
`artemis.jsonc.backup-20261111-0915`):

- `agent.flash.step_summarizer.enabled = false`
- `agent.video_analyzer.enabled = false`, `enable_ledger = false`
- `agent.memory.runtime.max_concurrency = 1`

Config hợp lệ theo `parse_llm_config()` (operator đọc đúng model sau mỗi lần sửa).

### Đính chính 09:25 — model quá tải (503) và đổi model

Sau khi giảm tải, lượt `7232cc8b-…` vẫn fail: call chính không có 429 nhưng
`503 UNAVAILABLE — "This model is currently experiencing high demand"` cho
`gemini-3.1-flash-lite`; mỗi lượt thử vượt timeout 60 s của endpoint nên runner
báo `LLM call failed (timeout)` rồi dừng ở 180 s.

Probe trực tiếp cùng key host (ảnh JPEG 277.606 byte lấy từ trace):

| Model | Text | Ảnh |
|---|---|---|
| `gemini-3.1-flash-lite` | OK 9,6 s | lỗi kết nối sau 24,8 s |
| `gemini-3.5-flash-lite` | timeout 19,1 s | timeout 20,5 s |
| `gemini-3.5-flash` | OK 2,9 s | 503 sau 4,7 s |
| `gemini-3-flash-preview` | **OK 0,9 s** | **OK 3,8 s** |
| `gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.0-flash` | 404 | 404 |

`gemini-2.x` đã bị API khóa cho tài khoản mới ("no longer available to new users").
Đã đổi `default` trong `artemis.jsonc` sang `gemini-3-flash-preview`, fallback
`gemini-3.1-flash-lite`.

Lượt `4a4bc13e-…` chạy bằng `gemini-3-flash-preview` đi được 15 bước (mở Vault,
cuộn tới nút, bấm xuất, chấp nhận consent, chờ upload) rồi mới dừng: 429
`generate_content_free_tier_requests`, **quotaValue 20/ngày**, model `gemini-3-flash`,
`retryDelay 19791 s`. Một lượt ARTEMIS tốn ~20 call nên model Flash không đủ quota
ngày cho 3 lượt; **flash-lite** mới là model phù hợp (giới hạn theo phút, không phải 20/ngày).

Probe lại 09:30 cùng key: `gemini-3.1-flash-lite` ảnh OK 2,2 s; bản
`-preview` 1,6 s; `gemini-3.5-flash-lite` 5,2 s — nghẽn 503 lúc 09:25 chỉ là tạm thời.
Cấu hình cuối: default `gemini-3.1-flash-lite`, fallback `gemini-3.5-flash-lite`.
Đây là cấu hình host test, không đổi model của tính năng AI trong app
(`gemini-3.5-flash-lite` qua Firebase AI Logic).

## TC_10: nguyên nhân gốc của upload thất bại (đã tái hiện trên device thật)

Tái hiện thủ công bằng adb trên `GQDIV8HUPJWK79XC`, APK debug mới nhất:

1. Nhánh **local chạy thật**: "Tạo PDF trên thiết bị" → consent → PDF 36.4 KB,
   UI hiện "Đã tạo PDF trên thiết bị (36.4 KB). Chưa upload cloud.",
   log `[Analytics] Logged event: export_report_local {file_size_kb: 37, course_count: 88, …}`.
   ⇒ Khâu sinh PDF không lỗi.
2. Nhánh **cloud thất bại**: consent hiện đúng TRƯỚC upload (88 môn, 0 task, 0 note),
   sau khi đồng ý ~2 s thì UI báo
   `Xuất báo cáo thất bại: [firebase_storage/object-not-found] No object exists at the desired reference.`
3. Logcat native: `StorageException … Code: -13010 HttpResult: 404`,
   `Caused by: java.io.IOException: {"error":{"code":404,"message":"Not Found."}}`
   tại `UploadTask.beginResumableUpload` ⇒ **404 ngay khi mở phiên upload**, không phải lỗi rules hay App Check.
4. Firebase console (project `prm323-lab2-gr6`, tab Storage) hiển thị:
   *"Storage requires a billing account (Blaze). Upgrade your project now…"*
   ⇒ Bucket `prm323-lab2-gr6.firebasestorage.app` khai trong `google-services.json`
   **chưa tồn tại**; project ở gói Spark nên không tạo được bucket. Đây là bằng chứng
   xác thực deviation **D-02** (trước đó mới là khẳng định, chưa kiểm chứng).

`firebase/storage.rules` đã sẵn sàng (owner-scoped, <10 MB, reports chỉ PDF) nhưng
không deploy được khi chưa có bucket.

**Hướng xử lý đã chọn (người dùng quyết định):** Cloudinary qua Media API
(`admin-web/media-server.mjs`, `REPORT_MEDIA_URL`) — đúng D-02, giảng viên cho phép
Cloudinary/AWS S3 thay thế. Không tự nâng cấp billing.

Đã sửa `e2e_test/test_export_profile.py` (TC_10): instruction gọi nút theo tiền tố
"Xuất & Tải PDF lên" vì nhãn đổi theo provider; assertion URL chấp nhận cả
`https://` (Firebase) lẫn `http://127.0.0.1:…/api/reports/…pdf` (Media API qua adb reverse),
kèm kiểm tra `/reports/` + đuôi `.pdf` để không nới lỏng thành "URL bất kỳ".

`admin-web/.env` đã có đủ `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`,
`CLOUDINARY_API_SECRET` do người dùng cung cấp; tệp bị `.gitignore` (mẫu `.env*`)
và không được in giá trị ra log/tài liệu. Media API đã chạy trên cổng 8788 và
xác minh end-to-end (xem `evidence/app/export-cloudinary-2026-11-11/verification.json`).