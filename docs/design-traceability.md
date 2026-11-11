# Design Traceability — Figma → Flutter

Cập nhật: 2026-11-10. Tài liệu này là bảng đối chiếu duy nhất giữa thiết kế Lab 2
(`design/screen-spec.md`, `design/DESIGN.md`, `handoff/flutter-handoff.md`) và mã
Flutter hiện tại. Mỗi màn hình có route, widget, ViewModel, nguồn dữ liệu, trạng thái
và mã kiểm thử tương ứng. Sai lệch so với Figma được ghi ở mục 4 kèm lý do.

## 1. Màn hình → Route → Widget → ViewModel → Data source

| Screen ID (Figma) | Màn hình | Route / điểm vào | Widget | ViewModel | Data source | Trạng thái |
|---|---|---|---|---|---|---|
| SCR-00.01_AuthSetup | Đăng nhập | `/sign-in` (AuthGate) | `SignInScreen` | `AuthViewModel` | Firebase Auth (Google Sign-In) | Đã triển khai |
| SCR-01.01_Home | Trang chủ | `/home` tab 0 (`AppShell`) | `HomeScreen` | `AuthViewModel`, `NotificationsViewModel`, `TasksViewModel` | Firestore `users/{uid}`, `users/{uid}/tasks`, `announcements`; Remote Config | Đã triển khai |
| SCR-02.01 / SCR-02.03_Curriculum | Lộ trình môn học | `/home` tab 1 | `RoadmapScreen` | `RoadmapViewModel`, `AcademicViewModel` | Firestore `courses`, `majors`, `users/{uid}.passedCourses` | Đã triển khai |
| SCR-02.02_CourseDetail | Chi tiết môn học | `/course-detail` | `CourseDetailScreen` | `RoadmapViewModel`, `AcademicViewModel`, `TasksViewModel` | Firestore `courses/{id}`, `users/{uid}/courseProgress` | Đã triển khai |
| — (tab trong SCR-02.02) | Bí kíp cộng đồng | `/course-tips` | `CourseDetailScreen(initialTab: 3)` + `CommunityTipsSection` | `RoadmapViewModel`, `AuthViewModel` | `experience_notes`, `tip_ratings`, `tip_comments`, `users/{uid}/notifications` | Mới cho Lab 3 |
| SCR-03.01_Tasks | Việc cần làm | `/home` tab 2 | `TasksScreen` | `TasksViewModel` | Firestore `users/{uid}/tasks` | Đã triển khai |
| SCR-04.01_QuickNote | Soạn ghi chú | `/note-editor` | `NoteEditorScreen` | `NotesViewModel` | Firestore `users/{uid}/notes`; Cloudinary/Storage `notes/{uid}/…` | Đã triển khai (xem D-02) |
| — (mới) | Hỏi AI về ghi chú | push từ `NoteEditorScreen` / `NotesScreen` | `NoteAiScreen` | `NotesViewModel` + `AiService` | Firebase AI Logic (Gemini), Remote Config | Mới cho Final |
| SCR-04.02_NotesVault | Danh sách ghi chú | `/home` tab 3 | `NotesScreen` | `NotesViewModel` | Firestore `users/{uid}/notes` | Đã triển khai |
| — (mới) | Bí kíp của tôi | `/my-tips` | `MyTipsScreen` | (đọc trực tiếp `FinalFirestore`, chỉ hiển thị) | `experience_notes` lọc theo `uid` | Mới cho Lab 3 |
| SCR-05.01_AdvisorHub | Cố vấn học tập | `/advisor` | `AdvisorScreen` | `AdvisorViewModel` | Firestore `experience_notes` (đã duyệt), Remote Config (`feature_ai_advisor_enabled`, `ai_advisor_model`, `ai_advisor_prompt`), Gemini | Đã triển khai |
| SCR-05.04_StrategySim | Mô phỏng chiến lược | `/strategy-sim` | `StrategySimScreen` | `AcademicViewModel` | Firestore `users/{uid}` (`componentScores`, `passedCourses`) | Đã triển khai (xem D-04) |
| SCR-05.07_StrategyLoading | Trạng thái chờ chiến lược | trong `AdvisorScreen` | `AdvisorScreen` (chat loading) | `AdvisorViewModel` | Local state | Gộp vào SCR-05.01 (D-05) |
| SCR-05.05 / SCR-05.06 | Kết quả chiến lược (local/AI) | `/strategy-sim` | `StrategySimScreen` | `AcademicViewModel` | Local computation; Gemini chỉ khi người dùng đồng ý | Gộp vào SCR-05.04 (D-05) |
| SCR-06.01_SyncSettings | Cài đặt & Đồng bộ Vault | `/sync-vault` | `SyncVaultScreen` | `AuthViewModel`, `RoadmapViewModel`, `TasksViewModel`, `NotesViewModel` | Firestore, Crashlytics, Remote Config, PDF export | Đã triển khai |
| — (SCR-06.02) | Lỗi đồng bộ | push khi lỗi | `SyncErrorScreen` | (route args) | Lỗi từ tầng service | Đã triển khai |
| — (mới) | Trung tâm thông báo | `/notifications` | `NotificationsScreen` | `NotificationsViewModel`, `TasksViewModel` | `users/{uid}/notifications`, `announcements` | Mới cho Lab 3 |
| SCR-08_Settings | Hồ sơ học vụ | `/academic-profile` | `AcademicProfileScreen` | `AcademicViewModel`, `RoadmapViewModel` | Firestore `users/{uid}` | Đã triển khai |
| SCR-00.02_ProgramCatalog | Chọn chuyên ngành | gate sau đăng nhập | `MajorOnboardingScreen` | `AcademicViewModel`, `RoadmapViewModel`, `AuthViewModel` | Firestore `majors` | Đã triển khai |
| — (mới) | Thông báo hệ thống | `/announcements` | `AnnouncementsScreen` | `AnnouncementsViewModel` | `announcements` (realtime) | Mới cho Final |

