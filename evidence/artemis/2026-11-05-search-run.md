# ARTEMIS chạy lại ca tìm môn ngày 05/11/2026

Thiết bị Pixel_7_API_35_Google_Play, Android 15. Harness thu thập 76 lượt dự kiến. Bộ kiểm tra parser trên máy tính đạt 9/9.

| Lượt | Trace | Kết quả |
|---|---|---|
| Thử kết nối SDK | Chưa nhận task | SDK không kết nối được cổng 8000. Khởi động ARTEMIS host trên loopback rồi chạy lại. |
| Tìm PRM lần 1 | `25f098d6-20e6-44f2-8fc2-06916f09d3ef` | ARTEMIS thấy PRM323. Pytest fail vì bộ đọc chưa nhận các trường quan sát trực tiếp từ hành động cuối. |
| Tìm PRM lần 2 | `dcf4a01b-e5c5-4c34-bddf-ea3f37d26ec7` | ARTEMIS trả các trường trong `custom_fields`. Danh sách vẫn có mã SWP391 và SWR302, ô tìm kiếm vẫn ở trạng thái placeholder. Pytest fail. |
| Chạy lại sau khi sửa | `69255cac-414f-4e82-87f7-e93a49da152f` | Đã ghi 4 bước. Host báo Gemini HTTP 429 `RESOURCE_EXHAUSTED` và worker retry. Hủy task qua SDK sau khoảng 3 phút 35 giây. Hai lượt còn lại chưa chạy. |

Bộ đọc hiện nhận được cả hai dạng dữ liệu thực của hành động cuối và vẫn kiểm tra session, status và nội dung quan sát. Ca tìm môn đối chiếu thêm query và mã môn với hierarchy Android. Hai trace cũ được đọc lại để kiểm tra parser, kết quả pytest cũ vẫn giữ nguyên.

Không có PASS ARTEMIS mới trong đợt này. [TC_11 đã pass một lượt trước đó](results-20261105T103204181722Z.md). Batch đủ 10 ca × 3 lượt và exploratory cần quota chạy tác vụ. Các ca đăng nhập, đăng xuất và ghi dữ liệu có yêu cầu tài khoản thử riêng `@fpt.edu.vn`.
