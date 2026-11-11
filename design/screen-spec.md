# ĐẶC TẢ CHI TIẾT 8 MÀN HÌNH HỆ THỐNG (SCREEN SPECIFICATIONS)

Tài liệu này quy định mục đích sử dụng, nội dung hiển thị, cấu trúc thành phần và ý đồ thiết kế của 8 màn hình cốt lõi Lab 2 cùng nhóm màn hình mở rộng Workflow 4–6 trong **FPTU Second Brain Mobile**. Ba flow gốc vẫn ưu tiên P02 · Nguyễn Minh Đức; các màn hình mở rộng bổ sung hỗ trợ P01/P03. Tất cả nội dung tích hợp học vụ trong Figma là prototype dùng dữ liệu mẫu, không khẳng định kết nối FLM/FAP thật. Xem [`ux/academic-workflows.md`](../ux/academic-workflows.md) để biết đầy đủ luồng, nguồn và ranh giới dữ liệu.

---

## Danh mục 8 Màn hình Hệ thống

| Mã màn hình | Tên màn hình | Cấp bậc điều hướng | Ánh xạ User Flow |
| :---: | :--- | :--- | :--- |
| **SCR-01.01** | Trang chủ (Dashboard) | Màn hình cấp cao nhất (Top-level Tab 1) | Flow 1, Flow 2 |
| **SCR-02.01** | Lộ trình môn học (Timeline / Semester Courses) | Màn hình cấp cao nhất (Top-level Tab 2) | Flow 1 |
| **SCR-02.02** | Chi tiết môn học (Course Details / FLM Syllabus) | Màn hình chi tiết con (Pushed from SCR-01.01/02.01) | Flow 1, Flow 1A |
| **SCR-03.01** | Việc cần làm (Tasks & Deadlines) | Màn hình cấp cao nhất (Top-level Tab 3) | Flow 2 (Có nhánh phục hồi Undo) |
| **SCR-04.01** | Soạn thảo ghi chú nhanh (Quick Note / Markdown Editor) | Màn hình độc lập (Modal / Fullscreen Editor) | Flow 2, Flow 3, Flow 1A (nguồn) |
| **SCR-04.02** | Danh sách ghi chú Vault (Vault Notes Explorer) | Màn hình cấp cao nhất (Top-level Tab 4) | Flow 3, Flow 1A (tra cứu offline) |
| **SCR-05.01** | Tư vấn học vụ / Trợ lý AI (AdvisorHub) | Màn hình hội thoại chuyên sâu (Pushed) | Flow 1A, Workflow 5 |
| **SCR-06.01** | Cài đặt & Đồng bộ Vault (Settings & Sync) | Màn hình cấu hình hệ thống (Pushed from Top Bar) | Cấu hình nền tảng / Flow 3 |

Các mã ngắn `SCR-01`…`SCR-08` còn trong phần mô tả dưới đây là bí danh lịch sử của tài liệu Lab 2 ban đầu; mã hiện hành trên Figma dùng cấu trúc phân cấp như bảng trên. Tên file PNG trong `assets/figma/` giữ nguyên theo tên export ban đầu.

---

## 1. SCR-01.01: Trang chủ (Dashboard)

- **Mục đích:** Cung cấp bức tranh toàn cảnh về tiến độ học tập trong ngày, cảnh báo tức thì các hạn chót khẩn cấp nhất, và làm điểm xuất phát truy cập nhanh vào môn học hoặc ghi chú.
- **Thuộc User Flow:** Điểm bắt đầu (Starting Point) của **Flow 1** và **Flow 2**.
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar (56 dp):** Tiêu đề ứng dụng "FPTU Second Brain Mobile", phụ đề "Học kỳ Fall 2024 (Kỳ 5)", icon bánh răng Cài đặt dẫn sang SCR-08.
  - **Thẻ định danh sinh viên:** Lời chào cá nhân hóa "Chào Minh Đức ", nhãn ngành Kỹ thuật Phần mềm, chip trạng thái `Obsidian Vault: Đã kết nối 42 ghi chú (Offline)`.
  - **Khối hạn chót khẩn cấp (Urgent Deadlines):** Thẻ task ưu tiên cao nhất: Mã môn `SWP391`, tên task `Nộp báo cáo Lab 1`, badge đỏ `Quá hạn` kèm thời gian `Hôm qua 23:59 • Hệ thống LMS`. Nút hành động `Nộp bài qua LMS`.
  - **Thẻ trạng thái Vault:** Thông báo `Obsidian Vault Sẵn Sàng` (Hoạt động ngoại tuyến 100%, 42 ghi chú, 4 đề cương FLM).
  - **Thẻ môn học đang học:** Hiển thị môn `PRM323 - Lập trình Di động Đa nền tảng`, thanh tiến độ `Slot 12/30 (40%)`, giảng viên `Huỳnh Bảo Ân`, phòng `AL-R302`, nút `Xem đề cương môn học`.
  - **Banner Trợ lý AI:** Thẻ gợi ý `Trợ lý AI môn học (Gemini 1.5 Flash)`, kèm badge vàng `Cần kết nối mạng`, nút `Đặt câu hỏi ngay`.
  - **Thẻ Việc cần làm hôm nay:** Danh sách thu gọn gồm task đã tick và task đang chờ `18:00`.
  - **Thanh tiến độ đồng bộ Vault đáy:** Thanh tiến độ xanh và nút icon đồng bộ hai chiều.
  - **Bottom Navigation Bar (80 dp):** 4 tab, tab "Trang chủ" đang kích hoạt.
  - **Floating Action Button (FAB):** Nút tròn nổi màu xanh góc phải đáy với icon cây bút ghi chú nhanh.