## 2. Luồng người dùng Lab 2

### Flow 1 — Curriculum & Course Detail
- **Chính**: Home → tab Lộ trình → chọn ngành (nếu chưa có) → danh sách môn theo kỳ →
  chi tiết môn (slot, đầu điểm, đề cương, tiên quyết).
- **Nhánh lỗi**: mất mạng → `RoadmapViewModel` chuyển `ViewState.error`, màn hình hiện
  `AppErrorState` + "Thử lại"; dữ liệu cache Firestore vẫn đọc được khi có cache.
- **Analytics**: `course_view`, `prerequisite_check`, `search_course`.

### Flow 2 — Study Plan, Tasks & Notes
- **Chính**: Home → Việc cần làm → tạo/đánh dấu hoàn thành; Home → Ghi chú → soạn →
  đính kèm (tuỳ chọn) → lưu; mở lại ghi chú để tải tệp.
- **Nhánh lỗi**: lưu thất bại → ghi chú/task được rollback trong ViewModel và hiện
  snackbar lỗi; huỷ editor không làm mất dữ liệu cũ.
- **Analytics**: `task_create`, `task_complete`, `task_delete`, `note_create`,
  `note_export`, `export_report`.

### Flow 3 — AI Advisor & Strategy Simulation
- **Chính**: Home → Cố vấn AI → chọn cấp (Môn/Kỳ/Chương trình/Điểm) → đặt câu hỏi →
  câu trả lời có nhãn nguồn (Gemini / trên thiết bị).
- **Nhánh lỗi**: `feature_ai_advisor_enabled = false`, hết quota hoặc mất mạng → trả lời
  cục bộ, hiện nhãn "Không kết nối AI", không crash.
- **Analytics**: `ai_request`, `ai_result_accepted`, `ai_error`, `advisor_query`.

### Luồng liên vai trò (Final — mobile ↔ web)
- **Chính**: sinh viên gửi bí kíp (`experience_notes.status = pending`) trên mobile →
  Staff duyệt/từ chối trên web kèm lý do → mobile nhận trạng thái mới theo thời gian
  thực và thông báo trong Trung tâm thông báo.
- **Tài liệu chi tiết**: `docs/cross-role-flow.md`.

## 3. Component & token

