# DESIGN.md — FPTU Second Brain Mobile

Tài liệu mô tả thiết kế ban đầu đưa cho Google Stitch làm ngữ cảnh, đồng thời là nguồn gốc của Design System trong Figma (page 04, 05) và bảng token → Flutter trong handoff. Tên `SCR-xx` ở đây là alias lịch sử của bộ 8 màn hình Lab 2; mã phân cấp hiện hành và crosswalk được ghi trong `design/screen-spec.md` và `ux/user-flow.md`.

> **Cập nhật trực quan hiện hành (17/10/2026):** sau phản hồi giảng viên, Figma dùng bảng màu ngữ nghĩa có tiết chế: xanh dương `#1D4ED8` cho hành động chính; teal `#0F766E` cho Vault/ghi chú; xanh lá `#16845B` cho hoàn tất; amber `#B45309` cho cảnh báo; đỏ `#B42318` cho lỗi. Các container có sắc độ nhạt để phân biệt nhóm, nền màn hình `#F4F7FB`, card trắng. Mọi trạng thái vẫn có nhãn và icon. Bảng Token → Flutter hiện hành nằm trong `handoff/flutter-handoff.md`; bảng màu bên dưới ghi hướng thiết kế ban đầu.



---

## 0. Bối cảnh Sản phẩm (cho công cụ AI)

- **Sản phẩm:** ứng dụng Android đồng hành cho sinh viên Kỹ thuật Phần mềm FPTU: tra cứu đề cương môn học ngoại tuyến, tổng hợp deadline, ghi chú nhanh vào Obsidian Vault, hỏi trợ lý AI về ghi chú của mình.
- **Người dùng:** Nguyễn Minh Đức, 20 tuổi, thao tác một tay bằng ngón cái khi đang di chuyển, mạng thường chập chờn (xem `ux/persona.md`).
- **Phạm vi persona:** ba flow Lab 2 gốc tiếp tục phục vụ P02 · Nguyễn Minh Đức (primary). Figma được mở rộng bằng Workflow 4–6 để hỗ trợ P01 (khám phá catalog/lộ trình) và P03 (prerequisite/chiến lược cuối khóa); các màn mở rộng dùng dữ liệu mẫu.
- **Nền tảng:** di động Android, khung thiết kế chính **360 × 800 dp**, kiểm tra thêm ở **412 dp**. Chỉ **Light Theme**; dark theme nằm ngoài phạm vi.
- **8 màn hình cốt lõi Lab 2:** Trang chủ, Lộ trình, Chi tiết môn học, Việc cần làm, Soạn ghi chú, Ghi chú, Trợ lý AI, Cài đặt & Đồng bộ Vault. Figma có thêm Workflow 4–6 và 9 frame mở rộng; danh sách đầy đủ ở `design/screen-spec.md` và `ux/academic-workflows.md`. Điều hướng chính là Navigation Bar 4 mục (Trang chủ, Lộ trình, Việc cần làm, Ghi chú) kèm FAB "Ghi chú nhanh".

### Nên và không nên (dành cho Stitch)

| Nên | Không nên |
| :--- | :--- |
| Giao diện sáng, tối giản, nhiều khoảng trắng, theo Material Design 3 | Phong cách Cyberpunk, Glassmorphism, nền gradient tối của bản desktop |
| Mỗi màn hình có **một** hành động chính nổi bật | Nhiều nút Filled cạnh tranh trên cùng màn hình |
| Mọi trạng thái khẩn cấp có nhãn chữ và icon đi kèm | Chỉ dùng màu để biểu đạt trạng thái |
| Hành động chính nằm ở nửa dưới màn hình | Đặt nút quan trọng ở góc trên |
| Dữ liệu mẫu bằng tiếng Việt, mã môn thật (ví dụ PRM323) | Văn bản giả kiểu "Lorem ipsum" |


---

## 1. Phong cách Thiết kế và Giọng văn

