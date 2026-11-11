# Chạy lại ARTEMIS với Gemini Flash-Lite ngày 07/11/2026

Pixel 7 giả lập chạy APK debug sau ba sửa lỗi review. Probe trực tiếp của cấu hình cũ Gemini 2.5 Flash trả HTTP 429 với giới hạn ngày. Gemini 3.5 Flash-Lite trả HTTP 200 với cùng key ARTEMIS. Đã sao lưu cấu hình host rồi đổi model và khởi động lại daemon.

| Ca | Kết quả pytest | Trace |
|---|---|---|
| TC_X_06 trước khi đổi model | Đã hủy sau khi probe báo hết quota ngày | `4b96783a-2149-4f30-8599-4df234236700` |
| TC_02 lượt 1 | PASS | `0a957032-8b86-44b6-8180-e0c7470c37c4` |
| TC_02 lượt 2 | PASS | `98e2693b-ce0f-40c2-9670-dc9d89a9cf5d` |
| TC_02 lượt 3 | FAIL. ARTEMIS timeout khi mở lại app | `28226745-46d9-4bee-9074-ba7ad1e6951b` |
| TC_02 chạy lại sau khi khởi động lại giả lập | PASS | `aa8ce04c-2bfd-4b2a-8668-e9db2bc84dd6` |
| TC_X_06 sau khi khởi động lại giả lập | PASS | `0d0f6a8d-a927-4049-bab8-ad97dd8dfc93` |

TC_02 hiện hướng dẫn agent quan sát màn hình mà harness đã mở. Kết quả fail ban đầu vẫn được giữ. TC_X_06 kiểm tra giao diện Trung tâm thông báo và dữ liệu hiển thị. Ca này không gửi push mới.

| Ca chạy tiếp | Pass | Fail | Trace |
|---|---:|---:|---|
| TC_X_06, hai lượt bổ sung | 2 | 0 | `64e46578-4c40-48dc-872c-e1452b6f68a6`, `f32b97e6-d461-4e93-a976-fc0d157a6d21` |
| TC_F1_01, lịch slot | 3 | 0 | `fe0913bf-e5c0-4e21-861d-25796c00d5b8`, `41bfb9b6-a18d-4e00-b259-51298c21aaee`, `f3529fec-9b8e-42d7-b715-f35ce507d4be` |
| TC_F1_04, mở Cố vấn | 3 | 0 | `d2562b92-92d1-472b-a10a-3dfabec66bc5`, `54b4d512-41f3-48af-89ed-13c03ba771ea`, `b69f7a77-c310-458a-b17c-2be229db815b` |
| TC_05, tiên quyết | 3 | 0 | `344c682a-3c94-4e87-b89f-f7d35ea60c3e`, `903bdb13-3388-4d44-ac9d-3d495f0a69bb`, `c243885c-e139-4758-989f-7f66206ba006` |
| TC_F3_03, đồng bộ Vault | 3 | 0 | `e79c68f1-c6bd-42a8-90ed-930db36596f2`, `2a071b3a-586d-4f65-8bdc-3b736ae86372`, `2f1de623-6193-44bf-9645-47d142c57440` |
| TC_F1_02, tìm môn | 3 | 0 | `d749b903-3a9f-47ec-87e0-abd57cc4beb7`, `f6340738-c827-4b1b-960a-3b85035455d5`, `c71200d2-2dd0-4877-9c9b-ca7a15b4590c` |
| TC_09, tìm kiếm rỗng | 3 | 0 | `91c7381a-27fb-46a7-b5d7-868e9a264f11`, `9dcbc2b1-8f09-4aac-89ea-115236d35f47`, `f72496c8-15a6-466e-8aab-491d316188f0` |
| TC_14, Analytics | 0 | 3 | `44e466d4-dd6e-4715-b20b-a1777ae129b2`, `9148597c-843d-4ed1-a00e-da8aa39caa50`, `e7b42638-3c5d-42cc-8bb3-d8459392dfbd` |

Tổng hợp với TC_11 Remote Config trong [lượt trước](2026-11-07-regression.md) cho thấy 9 ca có ít nhất 3 lượt PASS. Hai lượt đầu của TC_14 thiếu log `search_course`. Lượt thứ ba thất bại ở ARTEMIS trước khi đến assert log. Phiên exploratory chưa chạy.
