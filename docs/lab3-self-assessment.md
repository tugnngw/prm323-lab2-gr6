# Lab 3 — Tự đánh giá theo rubric (guide v5 tr.23–25, 13 dòng)

> Ngày đánh giá: 2026-11-03 (trước khi nộp sẽ chạy lại lần cuối).
> Trạng thái: ✅ đạt đầy đủ · 🟡 một phần (nợ nêu ở cột bằng chứng) · ⬜ chưa (chờ phase).
> Nguyên tắc: chỉ ✅ khi có bằng chứng ở `evidence/` hoặc test chạy được; hermetic test
> không được tính là runtime PASS (guide tr.23).

| # | Rubric item | Đạt? | Bằng chứng / nợ còn lại |
|---|---|---|---|
| 1 | ≥10 ca kiểm thử ARTEMIS (điều kiện đầu, bước, kết quả mong đợi) | 🟡 | 26 cases authored + docstring điều kiện/assert (`e2e_test/`, mapping `docs/test-plan.md` §1b). **Nợ: chưa chạy** (E1: uv + ARTEMIS host + API key) |
| 2 | Bao phủ các luồng Lab 2, một nhánh lỗi, một tương tác Android gốc | 🟡 | Code phủ: F1/F2/F3 + TC-S-01..07 lỗi từng dịch vụ + native (wifi toggle `svc`, `pm revoke/grant`, screencap qua adb). **Nợ: chứng minh bằng trace chạy thật** |
| 3 | Mỗi ca chạy ≥3 lần, báo cáo tỷ lệ đạt + nhật ký thực thi | ⬜ | Khung bảng ở `docs/test-plan.md` §3; runs + logs tự ghi `evidence/artemis/logs/` khi E3 chạy |
| 4 | Assert giá trị quan sát được, không chỉ SUCCESS | ✅ (thiết kế) | Mỗi test assert chuỗi/log/doc cụ thể (logcat `Sign-In succeeded`, không `FirebaseException`, `Thử lại`, download URL); fixture `evidence_shot` + logcat capture (`e2e_test/conftest.py`) |
| 5 | Một phiên khám phá 15–30′ | ⬜ | Kịch bản + harness ≥600s đã sẵn (`test_exploratory.py`, Pro profile). Chờ E3 |
| 6 | Rà soát PR bằng Copilot/CodeRabbit/tương đương | ⬜ | Phase F — chờ code freeze + PR. `docs/code-review.md` **không tạo trước khi có output thật** (chống bịa) |
| 7 | ≥5 phát hiện gắn dòng mã, ≥2 nhóm | ⬜ | chờ #6 |
| 8 | Accept/Modify/Reject từng phát hiện + lý do kỹ thuật | ⬜ | Format bảng đã định nghĩa trong task map F2; quyết định ghi cả `ai/ai-code-log.md` §3.4 |
| 9 | Sửa ≥3 phát hiện, commit truy vết riêng | ⬜ | `fix(CR-01..03)` — chờ #6 |
| 10 | 6 dịch vụ Firebase tích hợp; mỗi dịch vụ có ca lỗi | 🟡 | 6/6 tích hợp + verify sign-in/CRUD 02/11; ca lỗi TC-S-01..07 authored. **Nợ: chạy thật trên device/Console** |
| 11 | Tài liệu traceability thiết kế + kiến trúc + Analytics plan | ✅ | `docs/design-traceability.md`, `docs/architecture.md` (2 sơ đồ), `docs/analytics-plan.md` (13 events khớp 1-1 code, 03/11) |
| 12 | Lưu nhật ký ARTEMIS, ảnh Console, quyết định review | ⬜ | Cây `evidence/` §10.1 đã dựng sẵn + README naming (03/11); ảnh chờ N-2/N-3; review chờ F |
| 13 | GitHub + report 8–12tr + slides 12–15tr + video 5–10′ | 🟡 | Repo có, public + rename khi nộp (DEC-05); outline report/slides + kịch bản video xong (`docs/lab3-*-outline.md`, `docs/lab3-video-script.md`). Bản final chờ evidence + quay |

**Tổng kết giữa kỳ nộp:** 2 ✅, 5 🟡, 6 ⬜ — toàn bộ ⬜ nằm sau 3 gate phía user:
E1 (ARTEMIS setup), ảnh Console/device, và PR reviewer (quyền repo).