### 1.1. Định vị thẩm mỹ
- **Phong cách chủ đạo:** Clean Academic Productivity — tinh gọn, hiện đại, nghiêm túc nhưng không gây áp lực thị giác.
- **Nguyên tắc:** Material Design 3, tối ưu cho thao tác một tay (thumb zone).
- **Theme:** Light Theme (bắt buộc theo đề bài). Độ tương phản cao để đọc được trong phòng lab và ngoài trời.

### 1.2. Giọng văn và ngôn ngữ giao diện
- **Ngắn gọn:** nhãn nút và tiêu đề 2–5 từ (ví dụ "Lưu vào Vault", "Xem sắp tới", "Tạo Task", "Hỏi AI về môn này").
- **Hướng giải pháp:** thông báo lỗi không đổ lỗi cho người dùng, nêu nguyên nhân bằng ngôn ngữ tự nhiên và luôn có nút hành động (ví dụ "Không có kết nối mạng. Bạn có thể kiểm tra Wi-Fi/4G rồi thử lại").
- **Không dùng màu đơn độc:** trạng thái và mức khẩn cấp luôn có nhãn chữ và icon ("Quá hạn", "Hôm nay", "Còn 2 ngày").
- **Định dạng ngày:** `dd/mm/yyyy`. Ngôn ngữ giao diện: tiếng Việt.


---

## 2. Color Tokens

Tỷ lệ tương phản dưới đây được **tính bằng công thức WCAG 2.x** (độ chói tương đối), không ước lượng. Ngưỡng: chữ thường ≥ 4.5:1; chữ lớn (≥ 24 sp, hoặc ≥ 19 sp in đậm) và thành phần điều khiển UI ≥ 3:1.

### 2.1. Bảng màu nền tảng

| Token | Hex | Tương phản | Vai trò | Flutter (`ColorScheme`) |
| :--- | :---: | :--- | :--- | :--- |
| `color-primary` | `#1D4ED8` | 6.70 trên trắng, 6.41 trên `color-surface` | CTA chính, trạng thái selected, viền focus | `primary` |
| `color-on-primary` | `#FFFFFF` | 6.70 trên `color-primary` | Chữ và icon trên nền primary | `onPrimary` |
| `color-primary-pressed` | `#1E40AF` | 8.72 với chữ trắng | Nền nút Filled khi nhấn | hằng số tùy biến |
| `color-primary-container` | `#DBEAFE` | — (nền); icon primary trên nền này 5.49 | Chip được chọn, indicator của tab, thẻ nổi bật | `primaryContainer` |
| `color-on-primary-container` | `#1E3A8A` | 8.49 trên `color-primary-container` | Chữ và icon trên container | `onPrimaryContainer` |
| `color-secondary` | `#0F766E` | 5.47 trên trắng, 5.23 trên `color-surface` | Điểm nhấn ghi chú cá nhân | `secondary` |
| `color-secondary-container` | `#CCFBF1` | — (nền) | Nền huy hiệu USER NOTE | `secondaryContainer` |
| `color-on-secondary-container` | `#115E59` | 6.73 trên `color-secondary-container` | Chữ huy hiệu USER NOTE | `onSecondaryContainer` |
| `color-surface` | `#F8FAFC` | — (nền) | Nền chính của màn hình | `surface` |
| `color-surface-container` | `#FFFFFF` | — (nền) | Nền Card, Bottom Sheet, Dialog, Text Field | `surfaceContainerLowest` |
| `color-surface-container-high` | `#F1F5F9` | — (nền) | Nền phân vùng nhẹ, Card khi nhấn, huy hiệu trung tính | `surfaceContainerHigh` |
| `color-on-surface` | `#0F172A` | 17.06 trên `color-surface` | Chữ chính | `onSurface` |
| `color-on-surface-variant` | `#475569` | 7.24 trên `color-surface`, 6.92 trên `color-surface-container-high` | Chữ phụ, placeholder, icon không chọn | `onSurfaceVariant` |
| `color-outline` | `#64748B` | 4.76 trên trắng, 4.55 trên `color-surface` | **Viền điều khiển** (Text Field, Outlined Button) | `outline` |
| `color-outline-variant` | `#CBD5E1` | 1.42 (chỉ trang trí) | Divider, viền Card. **Không dùng** cho viền ô nhập hoặc nút | `outlineVariant` |
| `color-disabled-container` | `#E2E8F0` | — | Nền thành phần bị vô hiệu | hằng số tùy biến |
| `color-on-disabled` | `#94A3B8` | 2.08 (đối tượng bị vô hiệu được miễn WCAG) | Chữ và icon bị vô hiệu | hằng số tùy biến |
| `color-skeleton` | `#E2E8F0` | — | Khối skeleton khi tải | hằng số tùy biến |
| `color-scrim` | `#0F172A`, độ mờ 40% | — | Lớp phủ sau Dialog và Bottom Sheet | `scrim` |
| `color-inverse-surface` | `#1E293B` | — | Nền Snackbar | `inverseSurface` |
| `color-inverse-on-surface` | `#F8FAFC` | 13.98 trên `color-inverse-surface` | Chữ Snackbar | `onInverseSurface` |
| `color-inverse-primary` | `#93C5FD` | 8.11 trên `color-inverse-surface` | Nút hành động trên Snackbar (HOÀN TÁC, Xem) | `inversePrimary` |

