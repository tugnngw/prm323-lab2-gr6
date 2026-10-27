# Mo rong tu van hoc vu FPTU — dac ta da chot

Tai lieu dac ta phan mo rong hoc vu ben canh ba luong Lab 2 hien co. Prototype dung du lieu mau; khong khang dinh da tich hop FAP/FLM that.

## Tom tat muc tieu
- Mo rong FPTU Second Brain Mobile cho sinh vien tu nam nhat den nam cuoi.
- Giu ba flow Lab 2 hien tai; them ba workflow: thiet lap/catalog, tu van da cap do (2.1), chien luoc hoc tap (2.2).
- Catalog FLM duoc dong bo qua kenh duoc phep; nguoi dung chon nganh/chuong trinh/khoa de tai offline.
- Ket noi FAP la tuy chon cho du lieu ca nhan nhu diem, thoi khoa bieu, chuyen can va dieu kien hoc vu.
- Du lieu ca nhan mac dinh luu cuc bo; chi gui phan toi thieu cho AI sau consent rieng tung lan.
- Tich hop that can quyen va kenh chinh thuc cua FPTU. Khong tu thu thap du lieu trai phep hoac yeu cau nguoi dung giao mat khau.

## Gia dinh da thong nhat
1. Prototype minh hoa bang du lieu mau co nhan; chua ket noi FPTU that.
2. Catalog FLM va du lieu ca nhan FAP la hai luong rieng; tai khoan cloud app khong dong nghia dang nhap FAP.
3. Nguoi dung tu chon nganh/chuong trinh/khoa muon tai catalog.
4. FAP la tuy chon qua luong chinh thuc; khong ket noi thi cac tinh nang ca nhan chi co du lieu mau/nhap tay co nhan.
5. AI khong nhan bang diem/lich ca nhan truoc khi nguoi dung xem va cho phep chia se mot lan. Tu choi van co the dung quy tac cuc bo.
6. Dieu kien thi, prerequisite, Capstone, OJT, diem dat va hoc cai thien phu thuoc quy che/nganh/khoa. Luon hien thi nguon, phien ban/ngay hieu luc; khong khang dinh nguong chung khi chua co nguon.
7. Muc tieu duoi 2 giay cho noi dung da cache la muc tieu can do, khong phai cam ket.

## Decision log
| Quyết định | Phương án cân nhắc | Lý do |
|---|---|---|
| Giữ 3 flow Lab 2, thêm 3 workflow (tổng 6) | Thay flow cũ | Bảo toàn phạm vi Lab 2 và thể hiện phần mở rộng |
| Chia mã theo module chức năng | Theo thứ tự prototype | Ổn định khi đổi luồng, phân biệt module/màn hình con |
| Tách catalog FLM và dữ liệu cá nhân FAP | Gộp một nguồn đồng bộ | Khác quyền truy cập, độ nhạy và cách lưu |
| FAP tùy chọn, local-first | Bắt buộc FAP từ đầu | Catalog vẫn dùng được và giảm thu thập dữ liệu |
| Consent theo từng lần gửi AI | Đồng ý một lần vĩnh viễn | Giữ quyền kiểm soát dữ liệu nhạy cảm theo ngữ cảnh |
| Tư vấn nêu nguồn và ngày/phiên bản | Trả lời AI không nguồn | Quy định khác nhau và có thể thay đổi |
| Dùng dữ liệu mẫu, tích hợp thật phụ thuộc cấp phép | Giả lập như đồng bộ thật | Tránh gây hiểu nhầm quyền truy cập/độ chính xác |

## Data flow va privacy
### Catalog hoc tap
Nguon FLM/nguon truong cho phep → dich vu dong bo catalog → nguoi dung chon nganh/chuong trinh/khoa → tai goi co phien ban ve may → tra cuu offline. Hien thi nguon, ngay cap nhat, trang thai. Offline thi dung ban cache va hien tuoi du lieu. Bulk sync chi khi co kenh/quyen chinh thuc.

### Du lieu FAP
Nguoi dung tu chon ket noi qua co che FPTU cho phep → diem/lich/chuyen can luu cuc bo theo chinh sach → tinh nang hien nguon va lan dong bo. Cho phep bo qua, ngat ket noi, xoa du lieu va thu hoi quyen. Khong luu mat khau FAP trong prototype; khong gui du lieu len cloud mac dinh.

### Chia se AI
Truoc khi gui, overlay liet ke dung cac truong du lieu va muc dich. Chon Khong chia se thi dung local rule engine; Chia se lan nay thi chi gui truong toi thieu, khong tai su dung cho lan sau. Thieu du lieu/quy tac xac minh thi hien Chua du du lieu.

