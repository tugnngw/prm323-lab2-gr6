# Hợp đồng dữ liệu mobile ↔ web quản trị

Nguồn sự thật duy nhất về cấu trúc Firestore mà mobile, web và rules cùng tuân theo. Mọi thay đổi schema phải cập nhật đồng thời `firebase/firestore.rules`, `packages/core/lib/study_pilot_core.dart` và tài liệu này.

## 1. Quy ước chung

- Project `prm323-lab2-gr6`, Firestore Native `(default)`.
- Đăng nhập Google; vai trò đọc từ `users/{uid}.role` (`user|staff|admin`). Custom claim `role`/`admin` chỉ là fallback phụ.
- Mobile dành cho `user`; web quản trị dành cho `staff`/`admin`. Staff/Admin bị chặn nộp bài như sinh viên.
- Không seed/mock dữ liệu chương trình đào tạo. Ngành/môn chỉ đến từ file FLM hoặc form nhập tay của cán bộ.
- Mọi document ghi từ client đều có `createdAt`/`publishedAt`/`receivedAt` bằng `request.time` khi rules yêu cầu.
- Xoá dữ liệu cũ trên web chỉ tác động `majors`, `courses`, `curriculums`; không xoá người dùng, thông báo, bí kíp hay đơn kế hoạch.

## 2. Bảng collection

| Path | Trường chính | Quyền |
|---|---|---|
| `users/{uid}` | `role`, tên hiển thị, chuyên ngành, học kỳ, hồ sơ học vụ, `componentScores`, `academicDataSource`, `academicUpdatedAt` | Chủ đọc/cập nhật hồ sơ, **không được đổi `role`**; admin đổi đúng trường `role` cho người khác. Tạo mới chỉ với `role=user`, `admin=false`, tối đa 40 trường. |
| `users/{uid}/tasks/{taskId}` | `id` (trùng doc ID), `title`, `category`, `dueDate`, `isCompleted`, `courseCode`, … | Chỉ chủ sở hữu. Doc ID canonical; legacy `data.id` khác doc ID được giữ ở `legacyId`. |
| `users/{uid}/notes/{noteId}` | `title`, `content`, `courseCode`, `updatedAt`, `attachments[]` (`name`, `path`, `storage`, `size`, `contentType`) | Chỉ chủ sở hữu. Đính kèm có thể ở Firebase Storage hoặc Cloudinary tùy metadata. |
| `users/{uid}/sync/{syncId}` | Metadata lần đồng bộ gần nhất | Chỉ chủ sở hữu. |
| `users/{uid}/courseProgress/{courseDocId}` | `courseDocId`, `completedSlotNumbers` (int[]), `courseCompleted` (bool), `lecturer` (string) | Chỉ chủ sở hữu. Không ghi vào `courses`, vì tiến độ là dữ liệu cá nhân. |
| `users/{uid}/notifications/{notificationId}` | `title` ≤140, `body` ≤300, `type`, `read`, `receivedAt`, `route`, `routeArgument`, `recipientId`, `actorId` | Chủ đọc/sửa/xoá. Ngoại lệ duy nhất: người chấm bí kíp được **tạo một** bản ghi `tip_rating` cho tác giả với ID `tip_rating_<...>`, route `/course-tips`, `read=false`, `receivedAt=request.time`. |
| `users/{uid}/tokens/{tokenPrefix}` | `token`, `updatedAt` | Chỉ chủ sở hữu. Doc ID là 24 ký tự đầu của token để mỗi thiết bị một dòng. Không log token. |
| `majors/{code}` | `code`, `name`, `nameEn`, `description`, `totalSemesters` 1–12, `source` (`manual`/`flm_html`), `archived` | Đăng nhập đọc; staff/admin ghi. `code` phải trùng doc ID. |
| `courses/{major}__{code}` hoặc `courses/{code}` | `code`, `name`, `nameVi`, `credits` 0–30, `semester` 0–12, `major`, `overview`, `studentTasks`, `tools`, `degreeLevel`, `timeAllocation`, `scoringScale`, `minAvgMarkToPass`, `learningTeachingMethod`, `note`, `decisionNo`, `approvedDate`, `prerequisites`, `slots`, `labs`, `learningOutcomes`, `courseMaterials`, `constructiveQuestions`, `electiveGroups`, `totalSlots`, `completedSlots`, `resourceLinks`, `link`, `syllabusId`, `syllabusStatus` (`complete|partial|metadata|manual`), `archived` | Đăng nhập đọc; staff/admin ghi. ID ghép cho phép cùng môn nằm trong nhiều ngành; rules vẫn nhận ID cũ `{code}`. |
| `curriculums/{id}` | Dữ liệu Lab 3 cũ | Đăng nhập đọc; staff/admin chỉ xoá; không tạo/cập nhật. |
| `experience_notes/{noteId}` | `courseDocId`, `courseCode`, `courseName`, `major`, `uid`, `authorName`, `title` 3–120, `content` 20–2000, `lecturerTip` ≤500, `examTip` ≤500, `rating` 0–5, `status`, `createdAt`; sau duyệt thêm `reason`, `reviewedBy`, `reviewedAt` | Sinh viên tạo `pending`, `uid` của mình, môn phải tồn tại. Chủ đọc note của mình; mọi người đọc `approved`; staff/admin đọc tất cả và duyệt `pending → approved/rejected` với lý do 1–300. Chủ xoá `pending`; admin xoá mọi note. |
| `tip_ratings/{tipId}__{uid}` | `tipId`, `courseDocId`, `uid`, `displayName` ≤80, `stars` 1–5, `createdAt` | Đăng nhập đọc; mỗi sinh viên tạo/sửa/xoá đánh giá của mình. ID ghép bảo đảm một đánh giá/tip/người. |
| `tip_comments/{commentId}` | `tipId`, `courseDocId`, `courseCode`, `uid`, `authorName`, `content` 1–1000, `createdAt` | Đăng nhập đọc/tạo; không sửa; tác giả hoặc admin xoá. Bình luận không kiểm duyệt. |
| `announcements/{id}` | `title` 1–120, `body` 1–1000, `authorUid`, `publishedAt` | Staff/admin đăng bằng UID mình; đăng nhập đọc; admin xoá. |
| `study_plan_submissions/{uid}_{semester}` | `uid`, `semester` 1–12, `summary` 1–600, `status`, `reason` ≤300, `createdAt`; sau duyệt thêm `reviewedAt`, `reviewedBy` | Sinh viên tạo `pending` đúng ID cố định; staff/admin duyệt một lần sang `approved/rejected`. Web hiện **không** có màn duyệt collection này. |
| `audit_logs/{id}` | `userId`, `action` 1–100, `createdAt` | Append-only; chỉ tạo bản ghi của chính mình, tối đa 3 trường; không đọc/sửa/xoá từ client. |