Viền focus của Text Field dùng lại `color-primary` (không cần token riêng).

### 2.2. Màu ngữ nghĩa

Màu gốc (`error`, `warning`, `success`) dùng cho icon, viền và chỉ báo. **Chữ nằm trên nền container luôn dùng `on-*-container`.**

| Token | Hex | Tương phản | Nhãn chữ bắt buộc đi kèm | Ứng dụng |
| :--- | :---: | :--- | :--- | :--- |
| `color-error` | `#DC2626` | 4.83 trên trắng, 4.62 trên `color-surface`, 3.95 trên `color-error-container` | "Quá hạn", "Lỗi kết nối", "Không thể lưu" | Icon lỗi, viền Text Field lỗi, chữ hành động nguy hiểm trên nền trắng |
| `color-error-container` | `#FEE2E2` | — | — | Nền huy hiệu Quá hạn, banner lỗi |
| `color-on-error-container` | `#991B1B` | 6.80 trên `color-error-container` | — | Chữ trên nền lỗi |
| `color-warning` | `#B45309` | 5.02 trên trắng, 4.51 trên `color-warning-container` | "Hôm nay", "Còn 1 ngày", "Đang ngoại tuyến" | Icon cảnh báo hạn gấp (≤ 3 ngày) |
| `color-warning-container` | `#FEF3C7` | — | — | Nền huy hiệu hạn gấp, banner ngoại tuyến |
| `color-on-warning-container` | `#92400E` | 6.37 trên `color-warning-container` | — | Chữ trên nền cảnh báo |
| `color-success` | `#15803D` | 5.02 trên trắng, 4.57 trên `color-success-container` | "Đã hoàn thành", "Đã tải về", "Đã lưu" | Icon trạng thái thành công |
| `color-success-container` | `#DCFCE7` | — | — | Nền huy hiệu FLM SYNC, trạng thái đã hoàn thành |
| `color-on-success-container` | `#166534` | 6.49 trên `color-success-container` | — | Chữ trên nền thành công |

### 2.3. Quy tắc nhãn Deadline (không dùng màu đơn độc)

| Trạng thái | Nhãn chữ | Icon | Nền | Chữ và icon |
| :--- | :--- | :--- | :--- | :--- |
| Quá hạn | "Quá hạn" | `error` | `color-error-container` | `color-on-error-container` |
| Hôm nay | "Hôm nay" | `schedule` | `color-warning-container` | `color-on-warning-container` |
| Còn 1–3 ngày | "Còn N ngày" | `schedule` | `color-warning-container` | `color-on-warning-container` |
| Còn 4–7 ngày | "Còn N ngày" | `event` | `color-primary-container` | `color-on-primary-container` |
| Còn trên 7 ngày | "Còn N ngày" | `event` | `color-surface-container-high` | `color-on-surface-variant` |
| Đã hoàn thành | "Đã hoàn thành", tên việc **gạch ngang** | `check_circle` | `color-success-container` | `color-on-success-container` |