| Component (Figma) | Widget Flutter | File | Ghi chú |
|---|---|---|---|
| Card / Surface | `AppCard` | `widgets/app_components.dart` | Bo góc + elevation theo token |
| Top App Bar | `CustomAppBar` | `widgets/app_components.dart` | Có `onBack` → nút quay lại 48 dp |
| Bottom Nav | `AppBottomNav` | `widgets/app_navigation.dart` | 4 tab, nhãn semantics |
| Primary Button | `AppButton` | `widgets/app_button.dart` | Spinner khi loading |
| Secondary Button | `AppOutlinedButton` | `widgets/app_button.dart` | |
| Text Field | `AppTextField` | `widgets/app_text_field.dart` | Hiện lỗi validate |
| Search Bar | `AppSearchBar` | `widgets/app_text_field.dart` | Nút xoá |
| Confirm Dialog | `AppConfirmDialog` | `widgets/app_components.dart` | Hủy/Xác nhận |
| Loading | `AppLoadingState` | `widgets/app_states.dart` | |
| Empty | `AppEmptyState` | `widgets/app_states.dart` | Có CTA |
| Error | `AppErrorState` | `widgets/app_states.dart` | "Thử lại" |
| Toast | `showAppToast` | `widgets/app_toast.dart` | Lỗi/thành công |

Token: `lib/theme/app_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`,
`app_theme.dart`. Không có màu/font/padding hard-code trong screen (đã rà bằng
`flutter analyze` + review).

| Token | Hằng số | Hex |
|---|---|---|
| Primary | `AppColors.primary` | `#1D4ED8` |
| Primary pressed | `AppColors.primaryPressed` | `#1E40AF` |
| Primary container | `AppColors.primaryContainer` | `#DBEAFE` |
| Secondary | `AppColors.secondary` | `#0F766E` |
| Success | `AppColors.success` | `#16845B` |
| Warning | `AppColors.warning` | `#B45309` |
| Error | `AppColors.error` | `#B42318` |
| Background | `AppColors.background` | `#F4F7FB` |
| Surface | `AppColors.surface` | `#FFFFFF` |
| On surface | `AppColors.onSurface` | `#17233B` |
| On surface variant | `AppColors.onSurfaceVariant` | `#526176` |
| Outline | `AppColors.outline` | `#C8D2E0` |

## 4. Sai lệch so với Figma (bắt buộc ghi kèm lý do)

| ID | Sai lệch | Lý do | Đã cập nhật Figma? |
|---|---|---|---|
| D-01 | Tên sản phẩm đổi từ "FPTU Second Brain Mobile" → **StudyPilot** | Tên cũ dài, trùng nghĩa "second brain" không đúng phạm vi (lộ trình, việc cần làm, ghi chú, cố vấn). Tên mới ngắn, dùng chung mobile + web. | Có — ghi chú trong `design/DESIGN.md`; ảnh export giữ tên tệp cũ |
| D-02 | Tệp đính kèm và báo cáo PDF lưu qua **Cloudinary** (Media API) thay cho Firebase Cloud Storage | Đã kiểm chứng 11/11: project ở gói Spark, console báo "Storage requires a billing account (Blaze)" nên bucket `prm323-lab2-gr6.firebasestorage.app` không tồn tại; upload trả HTTP 404 (`StorageException -13010`). Giảng viên cho phép Cloudinary/S3 thay thế. `firebase/storage.rules` vẫn giữ trong repo cho môi trường có bucket. Bằng chứng: `evidence/app/export-cloudinary-2026-11-11/`, `evidence/artemis/logs/TC-10-manual-repro-2026-11-11.log`. | Không đổi UI; nhãn nút + consent tự đổi theo provider ("…lên Cloudinary"). Ghi trong `docs/architecture.md` |
| D-03 | Bỏ ràng buộc email `@fpt.edu.vn`; mọi tài khoản Google đều đăng nhập được | Firebase Auth của project không bật domain restriction; app không tự chặn để tránh khoá nhầm tài khoản demo. Vai trò được kiểm soát ở `users/{uid}.role` (mobile) và web admin. | Có — màn hình đăng nhập không còn nhắc domain |
| D-04 | SCR-05.05/05.06 gộp vào một màn hình kết quả, không tách local/AI | Hai màn hình chỉ khác nhãn nguồn; gộp giảm điều hướng và tránh trùng lặp state. Nhãn nguồn vẫn hiển thị. | Có — `design/screen-spec.md` ghi chú gộp |
| D-05 | SCR-05.07 (loading) không phải route riêng | Là trạng thái `_isLoading` của `AdvisorViewModel`; route riêng sẽ tạo màn hình trống khi mạng chậm. | Có |
| D-06 | Thêm màn hình Đăng nhập, Trung tâm thông báo, Thông báo hệ thống, Bí kíp của tôi, Hỏi AI ghi chú | Lab 3 yêu cầu đăng nhập + FCM + demo area; Final yêu cầu inbox realtime và AI feature. Dùng cùng design system. | Có — bổ sung page 07 |
| D-07 | Trang chủ hiển thị dữ liệu thật từ Firestore thay vì dữ liệu mẫu trong prototype | Lab 3 cấm dữ liệu mock trong bản nộp. | Có |
| D-08 | Thêm web admin (Flutter/JS) ngoài phạm vi Figma mobile | Final yêu cầu vai trò Staff/Admin trên web; dùng lại token và component tương đương. | Có — page 08 |

