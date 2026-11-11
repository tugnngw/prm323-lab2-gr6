# P02 · Nguyễn Minh Đức — Sinh viên năm ba ngành SE

**Trạng thái:** Proto-Persona · **Vai trò:** Primary Persona · **Phạm vi sản phẩm cốt lõi.** Hồ sơ hiện dựa trên mô tả trong project, tài liệu thiết kế và giả định nhóm; cần đối chiếu với research log trước khi gọi là finding.

## Tóm tắt

Nguyễn Minh Đức, 20 tuổi, sinh viên năm 3 ngành Kỹ thuật Phần mềm (SE), Kỳ 5. Archetype: *Sinh viên SE tra cứu tài liệu offline, theo dõi deadline và ghi nhanh khi lịch học dày.* Quote tổng hợp để minh họa nhu cầu, không phải trích dẫn phỏng vấn: “Giữa hai ca học, mình muốn xem nhanh slot hôm nay và việc đến hạn mà không phải tìm qua nhiều nơi.”

| Trường cốt lõi | Hồ sơ |
|---|---|
| **01. Identity & Archetype** | Nguyễn Minh Đức, 20 tuổi; sinh viên năm 3 SE, Kỳ 5; cần kết nối lịch môn, deadline và ghi chú học tập trên điện thoại. |
| **02. Persona Priority** | **Primary.** Tám màn hình cốt lõi và ba flow Lab 2 gốc phục vụ nhóm tác vụ này: tra cứu môn, quản lý task/note, đồng bộ Vault và hỏi AI. Các Workflow 4–6 được thêm cho nhu cầu P01/P03 mà không thay thế các tác vụ P02. |
| **03. Usage Context** | Project mô tả việc tra cứu giữa các ca học/di chuyển, trên điện thoại Android 360–412 dp; thời gian chú ý ngắn và mạng có thể chập chờn. Đây là bối cảnh thiết kế cần xác thực, không coi mọi chi tiết tần suất/thời lượng là nghiên cứu đã chứng minh. |
| **04. Goals** | 1) Tra cứu nhanh nội dung slot/đề cương đã lưu. 2) Nhìn thấy deadline tập trung và sửa được thao tác đánh dấu nhầm. 3) Ghi/tìm note Markdown, hỏi AI có nguồn khi cần. |
| **05. Job to Be Done** | Khi đang đổi phòng hoặc di chuyển và cần xem bài học/việc đến hạn, tôi muốn tìm chúng từ một nơi trên điện thoại, kể cả khi mạng yếu, để chuẩn bị đúng việc và không mất ghi chú. |
| **06. Current Behaviors** | Trong project, workflow được mô hình hóa là đọc đề cương FLM đã sync, quản lý note Markdown trong Obsidian Vault và dùng LMS cho deadline. Tần suất, thao tác thực tế và workaround cá nhân chưa có nguồn nghiên cứu gắn mã; cần kiểm chứng thay vì khẳng định là quan sát. |
| **07. Pain Points** | 1) Tìm slot/đề cương qua nhiều nơi trên màn hình nhỏ mất tập trung. 2) Deadline nằm trong nhiều ghi chú nên có nguy cơ bỏ sót. 3) Mất mạng làm gián đoạn hỏi AI/đồng bộ và có thể gây lo mất nội dung. Đây là vấn đề thiết kế giả định cần usability/research xác nhận. |
| **08. Motivations** | Tốc độ tra cứu; kiểm soát ghi chú cá nhân; biết rõ trạng thái offline/đồng bộ; có cách phục hồi khi chạm nhầm. |
| **09. Constraints** | App mobile đọc/ghi Vault cục bộ; đề cương FLM được sync sẵn, không tự cào FLM. AI cần Internet/API. Mục tiêu thao tác một tay, tiếng Việt rõ, trên Android; accessibility baseline gồm tương phản AA, chữ tối thiểu 14 sp và target 48 dp. Quyền truy cập dữ liệu phải minh bạch. |
| **10. Key Scenarios** | **Scenario A — xem môn và deadline:** giữa buổi học, mở Home, xem task sắp đến hạn, mở roadmap/course detail đã tải. **Scenario B — ghi và đồng bộ:** tạo checklist note, lưu vào Vault; nếu sync lỗi thì đọc nguyên nhân, thử lại và giữ nguyên nội dung. Đây là scenario phục vụ các flow hiện có; cần test với người dùng. |
| **11. Success Criteria** | Các chỉ số prototype đề xuất hiện trong project: **M1** mở chi tiết môn trong ≤8 giây/≤3 chạm; **M2** hoàn tất lưu note trong ≤15 giây; **M3** 5/5 người thử hoàn tác hoặc xử lý lỗi sync đúng; **M4** 5/5 hiểu lỗi AI/mạng và thử lại mà không mất câu hỏi. Chỉ báo cáo là kết quả sau khi thực sự test; hiện là target. |
| **12. Evidence & Status** | Proto-Persona, tổng hợp từ scope, Figma và tài liệu project; chưa phải statistical/validated persona. Gắn mã OBS/peer chỉ khi có ghi chú ẩn danh và ngày thực tế. Các tuyên bố về 42 note, tần suất dùng, session timeout, bus và lỗi thao tác cần xác minh nguồn. |

## Lab 2 · Tuổi, vai trò, thiết bị và accessibility

- **Tuổi/vai trò:** 20 tuổi, sinh viên năm 3 SE, Kỳ 5 (hồ sơ project hiện tại).
- **Thói quen thiết bị:** Dự án nhắm Android mobile-first; đọc/ghi sâu và chuẩn bị/sync file có thể làm trên laptop theo workflow dự kiến. Tần suất 5–8 lần/ngày và thói quen cụ thể không được xem là finding nếu không có nhật ký/quan sát xác nhận.
- **Accessibility:** Không có nhu cầu khuyết tật cá nhân nào được ghi nhận. Baseline sản phẩm: Light theme; Inter/tiếng Việt rõ, body ≥14 sp; tương phản ≥4.5:1 văn bản thường/≥3:1 chữ lớn và điều khiển; target tương tác ≥48×48 dp; trạng thái dùng icon + nhãn + màu; Auto Layout tại 360 và 412 dp. Xác minh trên UI và usability test.

## Need → UI → kiểm chứng

| Need của P02 | Giả thuyết/quyết định UI hiện có | Kiểm chứng |
|---|---|---|
| Tra cứu slot offline | `SCR-01.01_Home` → `SCR-02.01_Roadmap` → `SCR-02.02_CourseDetail`, nhãn tải về/offline | M1: thời gian và số chạm |
| Không bỏ sót việc; cứu thao tác nhầm | `SCR-03.01_Tasks`, nhóm deadline, `SN-01` Undo | Nhận diện task và hoàn tác đúng |
| Ghi note, phục hồi sync | `SCR-04.01_NoteEditor` → `SCR-04.02_Notes`; `SCR-06.01_SyncVault` → D-01 → error/retry | M2/M3: lưu, xử lý lỗi, giữ nội dung |
| Hỏi AI có căn cứ | `SCR-05.01_AdvisorHub`, giữ câu hỏi khi mất mạng, hiển thị nguồn | M4: hiểu trạng thái và phục hồi |

**Liên quan:** Tổng hợp phạm vi, research backlog và coverage matrix tại [`../persona.md`](../persona.md).