### 2.4. Quy tắc nhãn Môn học và File

| Đối tượng | Nhãn chữ | Icon | Nền | Chữ và icon |
| :--- | :--- | :--- | :--- | :--- |
| Môn chưa có dữ liệu | "Chưa có tài liệu" | `insert_drive_file` (viền) | `color-surface-container-high` | `color-on-surface-variant` |
| Môn đã tải đề cương | "Đã tải về" | `download_done` | `color-success-container` | `color-on-success-container` |
| Môn AI đã phân tích | "AI đã phân tích" | `auto_awesome` | `color-primary-container` | `color-on-primary-container` |
| File đề cương trường | "FLM SYNC" | `school` | `color-success-container` | `color-on-success-container` |
| File người dùng tự viết | "USER NOTE" | `edit_note` | `color-secondary-container` | `color-on-secondary-container` |

### 2.5. Lý do chọn xanh dương thay cho cam FPT của bản desktop

Màu cam FPT `#F26F21` chỉ đạt **2.97:1** với nền trắng (cũng 2.97:1 với chữ trắng trên nền cam), thấp hơn ngưỡng 4.5:1 cho chữ thường nên không thể dùng làm nền nút Filled có chữ trắng hoặc làm màu chữ. Bản mobile dùng `color-primary` `#1D4ED8` (6.70:1). Cam FPT có thể xuất hiện ở logo hoặc hình minh họa, không dùng cho chữ và điều khiển.


---

## 3. Typography Tokens

- **Phông chữ:** `Inter` (dự phòng `Roboto`). Inter hỗ trợ đầy đủ dấu tiếng Việt.
- **Dấu tiếng Việt xếp chồng** (ví dụ "ệ", "ử") cần chiều cao dòng đủ lớn; không cắt chữ khi đặt `height` của `TextStyle`, và không đặt chiều cao cố định cho khối chữ.
- **Cỡ chữ tối thiểu 14 sp** cho mọi nội dung (đề Lab 2, mục 7). **Ngoại lệ duy nhất:** nhãn dưới icon của Navigation Bar dùng 12 sp theo chuẩn M3; mỗi màn hình cấp 1 luôn lặp lại tên đích đến ở tiêu đề màn hình (≥ 22 sp) nên thông tin không phụ thuộc vào nhãn này.
- **Chữ lớn (theo WCAG):** từ 24 sp trở lên, hoặc từ 19 sp trở lên nếu in đậm. `type-title-large` (18 sp) **không** được coi là chữ lớn và phải đạt 4.5:1.

| Token | Cỡ | Độ đậm | Chiều cao dòng | Vị trí áp dụng | Flutter (`TextTheme`) |
| :--- | :---: | :---: | :---: | :--- | :--- |
| `type-headline-large` | 28 sp | Bold 700 | 34 sp | Lời chào và tiêu đề lớn ở Trang chủ | `headlineLarge` |
| `type-headline-medium` | 22 sp | SemiBold 600 | 28 sp | Tiêu đề màn hình cấp 1 (Lộ trình, Việc cần làm, Ghi chú) | `headlineMedium` |
| `type-title-large` | 18 sp | SemiBold 600 | 24 sp | Tiêu đề Card môn, tên học kỳ, tiêu đề AppBar cấp 2 | `titleLarge` |
| `type-title-medium` | 16 sp | Medium 500 | 22 sp | Tên việc, tiêu đề slot, câu hỏi người dùng | `titleMedium` |
| `type-body-large` | 16 sp | Regular 400 | 24 sp | Nội dung ghi chú Markdown, câu trả lời của AI | `bodyLarge` |
| `type-body-medium` | 14 sp | Regular 400 | 20 sp | Mô tả slot, đề cương, thông báo lỗi, chữ hỗ trợ dưới ô nhập | `bodyMedium` |
| `type-body-semibold` | 14 sp | SemiBold 600 | 20 sp | Nhãn trạng thái ("Quá hạn", "FLM SYNC") | `bodyMedium` ghi đè `fontWeight` |
| `type-label-large` | 14 sp | Medium 500 | 20 sp | Chữ trên nút, chip, tab nội bộ | `labelLarge` |
| `type-label-small` | 12 sp | Medium 500 | 16 sp | **Chỉ** nhãn Navigation Bar | `labelSmall` |

