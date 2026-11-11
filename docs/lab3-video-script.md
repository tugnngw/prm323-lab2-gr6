# Kịch bản demo Lab 3 trên điện thoại thật

Thời lượng mục tiêu 7 phút 55 giây. Chuẩn bị Android có Google Play Services, APK đúng Firebase project, tài khoản FPT demo, web admin chạy trên máy chấm và kết nối mạng. Bật ADB reverse và chạy Media API trước khi quay Cloudinary và Gemini.

| Cảnh | Thời lượng | Hành động và lời giải thích |
|---|---:|---|
| Mở đầu | 0:20 | Giới thiệu FPTU Second Brain, model điện thoại và Android version. |
| Auth | 0:35 | Đăng nhập bằng tài khoản FPT demo. Giải thích UID từ Firebase Auth và Firestore Rules theo chủ tài khoản. |
| Bắt đầu test crash | 0:45 | Web admin ghi số event hiện tại. Trong Sync Vault, bấm Gây test crash rồi mở app lại. SDK gửi báo cáo ở lần mở lại, Firebase xử lý bất đồng bộ. |
| Lộ trình | 0:35 | Tìm PRM323, mở ba tab và kiểm tra dữ liệu thực. Giải thích lịch và đầu điểm chưa có thì app hiển thị trạng thái trống. |
| Công việc và ghi chú | 0:50 | Tạo dữ liệu thử, hoàn thành task và bấm Hoàn tác. Mở ghi chú và giới thiệu cache Firestore. Chỉ nói đã thử offline nếu có kết quả thực. |
| FCM | 0:55 | Mở code gửi trên server, chạy bằng UID tài khoản demo. Thử mở banner khi foreground, chạm notification khi background/cold start. Giải thích registration token và OAuth server. |
| PDF | 0:50 | Mở hộp xác nhận, hủy một lần, đồng ý lần sau. Quay upload, metadata Firestore và tải lại từ Lịch sử báo cáo. |
| Gemini | 0:30 | Mở Cố vấn, hỏi PRM323 có bao nhiêu tín chỉ, xác nhận gửi. Chỉ câu trả lời Gemini và phần đối chiếu trên thiết bị. |
| Remote Config | 0:35 | Cho thấy giá trị 30 trong app và bằng chứng 31 → 30 cùng APK. Demo đổi live chỉ khi đã chuẩn bị cấu hình thử riêng. |
| Web admin và Analytics | 0:55 | Tải lại dashboard web và chỉ nhóm crash vừa cập nhật nếu đã nhận. Dev mở Firebase Console để đối chiếu. Mở DebugView xem event và tham số có evidence. |
| ARTEMIS và review | 0:40 | Chiếu report chạy máy thật khi có. Nêu kết quả theo số lượt thực, chỉ các finding và thay đổi đã xác minh. |
| Kết | 0:25 | Chỉ README, evidence và các giới hạn còn lại. |

Dùng cảnh quay điện thoại thật lúc chấm. Che email, UID, token và credential trong hình. Lấy kết quả crash trước/sau cùng khoảng lọc trên web admin. Nếu chưa thấy crash mới khi hết thời lượng, ghi nhận đang chờ và đối chiếu kết quả sau. Video chưa được quay khi chưa có thiết bị thật.

Xem [cách chạy web và lệnh FCM](../admin-web/README.md) và [ghi chú trả lời khi chấm](lab3-oral-defense.md).
