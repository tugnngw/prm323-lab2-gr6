# THIẾT KẾ UI/UX: QUYẾT ĐỊNH THIẾT KẾ VÀ CHECKLIST TRỢ NĂNG (WCAG 2.1 AA)

Tài liệu này tổng hợp 10 quyết định thiết kế cốt lõi được phản ánh trên 8 màn hình Lab 2 ban đầu của ứng dụng **FPTU Second Brain Mobile** (sau 3 vòng lặp tinh chỉnh với Google Stitch), kèm checklist trợ năng (WCAG 2.1 AA) và responsive 360/412 dp. Các mã ngắn trong bảng là alias lịch sử; mã Figma phân cấp có crosswalk trong screen spec. Figma hiện có thêm Workflow 4–6; các quyết định dữ liệu/quyền riêng tư được ghi ở [`ux/academic-workflows.md`](../ux/academic-workflows.md).

---

## 1. Top 10 Quyết định Thiết kế Cốt lõi (Phản ánh trực tiếp trên 8 Màn hình)

| STT | Quyết định thiết kế | Vị trí cụ thể trên giao diện thực tế | Lý do lập luận (Persona Minh Đức & Heuristic) |
| :---: | :--- | :--- | :--- |
| **01** | **Dời nút "Lưu vào Vault" xuống thanh công cụ đáy (SCR-04.01)** | Nút bấm chính màu xanh `📥 Lưu vào Vault` được chuyển xuống góc phải của thanh công cụ định dạng sát bàn phím ở đáy màn hình. | **Persona Ergonomics:** Minh Đức di chuyển bằng xe bus, chỉ dùng một tay. Việc đưa nút Lưu từ Top Bar xuống đáy màn hình giúp ngón cái bấm lưu dễ dàng mà không phải với tay lên đỉnh máy, tránh rơi điện thoại. |
| **02** | **Thống nhất hạn chót Lab 2 PRM323 và cổng nộp bài LMS** | Xuất hiện đồng bộ trên SCR-01.01 (Banner khẩn cấp), SCR-02.01 (Card PRM323), SCR-02.02 (Slot 13), SCR-03.01 (Task 2), SCR-04.01 (Callout lưu ý), SCR-04.02 (Note 3) và SCR-05.01 (Tin nhắn AI): `23:59 Hôm nay (15/10/2024) trên Hệ thống LMS`. | **Heuristic #4 (Consistency) & #5 (Error Prevention):** Sinh viên ngành phần mềm phụ thuộc hoàn toàn vào deadline. Loại bỏ mọi mâu thuẫn ngày (18/10) và tên cổng nộp (CMS/Edunext) để đảm bảo sinh viên nộp đúng hạn, đúng nơi quy định. |
| **03** | **Tách biệt Snackbar (SN-01) nằm cạnh FAB để lộ nút "HOÀN TÁC" (SCR-03.01)** | Thanh thông báo tối màu `Đã hoàn thành task` nằm ở nửa trái đáy màn hình; nút chữ `HOÀN TÁC` màu xanh sáng hiển thị trọn vẹn 100%, không bị nút FAB xanh che lấp. | **Heuristic #3 (User Control) & #9 (Error Recovery):** Xe bus rung lắc dễ khiến Đức tick nhầm checkbox hoàn thành task. Nút "HOÀN TÁC" tách biệt đóng vai trò lưới an toàn (đáp ứng tiêu chí đo lường M3 của Persona). |
| **04** | **Bổ sung Banner báo lỗi mất kết nối & Trạng thái "Chỉ đọc Vault" (SCR-05.01)** | Phía dưới Top App Bar xuất hiện banner màu vàng `Mất kết nối Internet: Trợ lý AI cần mạng để giải đáp câu hỏi mới...` đi kèm nút `↻ Thử lại` và badge cam `● Chỉ đọc Vault`. | **Heuristic #1 (Visibility of System Status) & #9 (Error Recovery):** Mạng 4G trên xe bus chập chờn. Banner thông báo rõ ràng lý do không gọi được AI, nhưng vẫn cho phép sinh viên tra cứu 42 ghi chú offline có sẵn trong máy. |
| **05** | **Minh bạch cơ chế gọi Gemini API và ô nhập API Key (SCR-06.01)** | Thêm khối `Cấu hình AI & API Key` với ô nhập `Gemini API Key` (Google AI Studio có icon ẩn/hiện key); Chân trang ghi rõ: Ghi chú lưu cục bộ 100%, chỉ câu hỏi AI mới gửi qua Gemini API. | **Heuristic #2 (Match with Real World) & Đạo đức AI:** Xóa bỏ cam kết sai lệch "xử lý 100% trong máy", công khai rõ việc dùng mô hình Gemini 1.5 Flash qua mạng theo cơ chế BYOK (Bring Your Own Key) của người dùng. |
| **06** | **Đưa nút hành động "Hỏi trợ lý AI về môn này" xuống thanh đáy (SCR-02.02)** | Ở chân màn hình SCR-02.02 gồm 2 nút lớn: Nút chính `✨ Hỏi trợ lý AI về môn này` (Filled Blue) và nút phụ `📖 Tài liệu`. | **Persona Ergonomics:** Thay vì đặt icon AI nhỏ xíu ở góc trên AppBar, nút AI được đặt ở đáy màn hình ngay trong tầm với của ngón cái để sinh viên hỏi đề cương tức thì. |
| **07** | **Bổ sung nút tạo Task trực tiếp từ Checklist Markdown (SCR-04.01)** | Trong khung "BẢN XEM TRƯỚC TRỰC TIẾP", có nút viền xanh `+ Tạo việc cần làm từ checklist này`. | **Persona Goal (Quick Capture - M2):** Cho phép Đức chuyển nhanh các tiêu chí chấm điểm của đề cương thành danh sách việc cần làm có hạn chót trên SCR-03.01 chỉ bằng một chạm. |
| **08** | **Không dùng màu sắc đơn độc để truyền tải trạng thái (Toàn bộ 8 màn)** | - Task quá hạn: Icon cảnh báo đỏ + nhãn chữ `Quá hạn`.<br>- Task hôm nay: Icon đồng hồ vàng + nhãn chữ `Hôm nay`.<br>- Môn đã tải offline: Icon đám mây + chữ `Đã tải về`.<br>- Slot học: Checkmark + `Đã hoàn thành`, Play icon + `Đang diễn ra`. | **WCAG 2.1 (Tiêu chí 1.4.1 - Use of Color):** Giúp người dùng khiếm thị màu hoặc sinh viên nhìn màn hình dưới ánh sáng chói ngoài trời vẫn phân biệt được trạng thái công việc. |
| **09** | **Loại bỏ toàn bộ các tính năng rác ngoài phạm vi (SCR-01.01 & SCR-02.01)** | Gỡ bỏ hoàn toàn Spaced Repetition (18 thẻ), Streak học tập, biểu đồ mạng lưới 128 nodes, chuông thông báo và avatar online. | **Heuristic #8 (Aesthetic & Minimalist Design):** Tập trung đúng định vị "Ứng dụng đọc Obsidian Vault và theo dõi deadline", giảm tải nhận thức và tối ưu thời gian tra cứu trong 30–60 giây của sinh viên. |
| **10** | **Khóa cấu trúc Bottom Navigation Bar 4 tab cố định (SCR-01.01, 02, 04, 06)** | Thanh điều hướng đáy cao 80 dp hiển thị cố định 4 tab: `Trang chủ`, `Lộ trình`, `Việc cần làm`, `Ghi chú`. Tab đang chọn có viên thuốc nổi bật. | **Heuristic #4 (Consistency) & Android M3:** Cung cấp trục điều hướng cấp cao nhất ổn định, giúp chuyển đổi nhanh chóng giữa xem môn học, quản lý deadline và đọc tài liệu. |