## 3. Chuyển trạng thái

```text
experience_notes:  (none) ──create(pending)──► pending ──staff/admin──► approved | rejected
study_plan:        (none) ──create(pending)──► pending ──staff/admin──► approved | rejected
```

- Không có chuyển ngược hoặc duyệt lại; rules chặn bằng `resource.data.status == 'pending'` và `affectedKeys().hasOnly([...])`.
- Lý do bắt buộc khi duyệt/từ chối; `reviewedBy` phải bằng UID người duyệt; `reviewedAt` phải bằng `request.time`.

## 4. Ràng buộc nghiệp vụ

- **Điểm do sinh viên tự nhập** trong hồ sơ; admin không nhập điểm thay. `componentScores` lưu theo môn, có `academicDataSource: user_entered`.
- **Tiên quyết** nằm trong `courses.prerequisites` (mã môn hoặc ghi chú điều kiện). Mobile chỉ cảnh báo, không tự sửa catalog.
- **Đề cương thiếu**: `syllabusStatus: metadata` + mảng rỗng; mobile hiện "chưa cập nhật đề cương", không sinh slot/LO giả.
- **Đính kèm**: metadata ghi rõ `storage: cloudinary|firebase`; app chọn đúng adapter khi tải/xoá.
- **Dashboard web**: `getCountFromServer` cho số liệu tổng hợp; `onSnapshot` cho bảng/biểu đồ realtime.
- **Thông báo tip**: chỉ dùng cho hoạt động chấm bí kíp; nội dung cố định, không chứa dữ liệu cá nhân ngoài tên hiển thị do người dùng đã công khai.

## 5. Index

`firebase/firestore.indexes.json` khai báo index cho các truy vấn lọc `status`/`courseDocId`/`uid` kết hợp sắp xếp `createdAt`. Khi thêm truy vấn mới, cập nhật index và deploy cùng rules.