Thời gian đồng bộ, số slot và các chú thích khác dùng `type-body-medium` (14 sp).


---

## 4. Spacing và Layout Tokens

Lưới cơ sở 4 dp, nhịp chính 8 dp (mọi giá trị là bội của 4).

### 4.1. Khoảng cách

| Token | Giá trị | Ứng dụng |
| :--- | :---: | :--- |
| `spacing-2xs` | 4 dp | Giữa icon và chữ trong Chip, Badge |
| `spacing-xs` | 8 dp | Giữa các chip; **khoảng cách tối thiểu giữa hai vùng chạm liền kề** |
| `spacing-sm` | 12 dp | Giữa các dòng trong Card |
| `spacing-md` | 16 dp | Padding trong Card, giữa các khối danh sách, lề màn hình ở 360 dp |
| `spacing-lg` | 20 dp | Giữa các section lớn, lề màn hình ở 412 dp |
| `spacing-xl` | 24 dp | Padding Dialog và Bottom Sheet |
| `spacing-2xl` | 32 dp | Đầu màn hình, khoảng trống của Empty State |

### 4.2. Khung màn hình
- **Khung thiết kế chính:** 360 × 800 dp (theo đề Lab 2). **Kiểm tra bố cục:** 412 dp.
- **Lề ngang:** 16 dp ở 360 dp; 20 dp ở 412 dp.
- **Vùng an toàn:** dùng `SafeArea` / `MediaQuery.padding` của hệ thống, không cố định số.
- **Màn rộng từ 600 dp trở lên** (không thiết kế, chỉ mô tả trong handoff): Navigation Bar chuyển thành Navigation Rail và nội dung giới hạn chiều rộng.


---

## 5. Bo góc và Độ nổi

### 5.1. Bo góc

| Token | Giá trị | Áp dụng |
| :--- | :---: | :--- |
| `radius-xs` | 4 dp | Checkbox, thanh tiến độ |
| `radius-sm` | 8 dp | Text Field, thumbnail |
| `radius-md` | 12 dp | Card môn, Card việc, banner |
| `radius-lg` | 16 dp | Dialog, Card carousel nổi bật, **FAB** |
| `radius-xl` | 24 dp | Hai góc trên của Bottom Sheet |
| `radius-full` | 999 dp | **Button**, Chip, Badge |

### 5.2. Độ nổi

| Token | Độ cao | Đổ bóng | Áp dụng |
| :--- | :---: | :--- | :--- |
| `elevation-0` | 0 dp | Không đổ bóng, viền `color-outline-variant` | Card mặc định, nền màn hình |
| `elevation-1` | 1 dp | `0 1px 3px rgba(15,23,42,0.08)` | AppBar khi cuộn, Card khi được kéo lên |
| `elevation-2` | 3 dp | `0 4px 6px -1px rgba(15,23,42,0.10)` | FAB |
| `elevation-3` | 6 dp | `0 10px 15px -3px rgba(15,23,42,0.12)` | Bottom Sheet, Dialog, Snackbar |


---

## 6. Component

Tất cả component dựng bằng **Auto Layout** và **Variants**. Mọi giá trị màu, cỡ chữ, khoảng cách và bo góc phải gán từ token ở các mục 2–5, không gán hex hoặc số trực tiếp.

