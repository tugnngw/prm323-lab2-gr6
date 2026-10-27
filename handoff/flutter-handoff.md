# Flutter Handoff — FPTU Second Brain Mobile

## Quy tắc toàn cục

- Android portrait; thiết kế chuẩn 360 × 800 dp, kiểm tra 412 dp. PNG tham chiếu cuối nằm trong `assets/figma/`.
- Material Design 3, light theme, Inter (fallback Roboto), tiếng Việt. Dùng SafeArea/MediaQuery cho system insets.
- Nội dung tối thiểu 14 sp; Navigation label 12 sp là ngoại lệ được ghi trong design brief. Touch target tối thiểu 48 × 48 dp; khoảng cách tối thiểu 8 dp.
- Contrast chữ thường ≥ 4.5:1, chữ lớn/UI control ≥ 3:1; không dùng màu làm tín hiệu duy nhất.
- **Visual refresh hiện hành:** xanh dương `#1D4ED8` cho hành động; teal `#0F766E` cho Vault/ghi chú; xanh lá `#16845B` cho hoàn tất; amber `#B45309` cho cảnh báo; đỏ `#B42318` cho lỗi. Dùng container tint nhẹ, nền `#F4F7FB`, card trắng; trạng thái luôn có nhãn và icon. Icon dùng Material Symbols Rounded 24 px; xem Page 05 `10 · Iconography`. Bảng token chi tiết bên dưới là nguồn Flutter hiện hành; phần màu trong `design/DESIGN.md` ghi hướng ban đầu.
- **AppBar Workflow 4–6:** cao 56 dp; back target 48 × 48 dp bên trái; tiêu đề Inter Semi Bold 20 sp căn giữa trong vùng giữa hai nút; áp dụng đồng nhất trên Final UI và Prototype.
- Lưới 4 dp; lề 16 dp tại 360, 20 dp tại 412. Xem `design/DESIGN.md` để biết giá trị đầy đủ.
- Prototype có 6 điểm bắt đầu: ba flow Lab 2 gốc và Workflow 4–6. Hỏi AI là nhánh Flow 1A từ chi tiết môn, không phải một start point riêng. Dữ liệu Figma mở rộng là dữ liệu mẫu.
- Mã phẳng trong phần handoff của ba flow gốc là alias lịch sử. Mã hiện hành theo module là `SCR-01.01_Home`, `SCR-02.01_Roadmap`, `SCR-02.02_CourseDetail`, `SCR-03.01_Tasks`, `SCR-04.01_NoteEditor`, `SCR-04.02_Notes`, `SCR-05.01_AdvisorHub`, `SCR-06.01_SyncVault` và `SCR-06.02_SyncError`.

## Responsive từ 600 dp

Các bố cục rộng là yêu cầu handoff để triển khai/kiểm tra; Figma hiện ưu tiên mobile, không khẳng định đã có frame tablet.

- Từ 600 dp: BottomNavigationBar chuyển thành NavigationRail; nội dung một cột, căn giữa, giới hạn khoảng 840 dp; lề 24–32 dp.
- Từ 840 dp: Roadmap có thể dùng danh sách môn + chi tiết hai pane; Notes dùng danh sách + nội dung ghi chú hai pane. Ở 600–839 dp dùng một pane.
- SCR-04.01 giới hạn vùng soạn khoảng 720 dp; dialog căn giữa tối đa khoảng 560 dp.
- Giữ target 48 dp và cho phép cuộn khi text scale tăng. Rà soát tràn chữ tiếng Việt tại 360, 412, 600 và 840 dp.

## Token → Flutter