---

## 2. Bảng Checklist Kiểm tra Trợ năng (WCAG 2.1 AA)

| Tiêu chuẩn WCAG | Yêu cầu kỹ thuật | Trạng thái | Đối chiếu theo cặp màu token trong `design/DESIGN.md` |
| :--- | :--- | :---: | :--- |
| **1.4.3 Contrast (Minimum)** | Độ tương phản văn bản thường ≥ **4.5:1**; chữ lớn & điều khiển ≥ **3.0:1** | **ĐẠT THEO TOKEN** | Các cặp màu đại diện, tính theo WCAG 2.x: chữ `#0F172A` trên trắng `#FFFFFF` **17.85:1**; primary `#1D4ED8` với chữ trắng **6.70:1**; badge cảnh báo `#92400E` trên `#FEF3C7` **6.37:1**; badge lỗi `#991B1B` trên `#FEE2E2` **6.80:1**; nút nguy hiểm `#B91C1C` trên `#FEE2E2` **5.30:1**. Đây là phép tính theo token, không phải báo cáo đo từng pixel của mọi màn hình. |
| **2.5.5 Target Size** | Vùng chạm cảm ứng tối thiểu **48 × 48 dp** | **ĐẠT** | - 4 Tab Bottom Navigation Bar: Chiều cao 80 dp, mỗi ô rộng 90 dp.<br>- Floating Action Button (FAB): Đường kính tiêu chuẩn 56 × 56 dp.<br>- Checkbox trên SCR-03.01 & SCR-04.01: Icon 24 dp nhưng vùng đệm chạm đạt **48 × 48 dp**.<br>- Các nút chính (Filled Button) và hàng phím định dạng SCR-04.01 đều đạt chiều cao chuẩn 48 dp. |
| **1.4.1 Use of Color** | Không truyền đạt trạng thái chỉ bằng màu sắc | **ĐẠT** | Toàn bộ trạng thái (Quá hạn, Hôm nay, Đang diễn ra, Đã hoàn thành, Sẵn sàng offline) đều kết hợp cả Icon đặc thù và nhãn Text rõ ràng. |
| **1.4.4 Resize Text** | Cỡ chữ nội dung tối thiểu **14 sp**, phông chữ Inter rõ dấu | **ĐẠT** | - Tiêu đề màn hình: 20–22 sp bold.<br>- Tiêu đề thẻ: 16 sp semi-bold.<br>- Nội dung ghi chú, mô tả slot, chi tiết deadline: 14 sp regular (chiều cao dòng 20 sp), hiển thị tiếng Việt có dấu trọn vẹn. |