- **Ý đồ thiết kế:** Ưu tiên thị giác cao độ cho việc khẩn cấp (màu đỏ của task quá hạn) để Đức lập tức nắm bắt nhiệm vụ cấp bách ngay khi vừa mở app trong vòng 5 giây đầu.

---

## 2. SCR-02.01: Lộ trình môn học (Timeline / Semester Courses)

- **Mục đích:** Hiển thị tổng quan các môn học sinh viên đang theo học trong kỳ hiện tại cùng trạng thái lưu trữ ngoại tuyến của từng bộ đề cương.
- **Thuộc User Flow:** Bước trung gian của **Flow 1**.
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Nút mũi tên Back, tiêu đề màn hình "Lộ trình học tập", phụ đề chuyên ngành SE.
  - **Bộ lọc kỳ học (Chips):** Chip `Học kỳ Fall 2024 (Kỳ 5)` (đang chọn) và `Kỳ 4 (Summer 2024)`.
  - **Danh sách 4 môn học dạng thẻ dọc:**
    - `PRM323`: 3 tín chỉ, GV Huỳnh Bảo Ân, Phòng AL-R302, thanh tiến độ Slot 12/30 (40%), badge xanh lá `Đã tải về`, thẻ vàng cảnh báo `Hạn chót Lab 2: 23:59 Hôm nay (15/10/2024) trên Hệ thống LMS`, nút `Chi tiết môn học >`.
    - `SWP391`: 5 tín chỉ, Mentor Nguyễn Văn A, tiến độ Sprint 2/4 (50%), badge `Đã tải về`, nút `Chi tiết môn học >`.
    - `ITE302c`: 3 tín chỉ, tiến độ Slot 6/20 (30%), badge `Đã tải về`, nút `Chi tiết môn học >`.
    - `MAS291`: 3 tín chỉ, tiến độ Slot 24/30 (80%), badge `Đã tải về`, nút `Chi tiết môn học >`.
  - **Callout ghi nhớ thi cử:** Nền vàng nhạt nhắc nhở tài liệu đã lưu bộ nhớ đệm, có thể tra cứu ôn thi Progress Test khi mất Wi-Fi giảng đường.
  - **Bottom Navigation Bar:** Tab "Lộ trình" đang chọn. FAB tròn (+) tạo ghi chú mới.