```text
Thư viện component
├── 1. Button        (Filled, Outlined, Text, Text-danger, FAB)
├── 2. Text Field    (Single-line, Multi-line Markdown)
├── 3. Card          (Course Card, Task Card)
├── 4. Navigation Bar (4 điểm đến)
├── 5. App Bar       (Top-level, Level-2 với action)
├── 6. Dialog        (D-01 Confirmation, D-02 Error)
├── 7. Loading State (LD-01 Skeleton, LD-02 Search Pulse, LD-03 Spinner)
├── 8. Empty State   (EM-01..04)
├── 9. Error State   (ER-01..03)
└── Bổ trợ: Chip, Badge, Snackbar, Bottom Sheet, Banner, Progress Bar, Chat Bubble
```

### 6.1. Button
- Chiều cao tối thiểu **48 dp**, padding ngang 16–24 dp, bo góc `radius-full`, chữ `type-label-large`. FAB: 56 × 56 dp, `radius-lg`, `elevation-2`, nằm góc dưới bên phải, cách mép phải `spacing-md` và nằm phía trên Navigation Bar.
- **Trạng thái bắt buộc (Filled):**

| Trạng thái | Nền | Chữ và icon | Ghi chú |
| :--- | :--- | :--- | :--- |
| Default | `color-primary` | `color-on-primary` | |
| Pressed | `color-primary-pressed` | `color-on-primary` | Hiệu ứng ripple |
| Disabled | `color-disabled-container` | `color-on-disabled` | Không nhận chạm |
| Loading | `color-primary` | Ẩn nhãn, hiện spinner 20 dp màu `color-on-primary` | Giữ nguyên chiều rộng nút; đọc "Đang xử lý" cho trình đọc màn hình |

- **Outlined:** nền trong suốt, viền 1 dp `color-outline`, chữ `color-primary`; Pressed nền `color-primary-container`; Disabled viền và chữ `color-on-disabled`.
- **Text:** không viền, chữ `color-primary`; Pressed nền `color-primary-container`.
- **Text-danger** (nút "Bỏ" ở D-01): chữ `color-error`; Pressed nền `color-error-container`.

### 6.2. Text Field
- Chiều cao tối thiểu 56 dp, padding trong `spacing-md`, bo góc `radius-sm`, nền `color-surface-container`, chữ nhập ≥ 14 sp.

| Trạng thái | Viền | Nhãn và chữ | Chi tiết |
| :--- | :--- | :--- | :--- |
| Default | 1 dp `color-outline` | Placeholder `color-on-surface-variant` | |
| Focused | 2 dp `color-primary` | Nhãn nổi màu `color-primary` | |
| Filled | 1 dp `color-outline` | Chữ `color-on-surface` | Icon xóa nhanh, vùng chạm 48 × 48 dp |
| Error | 2 dp `color-error` | Thông báo lỗi 14 sp (`type-body-medium`) màu `color-error`, kèm icon lỗi | Nêu nguyên nhân và cách sửa; nội dung đã gõ được giữ nguyên |
| Disabled | 1 dp `color-disabled-container` | Chữ `color-on-disabled` | Nền `color-surface-container-high` |

### 6.3. Card
- Auto Layout dọc, padding `spacing-md`, bo góc `radius-md`, viền `color-outline-variant`, nền `color-surface-container`.
- **Course Card:** mã môn, tên môn (`type-title-large`), Badge trạng thái môn (mục 2.4).
- **Task Card:** checkbox, tên việc (`type-title-medium`), tên môn, Badge hạn (mục 2.3).
- **Biến thể:** Default (`elevation-0`); Pressed (nền `color-surface-container-high`, thu nhỏ 0.98); Task Card có thêm biến thể **Done** (tên việc gạch ngang, Badge "Đã hoàn thành").
- **Task Card:** checkbox có vùng chạm riêng **48 × 48 dp**, tách khỏi vùng chạm mở file của thẻ ít nhất `spacing-xs` (8 dp). Chạm vào thân thẻ không làm đổi trạng thái hoàn thành.