---

## 3. Bảng Kiểm tra Thích ứng Bố cục Responsive (360 dp vs 412 dp)

| Thành phần giao diện | Trạng thái hiển thị ở 360 × 800 dp (Base) | Trạng thái hiển thị ở 412 × 915 dp (Mở rộng) | Cơ chế thiết lập Figma Auto Layout |
| :--- | :--- | :--- | :--- |
| **Lề biên màn hình (Padding)** | Padding 2 bên cố định 16 dp; vùng nội dung rộng **328 dp**. | Giữ padding 16 dp; vùng nội dung tự động mở rộng thành **380 dp**. | Frame ngoài: Auto Layout dọc, Horizontal Padding = `16px`. |
| **Hệ thống thẻ (Cards)** | Chiều rộng Card cố định 328 dp, ôm sát nội dung. | Thẻ tự động dãn ngang theo chiều rộng màn hình, không bị khoảng trống thừa. | Thuộc tính thẻ: Chiều rộng set `Fill container`. |
| **Bottom Navigation Bar** | 4 tab phân bổ đều, mỗi tab chiếm độ rộng **90 dp**. | 4 tab tự động dãn đều, mỗi tab chiếm độ rộng **103 dp**, icon và nhãn căn giữa. | Thanh Bottom Nav: `Fill container`, các Tab Item con set `Fill container`. |
| **Thanh công cụ soạn thảo (SCR-04.01)** | 5 icon định dạng (B, I, T, [ ], list) và nút "Lưu" xếp gọn gàng trên 360 dp. | Khoảng cách giữa các icon định dạng tự động giãn thoáng hơn, nút Lưu vẫn neo sát phải. | Toolbar Frame: `Fill container`, thuộc tính căn chỉnh `Space between`. |
| **Xử lý tràn chữ (Text Truncation)** | Tiêu đề task hoặc ghi chú dài tự động xuống dòng tối đa 2 dòng, không cắt mất ngày hạn. | Tiêu đề hiển thị trọn vẹn trên 1 dòng do khung chứa rộng hơn. | Text layer: Chiều rộng `Fill container`, chọn chế độ `Auto height`. |
