# ARTEMIS regression trên Pixel 7 giả lập ngày 07/11/2026

Thiết bị `emulator-5554`, AVD Pixel_7_API_35_Google_Play. APK dùng baseline `b69dc71`. Test runner đọc quan sát từ báo cáo cuối của ARTEMIS và đối chiếu hierarchy Android.

```powershell
& e2e_test/.venv/Scripts/python.exe -m pytest e2e_test/test_export_profile.py -k TC_11 --runs 3 -x --tb=short -v
```

| Ca | Lượt | Kết quả pytest | Thời gian ARTEMIS | Trace |
|---|---:|---|---:|---|
| TC_11 Remote Config | 1 | PASS | 20,34 giây | `0040c1d1-6112-4202-bd02-5d6bbe5159ec` |
| TC_11 Remote Config | 2 | PASS | 20,28 giây | `27aaad2b-b16d-4f19-a4e3-6998fd6f2518` |
| TC_11 Remote Config | 3 | PASS | 20,32 giây | `730cc9cd-fc53-4c34-adfe-2a8b4ba09680` |

TC_11 đạt 3/3 lượt. Thời gian trung bình tính theo toàn bộ ca pytest là 31,66 giây. Bản ghi gốc gồm ảnh và hierarchy có thể chứa thông tin tài khoản nên được giữ ngoài repo.

Batch bổ sung chọn 9 ca với 3 lượt mỗi ca. Trace đầu tiên `fde92d75-b434-4a61-b14e-c629410d6fdf` của TC_09 ghi 14 bước. Host lặp lỗi Gemini HTTP 429 `RESOURCE_EXHAUSTED`. Task được hủy qua SDK. Pytest ghi 1 fail do lượt bị hủy, 26 lượt chưa chạy và không có PASS mới từ batch này.
