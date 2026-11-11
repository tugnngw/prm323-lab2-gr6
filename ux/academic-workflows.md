# Academic Workflows · FPTU Second Brain Mobile

Tài liệu này mô tả ba workflow mở rộng được bổ sung sau ba flow Lab 2 ban đầu. Đây là đặc tả sản phẩm và prototype, không phải xác nhận tích hợp hệ thống trường. Figma dùng dữ liệu minh họa; chỉ triển khai dữ liệu FLM/FAP thật qua nguồn/kênh được FPTU cấp phép.

## Nguyên tắc dữ liệu và quyền riêng tư

- **Catalog học tập:** hệ thống dự kiến đồng bộ catalog chương trình/đề cương từ nguồn FLM được phép lên cloud. Sinh viên chọn ngành/khóa muốn tải về thiết bị để tra cứu offline. Không coi việc tải catalog là kết nối tài khoản hay đồng bộ bảng điểm cá nhân.
- **Dữ liệu cá nhân:** kết nối FAP là tùy chọn, chỉ dùng qua cơ chế chính thức được trường cấp quyền. Bảng điểm, thời khóa biểu và thông tin chuyên cần lưu cục bộ theo mặc định; cho phép ngắt kết nối và xóa dữ liệu.
- **Tư vấn AI:** cần Internet. Trước mỗi lần gửi dữ liệu cá nhân, hiển thị rõ các trường và mục đích, hỏi consent mới; từ chối vẫn chạy nhánh cục bộ với dữ liệu/cache có sẵn. Không gửi tên, MSSV hay mật khẩu. Không tái sử dụng consent.
- **Nguồn học vụ:** mọi kết quả về điểm, prerequisite, điều kiện thi, Capstone và OJT phải gắn ngành/khóa, nguồn và thời điểm hiệu lực. Thiếu căn cứ thì báo chưa thể kết luận; gợi ý không thay quyết định của FAP/phòng đào tạo.
- **Prototype:** các màn hình hiện tại dùng dữ liệu mẫu/nhập thủ công có nhãn. Không có đăng nhập FAP thật, không cào dữ liệu FLM, không tính kết quả học vụ cá nhân thật.

## Workflow 4 · Thiết lập, catalog và lộ trình

**Persona chính:** P01 · Lê Hoàng Nam (năm nhất); cũng hữu ích với P03 khi rà khung ngành/khóa.

**Điểm bắt đầu:** `SCR-00.01_AuthSetup`.

| Bước | Màn hình | Hành động / kết quả |
|---|---|---|
| 1 | `SCR-00.01_AuthSetup` | Giải thích catalog học tập và FAP tùy chọn; tiếp tục không cần đăng nhập FAP. |
| 2 | `SCR-00.02_ProgramCatalog` | Xem danh sách ngành/khóa trong catalog cloud; chọn một hoặc nhiều chương trình để tải về máy. Prototype hiển thị dữ liệu mẫu và nói rõ chưa nối FLM thật. |
| 3 | `SCR-01.01_Home` | Hiển thị ngành/khóa và kỳ hiện tại như dữ liệu catalog mẫu; GPA và tín chỉ cá nhân ghi rõ cần kết nối FAP, không bịa dữ liệu khi chưa cấp quyền. |
| 4 | `SCR-02.03_Curriculum` | Xem tiến độ catalog và cây prerequisite theo ngành/khóa; có điều khiển lọc trực quan “Chỉ hiện môn tiên quyết”. Prototype dùng danh sách minh họa; không tự khẳng định môn cá nhân đã đạt. |
| 5 | `SCR-02.02_CourseDetail` | Mở chi tiết đề cương, slot, đánh giá và quan hệ môn học. |

**Nhánh tùy chọn FAP:** từ `SCR-02.03_Curriculum` mở `SCR-00.03_FAPConnect` để xem lịch/bảng điểm/chuyên cần cá nhân nếu có tích hợp chính thức. Có thể bỏ qua; nếu không có quyền tích hợp thì dùng dữ liệu mẫu hoặc quay lại lộ trình. Trên Figma, thẻ hồ sơ Home và điều khiển lọc prerequisite đã được thêm vào cả `03 Final UI` lẫn `06 Prototype`.

**Giá trị giữ chân:** năm nhất có lý do quay lại để xem catalog offline, tiến độ môn, yêu cầu từng môn và hỏi tư vấn theo cấp độ. Dữ liệu thật luôn được phân biệt bằng nguồn/trạng thái kết nối.

## Workflow 5 · Tư vấn học vụ 2.1

**Persona:** P01/P02/P03. **Điểm bắt đầu:** `SCR-05.01_AdvisorHub` (Flow 5); cũng mở được từ màn chi tiết môn/lộ trình.

AdvisorHub hiện có bốn scope chips: **Môn**, **Kỳ**, **CTĐT** (chương trình đào tạo) và **Điểm**. Prototype mặc định chọn “Môn”; người dùng chọn phạm vi trước khi hỏi.

| Cấp độ | Nội dung có thể hỏi | Ràng buộc trả lời |
|---|---|---|
| Môn học | Đề cương, slot, tài liệu, thành phần đánh giá/điều kiện môn | Dẫn syllabus đúng mã môn, phiên bản/ngày hiệu lực; không suy diễn quy chế. |
| Kỳ học | Khối lượng tín chỉ, deadline, cân bằng môn lý thuyết/dự án | Cần chương trình đúng ngành/khóa và lịch đã xác nhận; kế hoạch chỉ là gợi ý. |
| Chương trình | Lộ trình, prerequisite, Capstone, dịch vụ học vụ | Dùng curriculum chính thức đúng khóa; xác nhận thủ tục cuối tại đơn vị trường. |
| Điểm số | Tính thử điểm, phát hiện điểm/đầu mục cần chú ý, rà điều kiện cá nhân | Chỉ dùng bảng điểm FAP được cấp quyền hoặc dữ liệu mẫu gắn nhãn; không áp ngưỡng chung cho mọi môn/khóa. |

