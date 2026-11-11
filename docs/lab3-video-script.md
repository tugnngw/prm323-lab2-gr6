# Kịch bản video demo Final — StudyPilot (GR6)

Thời lượng mục tiêu **8–12 phút** (kịch bản dưới khoảng 10 phút). Quay song song màn hình điện thoại thật và trình duyệt web để thấy dữ liệu cập nhật realtime. Chuẩn bị: APK đúng Firebase project `prm323-lab2-gr6`, tài khoản Google demo cho `user` và `staff`, web admin tại <https://prm323-lab2-gr6.web.app/>, điện thoại bật ADB (serial thật) và ARTEMIS đã cấu hình.

| Cảnh | Thời lượng | Hành động và lời giải thích |
|---|---:|---|
| Mở đầu | 0:30 | Giới thiệu StudyPilot, nhóm GR6, hai client dùng chung một backend Firestore. Nêu cấu trúc repo: `lib/` mobile, `admin-web/` web, `packages/core/`, `firebase/`, `e2e_test/`. |
| Mobile — luồng Lab 2 | 1:30 | Đăng nhập Google, trang chủ, lộ trình, tìm môn, chi tiết môn 3 tab, việc cần làm + Hoàn tác, ghi chú + tệp đính kèm. Dữ liệu môn lấy từ Firestore, không mock. |
| Mobile — Vault, PDF, AI | 1:00 | Sync Vault, xuất PDF và upload Cloudinary (consent trước khi upload), mở Cố vấn AI. Chỉ nêu kết quả có trên màn hình. |
| Hòm thư realtime | 0:40 | Mở **Hòm thư / Thông báo hệ thống**; để nguyên màn hình khi web đăng thông báo ở cảnh sau để thấy tin nhắn xuất hiện không cần reload. |
| Web — đăng nhập và phân quyền | 1:00 | Mở URL Hosting, đăng nhập Google bằng tài khoản staff. Thử một tài khoản không phải staff/admin để thấy thông báo từ chối. |
| Web — quản lý dữ liệu | 1:00 | Tìm kiếm, tạo mới, sửa và lưu trữ một ngành/môn; mở mobile kiểm tra dữ liệu vừa đổi. |
| **Cross-role hai màn song song** | 2:00 | Mobile: gửi bí kíp (trạng thái *Chờ duyệt*). Web: mở **Duyệt yêu cầu**, thấy bản ghi pending, nhập lý do và bấm **Duyệt**. Mobile: trạng thái đổi ngay **không reload** và Hòm thư nhận tin nhắn `tip_review` kèm lý do. Lặp lại một lần với **Từ chối** nếu còn thời lượng. |
| Web — dashboard và form thông báo | 1:00 | Chỉ 3 số liệu aggregation (tổng sinh viên, bí kíp chờ duyệt, bí kíp đã duyệt, ngành) và biểu đồ trạng thái. Soạn thông báo → mobile Hòm thư nhận realtime. |
| AI Level 2 + Remote Config | 1:00 | Mở gợi ý kế hoạch học tập: JSON có cấu trúc được parse thành model, người dùng sửa rồi mới dùng. Mở Firebase Console tắt cờ `study_plan_ai_enabled` → tải lại app, nút AI tự ẩn và form nhập tay vẫn hoạt động, không sửa code. |
| Rules + ARTEMIS trên máy thật | 1:00 | Chạy `npm run test:emulator` (17/17) và chiếu điện thoại thật đang chạy ARTEMIS. Nêu kết quả từng lượt trong `evidence/artemis/`. |
| Kết | 0:20 | Chỉ README, `docs/`, `report/Final_GR6.pdf`, `slides/`, bằng chứng và link video. |

Che email, UID, token và credential trong hình. Không nói "đã chạy" cho cảnh chưa quay được; cảnh nào chưa có kết quả thì bỏ khỏi video thay vì suy diễn. Xem thêm [cách chạy web](../admin-web/README.md) và [ghi chú trả lời khi chấm](lab3-oral-defense.md).
