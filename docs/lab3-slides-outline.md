# Lab 3 Slides — Outline 12–15 trang (draft G3, 03/11)

> Mỗi slide: tiêu đề + 3–5 bullet + 1 visual. ⏳ = chờ bằng chứng runtime; placeholder ảnh
> lấy từ `evidence/`. Presenter note gợi ý dưới mỗi slide.

| # | Slide | Nội dung chính | Visual | Note |
|---|---|---|---|---|
| 1 | Title | FPTU Second Brain — Lab 3 Cloud-Enabled Mobile App; SV, repo, ngày | screenshot Home ⏳ | 10″ |
| 2 | Lab 2 → Lab 3 | Prototype offline → Firebase cloud, dữ liệu thật, E2E + AI review | before/after 2 màn | 20″ |
| 3 | Personas & 3 flows | P01/P02/P03; F1 Curriculum, F2 Plan/Notes, F3 Advisor | user-flow cắt tép | 20″ |
| 4 | Kiến trúc MVVM | View→VM→Service→Firebase; 0 SDK call từ Widget | diagram architecture | 30″ |
| 5 | Fail-loud | Bỏ mock fallback; `FirebaseConfigErrorApp`; error+revert UI | 2 ảnh lỗi thật ⏳ | 30″ — decision highlight |
| 6 | Auth + domain gate | Google Sign-In, `hostedDomain` + check server `invalid-domain`, sign-out ngoại domain | logcat `Sign-In succeeded` ⏳ | 30″ |
| 7 | Firestore & rules | Collections, owner-scoped default-deny, offline persistence, canonical-ID fix | snippet rules + doc tree | 40″ |
| 8 | Storage & PDF export | Consent → generate (DejaVu VI) → `reports/{uid}` → progress → URL | 3 ảnh ⏳ | 40″ |
| 9 | Analytics/Crashlytics/RC/FCM | 11 events + PII filter; custom key; `maintenance_mode`; token 3 trạng thái + Notification Center | DebugView + dashboard ⏳ | 40″ |
| 10 | Test chiến lược | Kim tự tháp: 68/68 hermetic ≠ runtime; TC map 3 flow + error + native adb | test-plan ma trận | 30″ |
| 11 | ARTEMIS results | 26 cases; Flash/Pro; assert observable values; pass rate ×3 runs; exploratory 15–30′ | runs table + trace ⏳ | 45″ — slide ăn điểm, để dành số thật |
| 12 | AI Code Review | ≥5 findings ≥2 nhóm, decision table, 3 × `fix(CR-0x)` | snippet code-review.md ⏳ | 30″ |
| 13 | Challenges & fixes | BUG-01/02, evidence audit liêm chính, Spark limits | git log cut | 30″ |
| 14 | Demo video | Nhúng/chiếu video 5–10′ đã dựng (mục 2, 5, 8, 11 của script) | video ⏳ | 1–2′ |
| 15 | Wrap | Tuân thủ rubric checklist, repo/evidence layout, cảm ơn | QR repo | 15″ |

**Quy tắc:** không slide nào khẳng định PASS runtime khi ⏳ chưa thay bằng ảnh/số thật (guide tr.23).
