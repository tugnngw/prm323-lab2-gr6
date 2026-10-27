# User Personas · FPTU Second Brain Mobile

> Mỗi hồ sơ persona nằm trong một file riêng. Tất cả đều là **Proto-Persona**, không phải kết quả nghiên cứu đã xác thực. Không dùng tuổi/tên để thay thế phân khúc hành vi; khác biệt chính là giai đoạn học tập, công việc cần hoàn thành và loại quyết định UI.

## Phạm vi sản phẩm

FPTU Second Brain Mobile hỗ trợ tra cứu catalog ngành/đề cương, quản lý việc học, ghi chú Markdown trong Obsidian Vault và tư vấn học vụ. Thiết kế ưu tiên P02 cho ba flow Lab 2 gốc, đồng thời bổ sung Workflow 4–6 cho nhu cầu bắt đầu chương trình của P01 và rà soát cuối khóa/chiến lược học tập của P03. Prototype hiện có 6 điểm bắt đầu. Tất cả dữ liệu cá nhân trong demo đều là dữ liệu mẫu; không tuyên bố tích hợp FLM/FAP thật.

## Hồ sơ riêng

| Mã | Persona | Vai trò trong dự án | Hồ sơ |
|---|---|---|---|
| P01 | Lê Hoàng Nam · SV năm nhất BBA, Kỳ 1 | Secondary · khám phá chương trình, hiểu môn học, hình thành kế hoạch | [P01-le-hoang-nam.md](personas/P01-le-hoang-nam.md) |
| P02 | Nguyễn Minh Đức · SV năm ba SE, Kỳ 5 | Primary · tra cứu offline, deadline, note và AI | [P02-nguyen-minh-duc.md](personas/P02-nguyen-minh-duc.md) |
| P03 | Trần Thảo Vy · SV năm cuối Ngôn ngữ Anh, Kỳ 8–9 | Secondary · prerequisite, điều kiện Capstone/OJT, học lại/cải thiện | [P03-tran-thao-vy.md](personas/P03-tran-thao-vy.md) |

Mỗi hồ sơ có đủ 12 trường theo [PRM393 Persona Guideline](https://prm393-material.web.app/persona-guideline), cùng mục Lab 2 về tuổi/vai trò, thói quen thiết bị và accessibility. Dữ liệu chưa được cung cấp được đánh dấu rõ là chưa biết/giả định. P01/P03 hiện được hỗ trợ bởi màn hình và prototype mở rộng; các kết quả cá nhân vẫn cần FAP được cấp quyền và quy tắc chính thức đúng ngành/khóa.

## Khác biệt hành vi và phạm vi thiết kế

| Persona | Công việc trọng tâm | Rào cản cần xác minh | Quyết định thiết kế / kiểm chứng |
|---|---|---|---|
| P01 | Chọn chương trình để tải, tra lộ trình/đề cương, hỏi theo môn/kỳ | Chưa quen FLM/quy chế; chưa có dữ liệu về thiết bị hay cách tra hiện tại | Workflow 4 có catalog mẫu và lộ trình; Workflow 5 có bốn cấp tư vấn. Lịch học cá nhân cần FAP tùy chọn hoặc dữ liệu mẫu; cần usability test với năm nhất. |
| P02 | Xem slot/deadline, lưu note, xử lý đồng bộ và hỏi AI | Thông tin ở nhiều nguồn, offline/AI cần phân biệt, phục hồi thao tác | 8 màn hình cốt lõi + 3 flow Lab 2; Workflow 4–6 bổ sung cơ hội mở rộng. Kiểm chứng bằng M1–M4 và usability test. |
| P03 | Rà môn nợ/prerequisite, cân nhắc học lại/cải thiện, kiểm tra sơ bộ Capstone/OJT | Cần bảng điểm/khung chương trình/quy tắc GPA chính xác; dữ liệu nhạy cảm | Workflow 4/6 có lộ trình, mô phỏng cục bộ/nhánh AI có consent và lịch dự kiến. Demo dùng dữ liệu mẫu, không kết luận trạng thái cá nhân; kiểm thử với dữ liệu/quy chế đã xác minh. |

## Vấn đề sản phẩm

Sinh viên FPTU cần tìm lại đề cương, deadline và ghi chú học tập nhanh từ nhiều nguồn, thường trên điện thoại và có thể trong điều kiện mạng không ổn định. Phạm vi hiện tại giải quyết sâu workflow của sinh viên SE năm ba (P02); nhu cầu đầu/cuối hành trình được ghi nhận để định hướng nghiên cứu tiếp theo.

## Tiêu chí kiểm thử của P02

Các con số dưới đây là **target**, không phải kết quả test đã đạt:

- **M1:** từ `SCR-01` mở `SCR-03` trong ≤8 giây và ≤3 lần chạm.
- **M2:** hoàn thành lưu ghi chú ở `SCR-05` trong ≤15 giây.
- **M3:** 5/5 người thử hoàn tác hoặc xử lý lỗi đồng bộ đúng, không mất dữ liệu.
- **M4:** 5/5 người thử hiểu lỗi kết nối AI và thử lại mà không mất câu hỏi.

## Evidence & assumption backlog

| Mã | Nội dung | Trạng thái / bước xác minh |
|---|---|---|
| SRC-01 | Mô tả P01/P03 do giảng viên cung cấp trong yêu cầu bổ sung | Reported brief; chưa có interview/observation |
| SRC-02 | Scope, flow, màn hình và giới hạn kỹ thuật của FPTU Second Brain | Project/Figma artifacts; dùng làm bằng chứng về thiết kế, không chứng minh hành vi người dùng |
| A-01 | Thiết bị, tần suất và workflow hiện tại của P01/P03 | Assumed/unknown; phỏng vấn từng nhóm |
| A-02 | Tần suất tra cứu 5–8 lần/ngày, 42 ghi chú, session timeout, bối cảnh xe bus và các workaround gắn với P02 | Chỉ giữ nếu tìm được nguồn trong research log; nếu chưa có thì không trình bày như finding |
| A-03 | Nhu cầu accessibility cá nhân | Chưa có dữ liệu; hỏi người tham gia tự nguyện, không suy đoán từ baseline UI |
| A-04 | Quy tắc điểm danh, PE/FE, prerequisite và GPA | Cần đối chiếu tài liệu FPTU chính thức đúng ngành/khóa và ngày hiệu lực trước khi đưa thành nội dung tư vấn |

### Research backlog

1. Phỏng vấn/quan sát P01 về lần gần nhất tìm đề cương, hiểu quy chế và tự xếp lịch; hỏi thiết bị/công cụ/workaround.
2. Phỏng vấn/quan sát P02 về workflow FLM/LMS/Obsidian, tần suất thực tế, mạng, lỗi và phục hồi; ghi nguồn ẩn danh, ngày và mã nghiên cứu.
3. Phỏng vấn P03 về nguồn tra cứu bảng điểm, quy trình kiểm tra prerequisite, cách tính GPA và ưu tiên tốt nghiệp/GPA; dùng dữ liệu giả lập nếu chưa được đồng ý chia sẻ dữ liệu nhạy cảm.
4. Chạy usability test cho các task trong từng hồ sơ; cập nhật success criteria bằng số liệu thực, không trình bày target thành kết quả.

## Tài liệu liên quan

- [User flow](user-flow.md)
- [Screen specification](../design/screen-spec.md)
- [Design decisions & accessibility](../design/design-decisions.md)
