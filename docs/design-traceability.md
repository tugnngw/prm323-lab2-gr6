# Design Traceability — Figma → Flutter

Ánh xạ từ Screen-ID trong thiết kế (Lab 2) sang route, widget, ViewModel, data source và test case.

## Screen → Route → Widget → ViewModel → Data Source → Test Case

| Screen ID | Tên màn hình | Route | Widget | ViewModel | Data Source | Test Case ID |
|-----------|-------------|-------|--------|-----------|-------------|--------------|
| SCR-00.01 | Auth Setup | `/sign-in` (AuthGate) | `SignInScreen` | `AuthViewModel` | Firebase Auth (Google Sign-In) | TC-AUTH-01, TC-AUTH-02 |
| SCR-01.01 | Trang chủ | `/home` (tab 0) | `HomeScreen` | `HomeViewModel` | Firestore (`users/{uid}`), Remote Config | TC-HOME-01, TC-NAV-01 |
| SCR-02.01 | Lộ trình môn học | `/home` (tab 1) | `RoadmapScreen` | `RoadmapViewModel` | Firestore (`courses`), Local Cache | TC-ROAD-01, TC-ROAD-02 |
| SCR-02.02 | Chi tiết môn học | `/course-detail` | `CourseDetailScreen` | — (Route args) | Firestore (`courses/{id}`) | TC-COURSE-01 |
| SCR-03.01 | Việc cần làm | `/home` (tab 2) | `TasksScreen` | `TasksViewModel` | Firestore (`users/{uid}/tasks`) | TC-TASK-01, TC-TASK-02 |
| SCR-04.01 | Soạn ghi chú | `/note-editor` | `NoteEditorScreen` | — (Stateful) | Firestore (`users/{uid}/notes`), Storage | TC-NOTE-01 |
| SCR-04.02 | Danh sách ghi chú | `/home` (tab 3) | `NotesScreen` | `NotesViewModel` | Firestore (`users/{uid}/notes`) | TC-NOTE-02 |
| SCR-05.01 | Cố vấn học tập | `/advisor` | `AdvisorScreen` | — (future) | Firestore, Remote Config (`ai_advisor`) | TC-ADV-01 |
| SCR-06.01 | Sync Vault | `/sync-vault` | `SyncVaultScreen` | — (future) | Local cache, Firestore offline | TC-SYNC-01 |
| SCR-06.02 | Lỗi đồng bộ | (push on error) | `SyncErrorScreen` | — (Route args) | Local error handler | TC-SYNC-02 |

---

## User Flow Traceability

### Flow 1: Curriculum & Course Detail
- **Đường dẫn**: Home → Lộ trình (Tab 1) → Chọn môn (PRM323) → Course Detail.
- **Nhánh chính**: Tải danh sách môn kỳ Fall 2024 từ Firestore `courses`, kiểm tra môn tiên quyết (PRO192, CSD201).
- **Nhánh lỗi**: Mất mạng → hiển thị dữ liệu từ cache cục bộ (Firestore offline persistence), icon thông báo offline.
- **Analytics event**: `course_view`, `prerequisite_check`.

### Flow 2: Study Plan & Notes Vault
- **Đường dẫn**: Home → Việc cần làm (Tab 2) / Ghi chú (Tab 3) → Soạn ghi chú → Lưu.
- **Nhánh chính**: Hiển thị danh sách task theo hạn chót, đánh dấu hoàn thành, tạo ghi chú lưu vào Firestore và Cloud Storage.
- **Nhánh lỗi**: Hủy tạo task/ghi chú → quay về danh sách không làm mất dữ liệu cũ.
- **Analytics event**: `task_create`, `task_complete`, `note_create`.

### Flow 3: AI Advisor & Strategy Simulation
- **Đường dẫn**: Home → Quick Access "AI Academic Advisor" → Phân tích GPA & Mô phỏng chiến lược.
- **Nhánh chính**: Lấy cấu hình từ Firebase Remote Config (`feature_ai_advisor_enabled`), hiển thị kịch bản điểm số.
- **Nhánh lỗi**: Khi `feature_ai_advisor_enabled == false` → hiển thị banner bảo trì tính năng, không crash.
- **Analytics event**: `advisor_query`.

---

## Reusable Widgets → Design Components (9/9 Nhóm)

| Design Component (Figma) | Flutter Widget | File | Semantics Label |
|--------------------------|----------------|------|-----------------|
| Card / Surface | `AppCard` | `widgets/app_components.dart` | Card container |
| Top App Bar | `CustomAppBar` | `widgets/app_components.dart` | Header bar, action buttons |
| Bottom Nav Bar | `AppBottomNav` | `widgets/app_navigation.dart` | Navigation destinations (4 tabs) |
| Primary Button | `AppButton` | `widgets/app_button.dart` | Action button, loading spinner |
| Secondary Button | `AppOutlinedButton` | `widgets/app_button.dart` | Secondary action button |
| Text Field | `AppTextField` | `widgets/app_text_field.dart` | Form input with validation text |
| Search Bar | `AppSearchBar` | `widgets/app_text_field.dart` | Search input with clear button |
| Confirm Dialog | `AppConfirmDialog` | `widgets/app_components.dart` | Confirmation modal (Hủy/Xác nhận) |
| Loading Indicator | `AppLoadingState` | `widgets/app_states.dart` | Circular progress with message |
| Empty State | `AppEmptyState` | `widgets/app_states.dart` | Empty illustration + CTA button |
| Error State | `AppErrorState` | `widgets/app_states.dart` | Error warning + "Thử lại" button |

---

## Color Tokens Mapping

| Figma Token | Dart Constant | Hex | Vai Trò |
|-------------|--------------|-----|---------|
| Primary/Default | `AppColors.primary` | `#1D4ED8` | Nút bấm chính, header, active tab |
| Primary/Pressed | `AppColors.primaryPressed` | `#1E40AF` | Trạng thái nhấn nút |
| Primary/Container | `AppColors.primaryContainer` | `#DBEAFE` | Nền icon, badge nổi bật |
| Secondary/Default | `AppColors.secondary` | `#0F766E` | Nhãn tiến độ, task |
| Success/Default | `AppColors.success` | `#16845B` | Đã hoàn thành, sync thành công |
| Warning/Default | `AppColors.warning` | `#B45309` | Sắp đến hạn, cảnh báo tiên quyết |
| Error/Default | `AppColors.error` | `#B42318` | Lỗi đồng bộ, banner lỗi đăng nhập |
| Background | `AppColors.background` | `#F4F7FB` | Nền scaffold ứng dụng |
| Surface | `AppColors.surface` | `#FFFFFF` | Nền card, dialog, input |
| On Surface | `AppColors.onSurface` | `#17233B` | Chữ chính (body, title) |
| On Surface Variant | `AppColors.onSurfaceVariant` | `#526176` | Chữ phụ, mô tả |
| Outline | `AppColors.outline` | `#C8D2E0` | Viền card, divider, input border |