| Token | Flutter mapping | Giá trị/ghi chú |
| --- | --- | --- |
| color-primary / on-primary / primary-pressed | ColorScheme.primary / onPrimary; custom pressed | #1D4ED8 / #FFFFFF / #1E40AF |
| primary-container / on-primary-container | primaryContainer / onPrimaryContainer | #DBEAFE / #1E3A8A |
| secondary / secondary-container / on-secondary-container | secondary / secondaryContainer / onSecondaryContainer | #0F766E / #CCFBF1 / #115E59 |
| surface / background / card | surface / scaffoldBackgroundColor / surfaceContainerLowest | #FFFFFF / #F4F7FB / #FFFFFF |
| on-surface / on-surface-variant / outline / outline-variant | onSurface / onSurfaceVariant / outline / outlineVariant | #17233B / #526176 / #C8D2E0 / #D9E1EC (outline-variant chỉ trang trí) |
| error / error-container / on-error | error + semantic colors | #B42318 / #FDE8E7 / #B42318 |
| warning / warning-container / on-warning | custom semantic colors | #B45309 / #FFF2CC / #925500 |
| success / success-container / on-success | custom semantic colors | #16845B / #DDF5E8 / #126B48 |
| disabled-container / on-disabled / skeleton | custom states | #E2E8F0 / #94A3B8 / #E2E8F0 |
| scrim / inverse-surface / inverse-on-surface / inverse-primary | scrim + inverse ColorScheme | #0F172A at 40%; #1E293B / #F8FAFC / #93C5FD |
| headline-large / headline-medium | TextTheme.headlineLarge / headlineMedium | Inter 28/22 sp; line height 34/28 |
| title-large / title-medium | titleLarge / titleMedium | 18/16 sp; line height 24/22 |
| body-large / body-medium / body-semibold | bodyLarge / bodyMedium + weight | 16/14 sp; line height 24/20 |
| label-large / label-small | labelLarge / labelSmall | 14/12 sp; small chỉ dùng navigation |
| spacing-2xs / xs / sm / md | constants | 4 / 8 / 12 / 16 dp |
| spacing-lg / xl / 2xl | constants | 20 / 24 / 32 dp |
| radius-xs / sm / md / lg / xl / full | constants | 4 / 8 / 12 / 16 / 24 / 999 dp |
| elevation tokens | CardTheme / state elevation | theo bảng elevation trong DESIGN.md |
| iconography | Material Symbols Rounded | glyph 24 px, xanh primary; trạng thái lỗi dùng semantic error |

## Component → Flutter widget

| Figma component | Flutter suggestion | Trạng thái |
| --- | --- | --- |
| Button | FilledButton, OutlinedButton, TextButton, FloatingActionButton | Default, pressed, disabled, loading |
| TextField/SearchField | TextField hoặc TextFormField | Default, focused, filled, error, disabled |
| CourseCard/NoteCard | Card + InkWell | Default/pressed; semantics chứa tên và status |
| TaskItem | custom row + Checkbox | checkbox và mở chi tiết là hai hit target; Undo 8 giây |
| BottomNavigation | NavigationBar; NavigationRail khi ≥600 dp | selected: Home/Roadmap/Tasks/Notes |
| AppBar | AppBar | default/action |
| D-01 dialog | AlertDialog | confirm/cancel; back/outside theo prototype |
| LoadingState | skeleton hoặc CircularProgressIndicator | chỉ hiển thị trong lúc tải |
| EmptyState | custom icon + message + CTA | một hành động chính |
| ErrorState | banner/page error + retry | giữ dữ liệu/input hiện có |
| Chip/filter | FilterChip/ActionChip | selected có label/icon |
| Consultation scope | FilterChip/ChoiceChip | 4 phạm vi: Môn, Kỳ, CTĐT, Điểm; một lựa chọn mặc định |
| Progress | LinearProgressIndicator | kèm số liệu chữ |
| Snackbar | ScaffoldMessenger | Undo không bị FAB/navigation che |
| Program catalog | ListTile/Card + Checkbox/FilterChip | chọn ngành/khóa, tải catalog về thiết bị; trạng thái nguồn/phiên bản |
| Curriculum prerequisite | ExpansionTile/graph/list rows | hiện mã môn, quan hệ prerequisite và nguồn; tách catalog khỏi transcript |
| Share consent | AlertDialog | hiển thị các trường/mục đích; từ chối hoặc cho phép một lần |
| Strategy result | Card + ListTile + source links | local/shared, học lại/cải thiện, tải môn, khung giờ; cảnh báo khi thiếu căn cứ |

## Screen-by-screen handoff

Mỗi mục nêu đủ Layout, Components, States, Interactions, Navigation và Constraints. PNG là tham chiếu Figma final.