### 6.4. Navigation Bar
- Neo ở đáy, chiều cao **80 dp** (mặc định M3), 4 điểm đến: Trang chủ (`home`), Lộ trình (`account_tree`), Việc cần làm (`check_box`), Ghi chú (`description`). Mỗi điểm đến có vùng chạm ≥ 48 dp.
- **Variants:** 4 biến thể "đang chọn", mỗi biến thể là một điểm đến được chọn (Trang chủ, Lộ trình, Việc cần làm, Ghi chú).
  - Selected: nền con nhộng `color-primary-container`, icon `color-primary`, nhãn in đậm, `type-label-small`.
  - Unselected: icon `color-on-surface-variant`, nhãn thường.

### 6.5. App Bar
- Chiều cao 56 dp, padding ngang `spacing-md`.
- **Top-level:** tiêu đề căn trái (tên ngành hoặc tên màn hình, `type-headline-medium`); ở Trang chủ có icon Cài đặt (SCR-08) góc phải, vùng chạm 48 × 48 dp.
- **Level-2 với action:** nút Back bên trái (48 × 48 dp), tiêu đề `type-title-large`, tối đa hai action bên phải (Search, Filter, More; mỗi cái 48 × 48 dp). Nền `color-surface`; khi cuộn dùng `elevation-1`.

### 6.6. Dialog
- Phủ lớp `color-scrim`; hộp thoại nền `color-surface-container`, bo góc `radius-lg`, padding `spacing-xl`, `elevation-3`.
- **D-01 Confirmation:** tiêu đề "Bỏ ghi chú này?", mô tả "Nội dung chưa lưu sẽ bị mất", hai nút: "Tiếp tục soạn" (Outlined) và "Bỏ" (Text-danger).
- **D-02 Error:** tiêu đề "Không thể ghi vào Vault", mô tả nguyên nhân, hai nút: "Thử lại" (Filled) và "Hủy" (Text).

### 6.7. Loading State
- **LD-01 Skeleton:** khối `color-skeleton` bo góc theo hình dạng dòng việc và Card môn, shimmer nhẹ. Dùng ở SCR-01 và SCR-04.
- **LD-02 Search Pulse:** vòng sáng nhịp điệu `color-primary-container` kèm "AI đang tìm trong ghi chú của bạn...". Dùng ở SCR-07.
- **LD-03 Spinner:** vòng xoay 24 dp `color-primary`, kèm chữ "Đang quét Vault..." Dùng ở SCR-08; hoàn tất hiện "Đã cập nhật N file".
- Khi hệ thống bật giảm chuyển động, thay shimmer và pulse bằng trạng thái tĩnh.

### 6.8. Empty State (EM-01..04)
Khối căn giữa gồm: (1) icon 64 × 64 dp màu `color-on-surface-variant`; (2) tiêu đề và một dòng giải thích vì sao trống; (3) **đúng một** Button Filled chính.

| Mã | Màn hình | Ví dụ nội dung | Hành động |
| :--- | :--- | :--- | :--- |
| EM-01 | SCR-01 | "Chưa kết nối Vault" | "Mở Cài đặt" |
| EM-02 | SCR-03 | "Môn này chưa có đề cương" | "Tạo ghi chú cho môn này" |
| EM-03 | SCR-04 | "Hôm nay bạn không có deadline" | "Xem sắp tới" |
| EM-04 | SCR-06 | "Chưa có ghi chú nào" | "Tạo ghi chú" |

### 6.9. Error State (ER-01..03)
Khối gồm: (1) icon cảnh báo `color-error`; (2) thông điệp nêu rõ nguyên nhân; (3) nút "Thử lại" (Filled) và một nút phụ (Text). **Nội dung người dùng đã gõ được giữ nguyên.**