## Ba workflow moi
### Workflow 4 — Thiet lap, tai catalog, xem thong tin co ban
SCR-00.01_AuthSetup → SCR-00.02_ProgramCatalog → SCR-01.0_Home → SCR-02.03_Curriculum → SCR-02.02_CourseDetail
- Giai thich tai khoan cloud app rieng voi FAP; co the bo qua FAP.
- Catalog loc/chon nganh, chuong trinh, khoa/co so; hien dung luong, phien ban, thoi diem dong bo. Prototype ghi ro du lieu mau.
- Home/Curriculum hien tien do tu catalog. GPA/tin chi ca nhan chi hien khi nguon da ket noi va xac minh.
- Nhanh tuy chon SCR-00.03_FAPConnect co giai thich pham vi va nut bo qua/quay lai.
- Prerequisite chi hien khi catalog dung chuong trinh/khoa; du lieu chua ro duoc danh dau chua xac minh.

### Workflow 5 — Tu van hoc vu da cap do (Muc 2.1)
SCR-05.01_AdvisorHub la man hinh hoi dap dung chung va co bon scope: Mon hoc, Ky hoc, Chuong trinh, Diem so.
- Mon hoc: de cuong, slot, cau truc danh gia/qua mon tu nguon dung phien ban.
- Ky hoc: so sanh tai hoc/deadline; khong tu dang ky lop.
- Chuong trinh: lo trinh/prerequisite, Capstone khi co curriculum dung; thu tuc hanh chinh dan nguon FPTU.
- Diem so: chi dung FAP da ket noi hoac du lieu mau/nhap tay co nhan; khong khang dinh cam thi neu thieu quy che va chuyen can tin cay.
- Moi tra loi hien nguon, ky/phien ban; phan biet du kien va goi y. Co trang thai offline/loi/khong du du lieu.

### Workflow 6 — Chien luoc hoc tap nang cao (Muc 2.2)
SCR-05.01_AdvisorHub → SCR-05.04_StrategySim → DLG-05.04_ShareConsent → SCR-05.02_Loading → SCR-05.03_Result
- Mo phong hoc lai/cai thien, tai nhieu mon, toi uu thoi khoa bieu; hien dau vao, gia dinh, quy tac, ky ap dung.
- Bat buoc hien overlay consent truoc khi gui diem/lich cho AI.
- Tu choi: tinh cuc bo bang quy tac da xac minh; thieu du lieu thi khong ket luan.
- Dong y: chi gui toi thieu du lieu da liet ke cho lan nay; hien dang phan tich va ket qua co nguon.
- Ket qua co the so sanh hoc lai/cai thien, can bang tai, lich du kien, prerequisite/Capstone/OJT neu quy tac xac minh. Khong dam bao du dieu kien; xac nhan cuoi tai FAP/phong dao tao.
- Cho phep huy, quay lai, xem nguon, xoa du lieu cuc bo, thu hoi quyen.

## Ma man hinh phan cap da chot
- SCR-00.01_AuthSetup — thiet lap app/tai khoan cloud.
- SCR-00.02_ProgramCatalog — chon/tai catalog.
- SCR-00.03_FAPConnect — ket noi FAP tuy chon.
- SCR-01.0_Home — home hien huu.
- SCR-02.03_Curriculum — tien do chuong trinh.
- SCR-02.02_CourseDetail — chi tiet mon hien huu.
- SCR-05.01_AdvisorHub — man hinh AI hien huu mo rong tu van da cap.
- SCR-05.02_Loading va SCR-05.03_Result — dung lai trang thai xu ly/ket qua.
- SCR-05.04_StrategySim — mo phong chien luoc moi.
- DLG-05.04_ShareConsent — overlay chia se mot lan.

Ma chuc nang khong phu thuoc so flow. Asset export cu co the giu alias cu trong handoff den khi doi ten co kiem soat.

## NFR va tieu chi demo
- Rieng tu: local-first cho FAP, consent tung lan, xoa/ngat ket noi, khong yeu cau luu mat khau.
- Tin cay: cache co phien ban/timestamp; dong bo loi khong ghi de transcript cuc bo.
- Offline: catalog da tai van tra cuu; hien gioi han du lieu cu.
- Hieu nang: muc tieu mo man tu cache <2 giay, can do tren thiet bi.
- Bao tri: quy tac co chu so huu, nguon, ngay hieu luc, phien ban va duyet truoc phat hanh.
- Demo: 6 flow entry (3 cu + 3 moi), bo qua FAP, tai catalog, 4 scope, consent ca tu choi/dong y, ket qua co nguon/nhan du lieu mau, back/error/recovery, khong dead-end.

## Nguon va gioi han xac minh
- FAP Helpdesk: timetable, grade report, transcript, attendance, dang ky hoc lai/cai thien: https://it.fpt.edu.vn/cantho/huong-dan-he-thong-academic-portal-fap/
- FLM co muc xem curriculum/syllabus va learning path: https://flm.fpt.edu.vn/login
- Quy che dao tao FPTU can kiem tra theo phien ban/nganh/khoa: https://daihoc.fpt.edu.vn/hoat-dong-nha-truong/tin-tuc-chung/quy-che-dao-tao-dai-hoc-chinh-quy/
- Trang cong khai khong chung minh API/bulk sync cho ung dung ngoai. Xac nhan tich hop, dieu khoan va bao mat voi FPTU truoc khi trien khai that.