### SCR-01.01 — Home
- **Layout:** trang cuộn gồm lời chào, trạng thái Vault, deadline khẩn cấp, thẻ Vault; navigation cố định.
- **Components:** AppBar action đồng bộ/cài đặt, deadline cards, Vault card, NavigationBar.
- **States:** populated, skeleton loading, Vault chưa kết nối/empty, offline banner.
- **Interactions:** tất cả deadline → SCR-03.01; course → SCR-02.02; sync/settings → SCR-08.
- **Navigation:** start mặc định; tabs đến SCR-02.01/SCR-03.01/SCR-06.
- **Constraints:** ngày và trạng thái không bị cắt; icon + label. Ref: `assets/figma/SCR-01_Home.png`.

### SCR-02.01 — Roadmap
- **Layout:** chọn kỳ/tìm kiếm, tiến độ tuần, danh sách CourseCard cuộn.
- **Components:** term chips, SearchField, chart, CourseCard.
- **States:** populated, loading, empty, pressed.
- **Interactions:** chọn kỳ/tìm; mở PRM323 → SCR-03.
- **Navigation:** tab 2, back theo quy tắc chung.
- **Constraints:** biểu đồ có số liệu text; trạng thái không chỉ dựa vào màu. Ref: `assets/figma/SCR-02_Roadmap.png`.

### SCR-02.02 — Course Detail
- **Layout:** thông tin môn/tiến độ, cảnh báo offline, tabs nội bộ và actions.
- **Components:** AppBar, course/progress cards, tabs, Ask AI, Documents.
- **States:** populated, thiếu syllabus/empty, offline.
- **Interactions:** Ask AI → SCR-05.01 (Flow 1A); Documents → SCR-04.02 lọc PRM323.
- **Navigation:** push từ SCR-01.01/02; back về origin.
- **Constraints:** giữ course context; không yêu cầu đăng nhập FLM trên mobile. Ref: `assets/figma/SCR-03_CourseDetail.png`.

### SCR-03.01 — Tasks
- **Layout:** filters, semester progress, urgent tasks đầu danh sách, nhóm upcoming/completed.
- **Components:** chips, TaskItem có checkbox/detail hit target riêng, Snackbar, FAB nếu hiện diện.
- **States:** populated, loading, empty theo filter, completed + Undo.
- **Interactions:** chạm nội dung task → SCR-04.01; checkbox đổi trạng thái và mở Undo 8 giây.
- **Navigation:** tab 3; editor quay về context trước hoặc Notes.
- **Constraints:** checkbox 48 × 48 dp; Snackbar không bị FAB che; Undo khôi phục đúng trạng thái. Ref: `assets/figma/SCR-04_Tasks.png`.

### SCR-04.01 — Note Editor
- **Layout:** editor toàn màn hình; metadata/title, Markdown edit/preview, toolbar đáy có Save.
- **Components:** AppBar/back, course/tag chips, editor, preview, checklist action, format toolbar, Save.
- **States:** create, edit, autosaved, invalid filename, save failure.
- **Interactions:** soạn Markdown/checklist; lưu → SCR-04.02; back về origin.
- **Navigation:** mở từ task/note; hỗ trợ nhiều nguồn vào.
- **Constraints:** keyboard không che Save; làm rõ autosave và explicit save; hỗ trợ text scale. Ref: `assets/figma/SCR-05_NoteEditor.png`.

### SCR-04.02 — Notes
- **Layout:** Vault status, search, subject filters, list và helper callout.
- **Components:** SearchField, filter chips, NoteCards gắn USER NOTE/FLM SYNC, FAB nếu có.
- **States:** populated, filtered, no results, no notes.
- **Interactions:** note → SCR-04.01; tìm/lọc; tạo note.
- **Navigation:** tab 4; đích xem Vault offline trong Flow 1A.
- **Constraints:** phân biệt loại note bằng chữ/icon; title dài được wrap. Ref: `assets/figma/SCR-06_Notes.png`.

### SCR-05.01 — Ask AI
- **Layout:** context/model AppBar, connection banner, chat/citations, prompts, composer đáy.
- **Components:** chat bubbles, citation card, retry banner, prompt chips, composer/send.
- **States:** suggestions, loading, answer, no sources, network/config error.
- **Interactions:** gửi câu hỏi; citation mở nguồn; retry gửi lại câu hỏi đã giữ.
- **Navigation:** Flow 1A từ SCR-02.02; back giữ question và course context.
- **Constraints:** AI cần mạng; Vault vẫn tra cứu offline; không báo AI chạy offline. Ref: `assets/figma/SCR-07_AskAI.png`.

