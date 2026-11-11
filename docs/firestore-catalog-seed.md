# Firestore Catalog Seed (Safe, Idempotent)

> **Đã thay thế và xóa file seed (09/11/2026):** không còn seed chương trình đào tạo từ file mẫu và `firebase/seed_data.json` đã được bỏ khỏi repo. Cán bộ nhập chuyên ngành thật từ HTML FLM tại **Web quản trị → Chuyên ngành → Thêm chuyên ngành → Nhập từ file HTML FLM** (xem `docs/cross-role-flow.md`). Tài liệu dưới đây chỉ còn giá trị lịch sử cho Lab 3.

Purpose: populate Roadmap catalog when `courses` is empty. No code, Rules, billing, or cloud data changes happen automatically.

## Why emulator shows empty Roadmap

`RoadmapViewModel` reads default Firestore database collection `courses`, ordered by `semester`. It does not import local JSON. `firebase.json` has no emulator import/export configuration, so a fresh emulator has no documents. App also intentionally shows empty state when no authenticated UID exists.

> **`curriculums` là collection reserved**: `firestore.rules` cho phép đọc khi đăng nhập nhưng
> **không** screen nào của app đọc nó và Lab 2/3 không định nghĩa schema — intentionally NOT seeded.
> Khi được hỏi trong báo cáo/nộp bài: nêu rõ đây là chỗ mở rộng (multi-curriculum) đã chuẩn bị
> rules từ Lab 3, dữ liệu sẽ seed khi có màn hình dùng.

Expected document path:

```text
courses/{courseId}
```

Expected fixed IDs: `PRM323`, `SWP391`, `SWR302`, `SWT301`.

## Manual Console procedure

1. Sign in to app with Google Sign-In.
2. Open Firebase Console for project `prm323-lab2-gr6` → Firestore Database → Data.
3. Upsert each fixed document ID under root collection `courses` using fields from `docs/seed-courses.json`.
4. Preserve existing documents. Overwrite only intended catalog fields. Re-running same IDs is idempotent; do not delete or migrate documents.
5. Upsert root document `users/{actual Firebase UID}` with:
   - `passedCourses`: array from `userProfileTemplate`
   - `major`: `SE`
   - `expectedGraduation`: `2026`
6. Reopen Roadmap, keep semester 5 selected, and verify `PRM323`, `SWP391`, and `SWR302` appear.

Client app cannot seed this catalog: Firestore Rules allow authenticated catalog reads but deny client writes. Use Firebase Console or an authorized Admin SDK run by project owner. Never put service-account credentials in repo or logs.

## Emulator note

Emulator data is separate from deployed Firebase data. If using an emulator workflow, import a previously exported dataset with Firebase CLI `--import` / `--export-on-exit` under a user-controlled local directory. Do not run import/export against deployed data and do not commit credentials or emulator exports containing private user data.

## Source schema

`CourseModel.fromMap` requires `code`, `name`, `credits`, `semester`, and `major`; `prerequisites` is supported. Optional fields include `totalSlots`, `completedSlots`, `currentGrade`, `status`, `lecturer`, and `labs`. `docs/seed-courses.json` is canonical for this manual seed; `firebase/seed_data.json` is older and smaller.