| Mã | Màn hình | Nguyên nhân | Hành động chính | Hành động phụ |
| :--- | :--- | :--- | :--- | :--- |
| ER-01 | SCR-07 | "Không có kết nối mạng. Bạn có thể kiểm tra Wi-Fi/4G rồi thử lại" | "Thử lại" | "Quay lại" |
| ER-02 | SCR-07 | "AI chưa sẵn sàng: thiếu API Key hoặc đã hết hạn mức" | "Mở Cài đặt" | "Quay lại" |
| ER-03 | SCR-08 | "Không tìm thấy thư mục Vault" | "Chọn lại thư mục" | "Hủy" |

Lỗi tên file ở SCR-05 dùng biến thể **Error của Text Field** (mục 6.2), không dùng khối Error State.

### 6.10. Component bổ trợ
- **Chip:** chiều cao hiển thị 32 dp, **vùng chạm mở rộng 48 dp**, `radius-full`, chữ `type-label-large`; đang chọn dùng `color-primary-container` và `color-on-primary-container`, kèm dấu tick.
- **Badge:** `radius-full`, icon 16 dp và chữ `type-body-semibold`, màu theo mục 2.3 và 2.4.
- **Snackbar (SN-01, SN-02):** nền `color-inverse-surface`, chữ `color-inverse-on-surface`, nút hành động `color-inverse-primary` (vùng chạm 48 dp), `elevation-3`, bo góc `radius-sm`, neo phía trên Navigation Bar. **SN-01 hiển thị 8 giây**; SN-02 (Đã lưu, nút Xem) 4 giây.
- **Bottom Sheet (BS-01):** nền `color-surface-container`, `radius-xl` ở hai góc trên, tay nắm kéo, padding `spacing-xl`, `elevation-3`; mỗi lựa chọn cao tối thiểu 48 dp.
- **Banner ngoại tuyến:** nền `color-warning-container`, icon `color-warning`, chữ `color-on-warning-container` "Đang ngoại tuyến, dữ liệu cập nhật lần cuối dd/mm", `radius-md`.
- **Progress Bar** (tiến độ kiến thức): `radius-xs`, đầy là `color-primary`, nền `color-surface-container-high`, luôn kèm chữ phần trăm.
- **Chat Bubble:** câu hỏi người dùng nền `color-primary` chữ `color-on-primary`; câu trả lời AI nền `color-surface-container` viền `color-outline-variant` chữ `color-on-surface` (`type-body-large`); thẻ trích dẫn nguồn là Chip nền `color-secondary-container`, vùng chạm 48 dp.


---

## 7. Ràng buộc Kỹ thuật và Bàn giao

1. **Không gán cứng giá trị:** 100% màu, cỡ chữ, khoảng cách, bo góc và độ nổi trong component phải gán từ Variables hoặc Styles tương ứng. Cấm gán trực tiếp mã hex hoặc số lẻ.
2. **Vùng chạm tối thiểu 48 × 48 dp** cho nút, icon, checkbox, chip, tab. Hình hiển thị nhỏ hơn được phép nếu vùng chạm mở rộng đủ 48 dp. Hai vùng chạm liền kề cách nhau tối thiểu `spacing-xs` (8 dp).
3. **Responsive:** layout dựng bằng Auto Layout (Hug hoặc Fill container), co giãn từ 360 dp sang 412 dp không tràn viền. Văn bản dài xuống dòng hoặc cắt bằng dấu "…" theo quy tắc từng màn hình, không làm vỡ bố cục.
4. **Icon:** bộ Material Symbols (Rounded), kích thước 24 dp, màu theo token.
5. **Chuyển động:** thời lượng 200–300 ms cho chuyển cảnh thông thường; thông báo có hành động (SN-01) tuân theo thời gian ở mục 6.10.
6. **Nhất quán:** cùng một đối tượng dùng cùng một component, nhãn và màu trên mọi màn hình (ví dụ Badge hạn nộp ở Trang chủ và ở Việc cần làm là cùng một component).
7. **Chữ ký hiệu trạng thái:** mọi trạng thái đều có nhãn chữ và icon, không chỉ màu (mục 2.3 và 2.4).