### SCR-06.01 — Sync Vault
- **Layout:** Vault path/status, rescan controls, AI config, capacity.
- **Components:** AppBar, path selector, switch, sync button, API key field, status card.
- **States:** connected, confirmation overlay, loading, success, inaccessible Vault.
- **Interactions:** sync now → D-01; confirm chạy sync; cancel đóng; failure → error state.
- **Navigation:** từ action trên SCR-01.01; retry từ error trở lại đây.
- **Constraints:** bảo vệ API key; thông báo chính xác nơi lưu và yêu cầu mạng. Ref: `assets/figma/SCR-08_SyncVault.png`.

### D-01 — Sync confirmation
- **Layout:** modal căn giữa trên SCR-06.01, mô tả + 2 actions.
- **Components:** AlertDialog, cancel/confirm, scrim.
- **States:** mở, dismissed, confirming.
- **Interactions:** cancel/back/outside dismiss; confirm bắt đầu đồng bộ.
- **Navigation:** dismiss trả về SCR-06.01 nền.
- **Constraints:** focus semantics, label rõ, contrast đạt chuẩn. Ref: `assets/figma/D-01_SyncConfirmation.png`.

### SCR-06.02_SyncError — Sync failure
- **Layout:** nguyên nhân lỗi, cam kết dữ liệu cục bộ còn nguyên, retry.
- **Components:** error icon/text, retry, optional choose-folder action.
- **States:** permission/path error, retrying, recovered.
- **Interactions:** Retry → SCR-06.01; choose folder mở picker khi implement.
- **Navigation:** đến sau sync thất bại; Back theo flow app.
- **Constraints:** nêu nguyên nhân và hành động; không dùng riêng màu đỏ. Ref: `assets/figma/SCR-08_SyncError.png`.

## Kiểm tra khi triển khai

Đối chiếu Figma page 06 và `design/screen-spec.md`; kiểm tra back navigation, giữ input khi lỗi, retry, trạng thái loading, semantics, contrast và overflow tại các độ rộng đã nêu. 

## Expanded workflow screen handoff

| Screen | Layout / Flutter structure | Data & interaction contract |
|---|---|---|
| `SCR-00.01_AuthSetup` | Scaffold + onboarding card + primary/secondary buttons | Catalog cloud và FAP tùy chọn được giải thích riêng; không buộc đăng nhập FAP để tiếp tục. |
| `SCR-00.02_ProgramCatalog` | Search/filter + selectable program cards + fixed download CTA | Catalog/nguồn/phiên bản; user chọn ngành/khóa, tải cache về máy. Prototype sample, không gọi FLM. |
| `SCR-00.03_FAPConnect` | Privacy explainer + permission/connection card + connect/skip | Dùng OAuth/SSO hoặc SDK/kênh chính thức được cấp phép; không thu password; local encryption, disconnect/delete. Skip/connect quay lại Curriculum. |
| `SCR-02.03_Curriculum` | Program header + progress + prerequisite list/tree + source labels | Curriculum catalog khác transcript cá nhân; FAP optional; không kết luận pass/fail khi thiếu dữ liệu. |
| `SCR-05.01_AdvisorHub` | Chat Scaffold + horizontal scope chips + citations + composer | Môn/Kỳ/CTĐT/Điểm; AI requires network; cache local; mọi claim học vụ có source/version. |
| `SCR-05.04_StrategySim` | Form/cards for goals, target term, inputs and source notes | Cho phép học lại/cải thiện, cân bằng tải, giờ trống, eligibility checks; thiếu dữ liệu thì disable conclusion. |
| `DLG-05.04_ShareConsent` | AlertDialog/ModalBottomSheet | Show exact fields and purpose; opt-in per request; Decline stays local; do not persist consent. |
| `SCR-05.07_StrategyLoading` | Centered progress/skeleton state | Simulated 1.2 s in Figma; cancellation returns to strategy form. |
| `SCR-05.05_LocalStrategyResult` | Result cards + source links + next-step actions | Local rule engine, no AI/network; explicit sample/verified source labels; unknown result remains unknown. |
| `SCR-05.06_SharedStrategyResult` | Result cards + citations + return-to-curriculum CTA | Send only consented fields for one request; label AI suggestion, link official verification; no automatic enrollment. |

See [`ux/academic-workflows.md`](../ux/academic-workflows.md) for source and privacy rules and [`design/screen-spec.md`](../design/screen-spec.md) for screen-level details.