- **Ý đồ thiết kế:** Đảm bảo khả năng xác nhận trạng thái ngoại tuyến tức thì (Heuristic #1) thông qua badge "Đã tải về" màu xanh lá trên từng môn học.

---

## 3. SCR-02.02: Chi tiết môn học (Course Details / FLM Syllabus)

- **Mục đích:** Cung cấp toàn bộ lịch trình slot học chi tiết, tài liệu và đề cương FLM của môn học cụ thể được lưu cục bộ trong máy.
- **Thuộc User Flow:** Điểm kết thúc của **Flow 1**, điểm bắt đầu của nhánh mở ghi chú/hỏi AI trong **Flow 1A** (nhánh từ Flow 1).
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Nút Back, tiêu đề môn "PRM323", phụ đề phiên bản syllabus "FLM Syllabus v2.4", nút menu ba chấm.
  - **Thẻ đầu trang:** Tên môn đầy đủ "Lập trình Di động Đa nền tảng", 3 tín chỉ, mã môn PRM323, tiến độ giáo trình 12/30 Slot (40%).
  - **Banner ngoại tuyến:** Nền vàng `#FEF3C7`: `Đang ngoại tuyến • Dữ liệu đề cương lưu cục bộ trong Vault`.
  - **Thanh 3 Tab điều hướng nội bộ:** `Lịch slot` (đang chọn), `Đánh giá`, `Tổng quan`.
  - **Danh sách tiến trình Slot:**
    - Slot 11: "Kiến trúc State Management" (Badge xanh `Đã hoàn thành`, ngày 14/10/2024, phòng AL-R302).
    - Slot 12: "HÔM NAY • Thiết kế UI Material 3 & Figma" (Badge xanh dương `Đang diễn ra`, GV Huỳnh Bảo Ân).
    - Slot 13: "Thực hành Lab • Lab 2: Usability & Handoff" (Badge đỏ nhạt `Hôm nay`, hạn nộp `23:59 Hôm nay (15/10/2024) trên Hệ thống LMS`).
    - Slot 14: "Lý thuyết • Networking & REST API" (Badge xám `Sắp tới`, dự kiến 21/10/2024).
  - **Thanh nút cố định đáy (Bottom Action Bar):** 
    - Nút chính: ` Hỏi trợ lý AI về môn này` (Filled Primary Blue - dẫn sang SCR-07).
    - Nút phụ: ` Tài liệu` (Outlined Button - dẫn sang SCR-06).
- **Ý đồ thiết kế:** Đưa nút hành động chính xuống đáy màn hình hỗ trợ công thái học ngón cái khi di chuyển trên xe bus (Ergonomics).

---

## 4. SCR-03.01: Việc cần làm (Tasks & Deadlines)

- **Mục đích:** Quản lý toàn bộ danh sách việc cần làm, bài tập Lab và deadline theo thứ tự ưu tiên, tích hợp cơ chế hoàn tác khi tick nhầm.
- **Thuộc User Flow:** Trung tâm của **Flow 2** (Flow có nhánh phục hồi lỗi Undo).
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Tiêu đề "Việc Cần Làm", icon tìm kiếm nhanh.
  - **Hàng Chip lọc trạng thái:** `Hôm nay (3)` (đang chọn), `Sắp tới (5)`, `Đã hoàn thành`.
  - **Thẻ tiến độ Sprint kỳ học:** Vòng tròn tiến độ 67%, dòng text nhắc nhở hoàn thành 2 bài Lab để duy trì 100%.
  - **Nhóm việc Khẩn cấp & Quá hạn:**
    - Task 1: Checkbox vuông đỏ, mã môn `SWP391`, badge `Quá hạn`, tên việc "Nộp báo cáo Lab 1", hạn "Hôm qua 23:59 • Hệ thống LMS".
    - Task 2: Checkbox vuông vàng, mã môn `PRM323`, badge `Hôm nay`, tên việc "Hoàn thiện Figma Prototype Lab 2", hạn "23:59 Hôm nay (15/10/2024)".
  - **Nhóm Kế hoạch tuần này:**
    - Task ITE302c (Còn 2 ngày) và Task họp nhóm SWP391 (Còn 4 ngày).
  - **Thanh thông báo nổi Snackbar (SN-01):** Nằm ở nửa trái phía trên Bottom Bar, nền đen tối `#1E293B`, icon check xanh lá, nội dung `Đã hoàn thành task`, nút chữ màu xanh sáng `HOÀN TÁC`.
  - **Floating Action Button (FAB):** Đặt cạnh phải của Snackbar, màu xanh dương với icon thêm task.
  - **Bottom Navigation Bar:** Tab "Việc cần làm" đang chọn.
- **Ý đồ thiết kế:** Đảm bảo khoảng trống an toàn tuyệt đối giữa nút "HOÀN TÁC" và FAB để người dùng không bấm nhầm lẫn khi xe bus xóc nảy.

---

## 5. SCR-04.01: Soạn thảo ghi chú nhanh (Quick Note Editor)

- **Mục đích:** Cho phép ghi chép nhanh cú pháp Markdown, lưu trực tiếp vào thư mục Vault nội bộ của máy và chuyển đổi checklist thành việc cần làm.
- **Thuộc User Flow:** Màn hình trung tâm của **Flow 3**.
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Nút mũi tên Back, tiêu đề "Soạn Thảo Ghi Chú", menu ba chấm.
  - **Thanh trạng thái phụ:** Nhãn "Ghi chú môn học", chế độ Markdown, banner xanh ngọc `Tự động lưu vào Vault cục bộ lúc 10:42 • Đã đồng bộ offline`.
  - **Hàng Tag & Phân loại:** Dropdown chọn môn `Môn: PRM323`, chip gắn thẻ `#lab2 #figma #prm323`.
  - **Vùng soạn thảo văn bản:**
    - Ô tiêu đề: "Tiêu chuẩn chấm điểm Lab 2 PRM323".
    - Thông tin meta: Thời gian cập nhật 10:42, số từ (42 từ), định dạng Markdown.
    - Khung soạn thảo code Markdown thô: Danh sách các gạch đầu dòng `[x]` và `[ ]`.
  - **Khung Xem trước trực tiếp (Live Preview):**
    - Hiển thị trực quan checklist đã render (2/4 hoàn thành), callout thông báo hạn chót nộp LMS.
    - Nút hành động: `+ Tạo việc cần làm từ checklist này` (Outlined Button bo tròn).
  - **Thanh công cụ định dạng đáy (Keyboard Toolbar):** Các nút icon thao tác nhanh gồm **B** (Đậm), *I* (Nghiêng), **T** (Tiêu đề), [x] (Checklist), List (Danh sách), và nút chính màu xanh ` Lưu vào Vault` ở góc phải.
- **Ý đồ thiết kế:** Dời nút Lưu xuống góc phải thanh công cụ đáy vừa vặn với ngón cái, loại bỏ sự lúng túng khi phải với tay lên góc trên màn hình.

---

## 6. SCR-04.02: Danh sách ghi chú Vault (Vault Notes Explorer)

- **Mục đích:** Duyệt, lọc và tìm kiếm toàn bộ các file ghi chú Markdown `.md` có trong Obsidian Vault ngoại tuyến của sinh viên.
- **Thuộc User Flow:** Điểm đến tra cứu tài liệu trong **Flow 3**.
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Icon thư mục Vault, ô tìm kiếm nhanh `Tìm trong Obsidian Vault..` tích hợp icon microphone và bộ lọc nâng cao.
  - **Thanh thư mục môn học (Horizontal Chips):** `Tất cả (42)` (đang chọn), `PRM323 (14)`, `SWP391`.
  - **Danh sách file ghi chú:**
    - Ghi chú 1: Badge `PRM323`, badge `USER NOTE`, tiêu đề `PRM323 - Tổng hợp Flutter & M3.md`, trích đoạn nội dung, tag `#mobile-dev, figma`, liên kết 4 links.
    - Ghi chú 2: Badge `SWP391`, tiêu đề `SWP391 - Biên bản họp Sprint 2.md`.
    - Ghi chú 3: Badge `LAB SPEC`, tiêu đề `PRM323 - Tiêu chuẩn chấm điểm Lab 2.md`, icon ngôi sao `Được ghim`.
  - **Callout hướng dẫn liên kết:** Thẻ vàng giải thích mẹo tạo liên kết 2 chiều `[[Tên ghi chú]]`.
  - **Bottom Navigation Bar:** Tab "Ghi chú" đang chọn. FAB tròn dấu cộng (+) màu xanh.
- **Ý đồ thiết kế:** Sử dụng cấu trúc danh sách thẻ phân cấp rõ ràng theo môn học, giúp định vị tài nguyên học tập chỉ trong 2 lần chạm.

---

## 7. SCR-05.01: Tư vấn học vụ / Trợ lý AI (AdvisorHub)

- **Mục đích:** Cung cấp giao diện hỏi đáp với mô hình Gemini 1.5 Flash dựa trên ngữ cảnh đề cương môn học và ghi chú cá nhân, có khả năng phản hồi khi mất kết nối.
- **Thuộc User Flow:** Màn hình tương tác AI trong **Flow 1A** (nhánh từ Flow 1, có xử lý lỗi mất kết nối).
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Nút mũi tên Back, tiêu đề màn hình "Trợ lý AI", phụ đề cấu hình `PRM323 • Gemini 1.5 Flash (Google AI)`.
  - **Thanh trạng thái kết nối & Ngữ cảnh:**
    - Chip ngữ cảnh: `Ngữ cảnh: PRM323 • Obsidian Vault (Offline)`.
    - Badge cảnh báo: `● Chỉ đọc Vault`.
  - **Banner xử lý lỗi mất kết nối (Error State Banner):** Nền vàng `#FEF3C7`: `Mất kết nối Internet: Trợ lý AI cần mạng để giải đáp câu hỏi mới. Bạn vẫn có thể tra cứu 42 ghi chú cục bộ trong Vault.` Đi kèm nút bấm viền `↻ Thử lại`.
  - **Lịch sử hội thoại chat:**
    - Bong bóng hỏi của sinh viên (User bubble): Màu xanh `#1D4ED8`, chữ trắng: "Cho mình hỏi Lab 2 PRM323 cần nộp những gì và hạn chót là khi nào?".
    - Bong bóng trả lời của AI (Bot bubble): Tên người gửi `AI Tutor`, nhãn model `Gemini 1.5 Flash`, phân tích gạch đầu dòng rõ ràng về Sản phẩm nộp, Tiêu chí chấm, Hạn chót `23:59 Hôm nay (15/10/2024)`.
    - Chip trích dẫn nguồn: Nền xanh ngọc nhạt ` Nguồn: PRM323_Syllabus.md` kèm icon mở file.
  - **Gợi ý câu hỏi tiếp theo (Chips):** "Check checklist nộp bài Lab 2", "Cách tính điểm".
  - **Thanh nhập liệu đáy:** Icon đính kèm tệp, ô nhập `Hỏi về môn học hoặc ghi chú...`, icon thu âm và nút tròn Gửi tin nhắn màu xanh.
- **Ý đồ thiết kế:** Phân định rạch ròi giữa việc đọc tài liệu cục bộ và việc kết nối đám mây, giúp sinh viên luôn chủ động ngay cả khi rớt mạng trên đường.

---

## 8. SCR-06.01: Cài đặt & Đồng bộ Vault (Settings & Sync)

- **Mục đích:** Quản lý đường dẫn lưu trữ Vault cục bộ trên máy Android, cấu hình Gemini API Key và theo dõi dung lượng bộ nhớ đệm offline.
- **Thuộc User Flow:** Màn hình cấu hình hỗ trợ toàn bộ hệ thống.
- **Nội dung & Thành phần hiển thị chính:**
  - **Top App Bar:** Nút Back mũi tên trái, tiêu đề "Cài đặt & Đồng bộ".
  - **Trạng thái kho lưu trữ:** Chấm xanh lá `● Obsidian Vault: Đã kết nối 42 ghi chú, 4 đề cương FLM (Sẵn sàng offline)`.
  - **Khối Đồng bộ Obsidian Vault:**
    - Hiển thị đường dẫn thư mục cục bộ `/storage/emulated/0/Documents/ObsidianVault`.
    - Nút bấm ` Chọn thư mục khác`.
    - Switch gạt bật tắt `Tự động đồng bộ một chiều khi có Wi-Fi`.
    - Nút chính màu xanh ` Đồng bộ ngay bây giờ`.
  - **Khối Cấu hình AI & API Key:**
    - Badge xanh lá `● Đã cấu hình`.
    - Nhãn `Gemini API Key` (Google AI Studio).
    - Ô nhập bảo mật `••••••••••••••••••••••••••••` có icon con mắt ẩn/hiện key.
    - Dòng mô tả nhỏ: "Dùng để gửi câu hỏi phân tích đề cương & ghi chú qua Gemini API khi có mạng".
  - **Khối Dung lượng & Bộ nhớ đệm:**
    - Thông tin tổng quan: 42 ghi chú, 4 đề cương, chiếm dụng `18.4 MB`.
    - Thanh phân bổ dung lượng: Vault 14 MB (xanh dương), Đề cương 4.4 MB (xanh teal).
    - Nút cảnh báo nguy hiểm: `🗑 Xóa cache tạm` (Chữ đỏ trên nền hồng nhạt).
  - **Khối Thông tin & Hỗ trợ:** Logo app F2B, phiên bản `v1.0.0-offline`, các liên kết hướng dẫn sử dụng, báo lỗi và chính sách riêng tư.
  - **Chân trang cam kết riêng tư:** Đoạn text minh bạch: "Ghi chú Obsidian & Đề cương FLM được lưu trữ cục bộ 100% trên thiết bị. Chỉ các truy vấn gửi tới Trợ lý AI mới được chuyển tiếp qua Gemini API...".
- **Ý đồ thiết kế:** Phân nhóm trực quan bằng các card bo tròn riêng biệt, minh bạch hóa việc bảo mật dữ liệu học tập cá nhân của sinh viên.

## 10. Màn hình mở rộng · Workflow 4–6

Các frame dưới đây nằm trên `03 Final UI` và được lặp lại/nối trong `06 Prototype`. Kích thước mobile 360 × 800 dp; nội dung dài có thể cuộn. Dữ liệu học vụ thật chỉ dùng khi có quyền tích hợp và nguồn đúng ngành/khóa.

| Mã màn hình | Persona / workflow | Mục đích, trạng thái và hành động chính |
|---|---|---|
| `SCR-00.01_AuthSetup` | P01 · Workflow 4 | Giải thích catalog học tập và FAP tùy chọn. Tiếp tục đến catalog mà không cần FAP; có thể bỏ qua kết nối. |
| `SCR-00.02_ProgramCatalog` | P01 · Workflow 4 | Catalog cloud có các ngành/khóa; người dùng chọn chương trình để tải về thiết bị. Prototype hiển thị dữ liệu mẫu, nguồn và phiên bản; không nối FLM thật. |
| `SCR-00.03_FAPConnect` | P01/P03 · Workflow 4 | Kết nối FAP qua kênh chính thức được cấp phép, không nhập mật khẩu vào app. Dữ liệu cá nhân (lịch/điểm/chuyên cần) tùy chọn, lưu cục bộ; `Để sau` quay lại Curriculum. |
| `SCR-01.01_Home` | P01/P03 · Workflow 4 | Thẻ hồ sơ minh họa ngành/khóa và kỳ hiện tại; GPA/tín chỉ cá nhân hiện yêu cầu kết nối FAP, không giả lập thành dữ liệu thật. |
| `SCR-02.03_Curriculum` | P01/P03 · Workflow 4 | Lộ trình theo ngành/khóa, cây prerequisite, trạng thái catalog tách biệt với transcript cá nhân. Có điều khiển lọc trực quan “Chỉ hiện môn tiên quyết”, lối hỏi AdvisorHub và kết nối FAP tùy chọn; nêu nguồn/phiên bản. Danh sách prototype là mẫu. |
| `SCR-05.01_AdvisorHub` | P01/P02/P03 · Workflow 5 (2.1) | Chat/tư vấn có bốn scope chip `Môn`, `Kỳ`, `CTĐT`, `Điểm`; hiển thị trạng thái mạng, nguồn và giới hạn. Scope mặc định `Môn`; CTA mở Workflow 6. |
| `SCR-05.04_StrategySim` | P03 · Workflow 6 (2.2) | Chọn mục tiêu học lại/cải thiện, cân bằng tải, giờ trống và kỳ dự kiến. Rà điều kiện thi/Capstone/OJT chỉ khi dữ liệu FAP và quy chế đúng ngành/khóa đã xác minh. |
| `DLG-05.04_ShareConsent` | P03 · Workflow 6 | Overlay bắt buộc trước khi chia sẻ; nêu rõ dữ liệu/mục đích và hỏi đồng ý theo từng lần. `Không chia sẻ` → local result; `Cho phép lần này` → loading. Không tái dùng consent. |
| `SCR-05.07_StrategyLoading` | P03 · Workflow 6 | Trạng thái chuyển tiếp sau consent, 1,2 giây trong prototype; sau đó đến kết quả AI hỗ trợ. Có hủy/quay lại chiến lược. |
| `SCR-05.05_LocalStrategyResult` | P03 · Workflow 6 | Mô phỏng cục bộ, không gửi AI; kết quả dùng dữ liệu mẫu/đã lưu và quy tắc có nguồn. Báo chưa thể kết luận nếu thiếu dữ liệu. |
| `SCR-05.06_SharedStrategyResult` | P03 · Workflow 6 | Kết quả AI chỉ dùng các trường đã cho phép trong lần đó; nêu học lại/cải thiện, cân bằng tải/khung giờ, nguồn và giới hạn. Xác nhận học vụ cuối tại FAP/đơn vị trường. |

### Phạm vi quyết định học vụ

- Không hard-code một ngưỡng điểm danh, điểm thành phần hay GPA cho mọi ngành/khóa. Dùng syllabus và quy chế có nguồn, phiên bản/ngày hiệu lực.
- Không tuyên bố đã kiểm tra đủ điều kiện thi, Capstone/OJT nếu thiếu transcript cá nhân hoặc quy chế áp dụng. Giao diện phải thể hiện “kiểm tra sơ bộ/chưa đủ căn cứ”.
- Nhánh AI chỉ chạy qua Internet và consent; nhánh từ chối chia sẻ giữ dữ liệu trên thiết bị. Catalog FLM cloud và dữ liệu cá nhân FAP là hai nguồn/luồng độc lập.