Khi mất mạng, người dùng vẫn xem được cache/câu trả lời đã lưu; câu hỏi mới cho AI cần kết nối. Mỗi trả lời phải thể hiện nguồn và giới hạn dữ liệu.

## Workflow 6 · Chiến lược học tập 2.2

**Persona chính:** P03 · Trần Thảo Vy; P02 cũng dùng được cho cân bằng nhiều môn. **Điểm bắt đầu:** `SCR-05.04_StrategySim` (Flow 6), mở từ AdvisorHub hoặc cảnh báo ở Curriculum.

1. Người dùng chọn mục tiêu/kỳ dự kiến: học lại, cải thiện điểm, cân bằng tải môn, tìm giờ trống hoặc rà điều kiện.
2. Bấm “Phân tích chiến lược” để mở overlay bắt buộc `DLG-05.04_ShareConsent`. Overlay nêu dữ liệu gửi và mục đích; dữ liệu cá nhân lưu cục bộ mặc định.
3. **Từ chối chia sẻ:** `SCR-05.05_LocalStrategyResult` tính theo dữ liệu trên thiết bị/dữ liệu mẫu và quy tắc đã xác minh. Không gửi dữ liệu lên AI. Gợi ý thời khóa biểu chỉ được đưa ra nếu có lịch cá nhân đã xác nhận trong máy; nếu không, báo thiếu dữ liệu.
4. **Đồng ý một lần:** chỉ các trường được nêu trong consent (ví dụ mã môn, điểm đã xác nhận, kỳ dự kiến) được gửi cho yêu cầu này; tên/MSSV/mật khẩu không gửi. Chuyển `SCR-05.07_StrategyLoading` trong 1,2 giây rồi đến `SCR-05.06_SharedStrategyResult`. Consent không được lưu để dùng lại.
5. Kết quả có bốn nhóm: mô phỏng điểm/học lại/cải thiện; cân bằng tải nhiều môn; gợi ý khung giờ trống từ thời khóa biểu đã xác nhận; rà soát sơ bộ điều kiện thi, prerequisite, Capstone/OJT. Nếu thiếu dữ liệu hoặc quy chế đúng ngành/khóa, hệ thống phải báo chưa thể kết luận và liên kết nguồn.

**Giá trị giữ chân P03:** hỗ trợ rà soát prerequisite và điều kiện cuối khóa, so sánh lựa chọn học lại/cải thiện và lịch dự kiến. Kết quả chỉ hỗ trợ quyết định; việc đăng ký/lịch chính thức và xác nhận đủ điều kiện thực hiện tại FAP/đơn vị trường.

## Đối chiếu Figma

| Nơi | Nội dung cần thấy |
|---|---|
| `01 User Flow` | Ba board Academic Expansion · Workflow 4/5/6, nhánh FAP tùy chọn, consent hai nhánh và nguồn/giới hạn. |
| `03 Final UI` | Các frame `SCR-00.01`, `SCR-00.02`, `SCR-00.03`, `SCR-01.01` (thẻ hồ sơ mẫu), `SCR-02.03` (điều khiển lọc prerequisite), `SCR-05.04`, `DLG-05.04`, `SCR-05.05`, `SCR-05.06`, `SCR-05.07`; AdvisorHub có selector bốn cấp. |
| `06 Prototype` | Sáu starting points tổng cộng: ba flow Lab 2 ban đầu và ba workflow mới. Home có thẻ hồ sơ mẫu, Curriculum có điều khiển lọc prerequisite; Flow 6 chạy consent → local result hoặc loading 1,2 giây → AI-supported result. |

## Nguồn tham chiếu chính thức và giới hạn

- [FPTU · Quy chế đào tạo đại học chính quy](https://daihoc.fpt.edu.vn/hoat-dong-nha-truong/tin-tuc-chung/quy-che-dao-tao-dai-hoc-chinh-quy/): chương trình tích lũy tín chỉ, yêu cầu theo chương trình/ngành và các giai đoạn học có OJT; cần kiểm tra phiên bản áp dụng cho từng khóa.
- [FPT Education Learning Materials · Cổng FLM](https://flm.fpt.edu.vn/login): trang công khai nêu mục xem curriculum/syllabus, learning path và prerequisite; quyền truy cập/dữ liệu đồng bộ hàng loạt phải được xác nhận riêng, không suy ra quyền scrape hoặc API.
- [FLM v2.0 User Guide](https://flm.fpt.edu.vn/Template/Guideline_Using_FLM_ver2.0.pdf): mô tả syllabus, curriculum, schedule và assessment trong hệ thống FLM; tài liệu hướng dẫn cũ, cần xác nhận kênh tích hợp/phiên bản hiện hành.
- [FPTU · Thông báo OJT Spring 2026](https://daihoc.fpt.edu.vn/thong-bao-huong-dan/ojt-spring-2026-thong-bao-tham-du-orientation-ojt/): ví dụ một yêu cầu tín chỉ và quy trình riêng cho kỳ OJT cụ thể. Không dùng con số/kỳ đó làm quy tắc chung cho mọi ngành/khóa.

Không tìm thấy căn cứ công khai đủ để khẳng định FAP cung cấp API cho ứng dụng bên thứ ba hoặc một ngưỡng điểm danh/điểm qua môn dùng chung. Vì vậy screen/prototype giữ nhãn mẫu, không hard-code các ngưỡng như 80% hay điểm thành phần <4.0 thành tư vấn chính thức.