## 5. Đối chiếu kiểm thử

| Luồng | Test Flutter (hermetic) | ARTEMIS E2E |
|---|---|---|
| Đăng nhập / đăng xuất | `test/viewmodels/session_regression_test.dart`, `test/services/version_gate_test.dart` | `TC_01`, `TC_02`, `TC_12`, `TC_S_01` |
| Lộ trình / tìm kiếm / chi tiết | `test/viewmodels/roadmap_viewmodel_test.dart`, `test/viewmodels/roadmap_major_test.dart`, `test/screens/course_detail_tabs_test.dart` | `TC_F1_01`, `TC_F1_02`, `TC_05`, `TC_09`, `TC_14` |
| Task | `test/viewmodels/tasks_notes_test.dart`, `test/services/firestore_tasks_regression_test.dart` | `TC_F2_01`, `TC_F2_02`, `TC_F2_05`, `TC_V1` |
| Ghi chú / đính kèm | `test/viewmodels/note_attachment_test.dart` | `TC_F3_01`, `TC_F3_02`, `TC_F3_03` |
| Đồng bộ / xuất PDF | `test/services/report_export_service_test.dart`, `test/sync_vault_flow_test.dart` (D-01_SyncConfirmation, SyncError + Thử lại, Back về Home) | `TC_10`, `TC_F2_05`, `TC_V1`, `TC_F3_03` |
| Cố vấn AI / chiến lược | `test/viewmodels/advisor_viewmodel_test.dart`, `test/screens/strategy_sim_test.dart` | `TC_08`, `TC_F1_04` |
| Thông báo / FCM | `test/viewmodels/notifications_test.dart`, `test/services/notification_routing_test.dart` | `TC_13`, `TC_X_06`, `TC_S_07` |
| Remote Config | `test/services/study_plan_ai_test.dart`, `test/services/analytics_wiring_test.dart` | `TC_11`, `TC_S_06` |
| Phiên khám phá | — | `TC_EXPLORATORY_20min` |

> Trạng thái chạy thật của ARTEMIS nằm trong `docs/test-plan.md` và
> `evidence/artemis/`. Bảng này chỉ ánh xạ, không tuyên bố PASS.

## 6. Ghi chú kỹ thuật đã kiểm chứng

- Ảnh chụp và URL tải xuống của tệp đính kèm nằm dưới `notes/{uid}/` (Cloudinary) và
  được đọc bằng phiên Firebase hiện tại; tệp cũ chỉ có URL vẫn hiển thị tên.
- Báo cáo PDF được tạo trên thiết bị, lưu metadata trong `users/{uid}/sync/{reportId}`
  và chia sẻ qua `printing`; không cần bucket Storage.
- Dữ liệu học tập (điểm thành phần, môn đã qua) do người dùng nhập, lưu ở
  `users/{uid}`; không có dữ liệu mẫu trong bản build.
