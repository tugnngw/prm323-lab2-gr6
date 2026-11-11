// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String kSlidesPath = 'slides/Final_GR6_slides.pdf';
const int kTotalSlides = 14;
const String kTeam =
    'Nguyễn Sỹ Thanh Tùng · Nguyễn Bá Thái Dương · Dương Quang Long · Võ Anh Duy';

void main() async {
  final regularBytes = File('assets/fonts/DejaVuSans.ttf').readAsBytesSync();
  final boldBytes = File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytesSync();
  final fontRegular = pw.Font.ttf(ByteData.view(regularBytes.buffer));
  final fontBold = pw.Font.ttf(ByteData.view(boldBytes.buffer));

  pw.TextStyle t(double size, {bool bold = false, PdfColor? color}) =>
      pw.TextStyle(
        font: bold ? fontBold : fontRegular,
        fontSize: size,
        color: color ?? PdfColors.grey900,
      );

  final doc = pw.Document(
    title: 'PRM393 Final — StudyPilot (GR6)',
    author: kTeam,
    subject: 'PRM393 Final Assignment — One Complete System on Firebase',
    keywords: 'PRM393, Final, Flutter, Firebase, StudyPilot, GR6',
  );

  pw.Widget header(String title, String category, int number) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.2),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(category.toUpperCase(),
                    style: t(7.5, bold: true, color: PdfColors.blue700)),
                pw.Text(title,
                    style: t(15, bold: true, color: PdfColors.blue900)),
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text('Slide $number / $kTotalSlides',
                  style: t(8, bold: true, color: PdfColors.white)),
            ),
          ],
        ),
      );

  pw.Widget footer() => pw.Container(
        padding: const pw.EdgeInsets.only(top: 5),
        margin: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('StudyPilot — PRM393 Final · GR6',
                style: t(7, color: PdfColors.grey600)),
            pw.Text('PRM393_Final_GR6 · 10/11/2026',
                style: t(7, bold: true, color: PdfColors.grey700)),
          ],
        ),
      );

  pw.Page slide(
    int number,
    String title,
    String category,
    List<pw.Widget> body, {
    bool cover = false,
  }) =>
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (pw.Context context) {
          if (cover) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: body,
            );
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              header(title, category, number),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: body,
                ),
              ),
              footer(),
            ],
          );
        },
      );

  pw.Widget box(String title, List<String> lines,
          {PdfColor color = PdfColors.blue50}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: t(10, bold: true, color: PdfColors.blue900)),
            pw.SizedBox(height: 3),
            for (final line in lines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('· $line', style: t(8.5)),
              ),
          ],
        ),
      );

  pw.Widget kv(String key, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(key, style: t(9, bold: true)),
            ),
            pw.Expanded(child: pw.Text(value, style: t(9))),
          ],
        ),
      );

  pw.Widget table(
    List<String> head,
    List<List<String>> rows, {
    required List<double> widths,
    double size = 8,
  }) =>
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: {
          for (var i = 0; i < widths.length; i++)
            i: pw.FixedColumnWidth(widths[i]),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              for (final h in head)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Text(h,
                      style: t(size, bold: true, color: PdfColors.blue900)),
                ),
            ],
          ),
          for (final row in rows)
            pw.TableRow(
              children: [
                for (final cell in row)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Text(cell, style: t(size)),
                  ),
              ],
            ),
        ],
      );

  // 1 — Cover
  doc.addPage(
    slide(1, 'Bìa', 'Giới thiệu', cover: true, [
      pw.Spacer(),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(22),
        decoration: const pw.BoxDecoration(
          color: PdfColors.blue900,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('TRƯỜNG ĐẠI HỌC FPT — PRM393 MOBILE PROGRAMMING',
                style: t(10, bold: true, color: PdfColors.blue200)),
            pw.SizedBox(height: 8),
            pw.Text('StudyPilot',
                style: t(30, bold: true, color: PdfColors.white)),
            pw.SizedBox(height: 5),
            pw.Text(
              'Một hệ thống hoàn chỉnh trên Firebase: mobile Android · web quản trị · AI có kiểm soát',
              style: t(12, color: PdfColors.grey200),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Nhóm GR6', style: t(10, bold: true)),
            pw.SizedBox(height: 3),
            pw.Text(kTeam, style: t(8.5)),
            pw.SizedBox(height: 3),
            pw.Text('PRM393 Final · 10/11/2026',
                style: t(8.5, color: PdfColors.grey700)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Repository: PRM393_Final_GR6', style: t(8.5)),
            pw.Text('Firebase: prm323-lab2-gr6', style: t(8.5)),
            pw.Text('Android: com.example.prm323_lab3', style: t(8.5)),
          ]),
        ],
      ),
      pw.Spacer(),
    ]),
  );

  // 2 — Persona & vấn đề
  doc.addPage(
    slide(2, 'Vấn đề và người dùng', 'Bối cảnh', [
      pw.Text(
        'Sinh viên cần biết môn nào học trước, việc nào sắp hạn và kế hoạch của mình đang ở đâu. '
        'Staff cần một hàng đợi để xử lý thay vì đọc tin nhắn rời rạc.',
        style: t(9.5),
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('P02 · Sinh viên (chính)', [
              'Tra đề cương, slot, tiên quyết',
              'Quản lý việc và ghi chú',
              'Hỏi AI, xuất PDF, nhận thông báo',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Staff · Cán bộ', [
              'Quản lý chuyên ngành/môn',
              'Duyệt bí kíp kèm lý do',
              'Đăng thông báo, xem dashboard',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Admin · Quản trị', [
              'Quyền của Staff',
              'Cấp role cho tài khoản',
              'Không ai tự đổi role mình',
            ]),
          ),
        ],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(7),
        decoration: const pw.BoxDecoration(color: PdfColors.amber50),
        child: pw.Text(
          'Phạm vi Final: không thêm tính năng mới; hoàn thiện luồng Lab 2/Lab 3, ghép hai client và chứng minh chạy end-to-end.',
          style: t(8.5, color: PdfColors.brown900),
        ),
      ),
    ]),
  );

  // 3 — Journey
  doc.addPage(
    slide(3, 'Từ Lab 2 và Lab 3 đến Final', 'Hành trình', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Lab 2 — Thiết kế', [
              'Figma, token, 8 màn hình',
              'Persona, user flow',
              'Handoff Flutter',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Lab 3 — Ứng dụng cloud', [
              'Flutter + Firestore thật',
              'FCM, Analytics, Crashlytics',
              'Remote Config, PDF, ARTEMIS',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Final — Một hệ thống', [
              'Mobile + web + backend chung',
              'Luồng liên vai trò realtime',
              'AI level 2 có RC và fallback',
            ]),
          ),
        ],
      ),
      kv('Đổi tên', 'StudyPilot; giữ applicationId để không phá Firebase binding'),
      kv('Dùng chung', 'packages/core (study_pilot_core) cho model và Firestore'),
      kv('Không làm mới', 'Không thêm tính năng ngoài rubric; ưu tiên hoàn thiện và bằng chứng'),
    ]),
  );

  // 4 — Architecture
  doc.addPage(
    slide(4, 'Kiến trúc hệ thống', 'Kiến trúc', [
      table(
        ['Thành phần', 'Công nghệ', 'Vai trò'],
        [
          ['Mobile', 'Flutter, Provider, MVVM', 'Luồng sinh viên, PDF, FCM, AI'],
          ['Web admin', 'SPA ES module + Hosting', 'Staff/Admin, duyệt, dashboard'],
          ['Shared', 'study_pilot_core', 'Model + Firestore dùng chung'],
          [
            'Backend',
            'Auth, Firestore, AI Logic, App Check, RC',
            'Danh tính, dữ liệu, quyền, cấu hình'
          ],
        ],
        widths: [95, 260, 380],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(7),
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        child: pw.Text(
          'Widget → ViewModel → Service → Firestore  ·  Firestore snapshot → ViewModel → AsyncViewState → UI\n'
          'Không SDK trong widget/ViewModel · Không server tùy chỉnh · Rules + App Check quyết định quyền',
          style: t(9, color: PdfColors.blue900),
        ),
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Trạng thái UI', [
              'loading / empty / data / error',
              'Nút thử lại ở mỗi màn',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Quan sát', [
              'Analytics event không PII',
              'Crashlytics user ID + custom key',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Cấu hình', [
              'Remote Config 9 tham số',
              'App Check cho Firestore + AI',
            ]),
          ),
        ],
      ),
    ]),
  );

  // 5 — Mobile
  doc.addPage(
    slide(5, 'Mobile — luồng sinh viên', 'Client 1', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Tra cứu', [
              'Trang chủ, lộ trình, tìm môn',
              'Chi tiết 3 tab, tiên quyết',
              'Dữ liệu đề cương thật',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Cá nhân', [
              'Việc cần làm + undo',
              'Ghi chú + tệp đính kèm',
              'Hồ sơ học tập tự nhập',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('AI & báo cáo', [
              'Cố vấn theo môn, consent',
              'PDF tạo tại thiết bị',
              'Lịch sử báo cáo',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Kết nối', [
              'Google Sign-In',
              'FCM 3 trạng thái',
              'Inbox thông báo realtime',
            ]),
          ),
        ],
      ),
      kv('Số màn hình', '18 file trong lib/screens (8 màn Lab 2 + mở rộng)'),
      kv('Bằng chứng', '159/159 test · APK debug/release pass · 10 ca ARTEMIS × 3 lượt trên giả lập'),
      kv('Giới hạn', 'E2E trên điện thoại thật chưa chạy vì thiết bị đang khóa'),
    ]),
  );

  // 6 — Web
  doc.addPage(
    slide(6, 'Web quản trị — Staff/Admin', 'Client 2', [
      table(
        ['Màn hình', 'Hành động chính', 'Trạng thái'],
        [
          ['Đăng nhập', 'Google Sign-In, từ chối sai role', 'Loading / lỗi'],
          ['Chuyên ngành', 'Tạo/sửa/archive, import FLM', 'Loading / empty / lỗi'],
          ['Duyệt bí kíp', 'Duyệt/từ chối kèm lý do', 'Realtime / empty / retry'],
          ['Dashboard', '≥ 3 số liệu + 1 biểu đồ', 'Loading / empty / lỗi'],
          ['Thông báo', 'Đăng announcements', 'Loading / empty / lỗi'],
        ],
        widths: [110, 330, 290],
        size: 8.5,
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Dữ liệu thật', [
              'Không seed/mock',
              'Import HTML FLM có preview',
              'Batch ghi majors + courses',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Chất lượng', [
              '14/14 test Node',
              'Banner lỗi + thử lại từng màn',
              'Token/màu theo Lab 2',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Deploy', [
              'Live: prm323-lab2-gr6.web.app',
              'URL công khai trong README',
              'Còn: ảnh checklist 5 màn',
            ], color: PdfColors.amber50),
          ),
        ],
      ),
    ]),
  );

  // 7 — Cross-role
  doc.addPage(
    slide(7, 'Luồng liên vai trò', 'Tích hợp', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('1 · Sinh viên gửi', [
              'experience_notes',
              'status = pending',
              'Chủ sở hữu + đủ trường',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('2 · Staff duyệt', [
              'approved / rejected',
              'Bắt buộc reason',
              'Chỉ 4 trường được đổi',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('3 · Mobile cập nhật', [
              'Snapshot listener',
              'Hiện trạng thái + lý do',
              'Không cần refresh',
            ]),
          ),
        ],
      ),
      table(
        ['Tài nguyên', 'Sinh viên', 'Staff', 'Admin'],
        [
          ['experience_notes', 'Tạo pending, đọc bản approved + của mình', 'Đọc tất cả, duyệt', 'Như Staff'],
          ['announcements', 'Đọc', 'Tạo', 'Tạo'],
          ['users.role', 'Không', 'Không', 'Đổi role người khác'],
        ],
        widths: [130, 300, 180, 120],
      ),
      pw.Text(
        'Bí kíp đã duyệt trở thành ngữ cảnh công khai cho AI. Chưa đo độ trễ 3 lượt trên hệ thống deploy.',
        style: t(8.5, color: PdfColors.brown900),
      ),
    ]),
  );

  // 8 — Data model
  doc.addPage(
    slide(8, 'Dữ liệu và phân quyền', 'Backend', [
      table(
        ['Collection', 'Nội dung', 'Ai ghi'],
        [
          ['users/{uid}', 'role, hồ sơ', 'Tự tạo user; Admin đổi role'],
          ['courses / majors', 'Đề cương, chuyên ngành', 'Staff/Admin'],
          ['experience_notes', 'Bí kíp + trạng thái', 'Sinh viên tạo; Staff duyệt'],
          ['announcements', 'Thông báo', 'Staff/Admin'],
          ['users/{uid}/tasks, notes', 'Việc, ghi chú', 'Chỉ chủ sở hữu'],
          ['audit_logs', 'Nhật ký quản trị', 'Append-only đúng chủ'],
        ],
        widths: [160, 250, 325],
        size: 8.5,
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Chuyển trạng thái', [
              'pending → approved / rejected',
              'Không sửa nội dung sau khi gửi',
              'Archive thay vì xóa cứng',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Ràng buộc', [
              'reviewedBy = UID người duyệt',
              'reviewedAt = request.time',
              'Một rating / người / bí kíp',
            ]),
          ),
        ],
      ),
    ]),
  );

  // 9 — Rules
  doc.addPage(
    slide(9, 'Security Rules và kiểm thử', 'Backend', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Nguyên tắc', [
              'Deny by default',
              'Role từ users/{uid}.role',
              'Kiểm schema + trạng thái',
              'Chặn tự nâng quyền',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Ví dụ', [
              'user tạo tip approved → deny',
              'staff duyệt pending → allow',
              'user tự đổi role → deny',
              'admin đổi role người khác → allow',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Kết quả', [
              '15/15 test pass',
              'Mỗi collection có allow + deny',
              'Emulator tách khỏi dữ liệu thật',
            ], color: PdfColors.green50),
          ),
        ],
      ),
      pw.Text(
        'Bản rules 04/11 đã deploy; bản siết 10/11 mới kiểm thử emulator — cần deploy lại cùng Hosting (G-09).',
        style: t(8.5, color: PdfColors.brown900),
      ),
    ]),
  );

  // 10 — AI
  doc.addPage(
    slide(10, 'AI — gợi ý kế hoạch học tập', 'Tính năng AI', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('1 · Chọn kỳ', [
              'Sinh viên chọn kỳ 1–12',
              'Không gửi dữ liệu cá nhân',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('2 · Gemini', [
              'Firebase AI Logic',
              'JSON goal + actions',
              'App Check bảo vệ',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('3 · Validate', [
              'goal ≤ 120 ký tự',
              '1–4 actions ≤ 100 ký tự',
              'Sai schema → bỏ nháp',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('4 · Người dùng', [
              'Nhãn "Bản nháp do AI tạo"',
              'Sửa rồi mới gửi',
              'Lỗi vẫn nhập thủ công',
            ]),
          ),
        ],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(7),
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        child: pw.Text(
          'Output thật (Kỳ 3): "Ôn PE/FE theo 30 slot; luyện đề C, toán, cơ sở điện toán; chia tuần theo đề cương."\n'
          '3/3 output hợp lệ trong evidence/ai/study-plan-2026-11-10-valid.json; 1 ca lỗi thật được xử lý.',
          style: t(8.5, color: PdfColors.blue900),
        ),
      ),
    ]),
  );

  // 11 — AI safety
  doc.addPage(
    slide(11, 'AI — cấu hình và an toàn', 'Tính năng AI', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Remote Config', [
              '9 tham số',
              'model, prompt, cờ bật/tắt',
              'Tắt cờ → ẩn nút AI',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('App Check', [
              'Firestore + AI Logic',
              'Debug token cho demo',
              'Play Integrity cho release',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Không PII', [
              'Chỉ số kỳ + đề cương công khai',
              'Không tên/email/điểm/lịch',
              'Event không chứa prompt',
            ]),
          ),
        ],
      ),
      table(
        ['Tình huống', 'Hành vi'],
        [
          ['Quota / mạng lỗi', 'Báo "AI chưa khả dụng", giữ form thủ công'],
          ['JSON sai schema', 'FormatException, ghi ai_error, không render'],
          ['Người dùng không đồng ý', 'Không gọi AI, vẫn gửi kế hoạch tay'],
        ],
        widths: [200, 535],
      ),
      pw.Text(
        'Chưa quay cảnh tắt cờ trên thiết bị; ảnh Console là hạng mục G-06.',
        style: t(8.5, color: PdfColors.brown900),
      ),
    ]),
  );

  // 12 — Testing
  doc.addPage(
    slide(12, 'Kiểm thử — kết quả và giới hạn', 'Bằng chứng', [
      table(
        ['Lớp', 'Kết quả', 'Ghi chú'],
        [
          ['flutter analyze', '0 issue', 'Toàn repo'],
          ['flutter test', '159/159 pass', 'Hermetic'],
          ['Rules emulator', '15/15 pass', 'Allow + deny theo vai trò'],
          ['Web Node', '14/14 pass', 'Parser + API'],
          ['ARTEMIS', '10 ca × 3 lượt', 'Giả lập; TC_14 fail'],
          ['AI model', '3 valid + 1 lỗi', 'evidence/ai'],
        ],
        widths: [150, 150, 435],
        size: 8.5,
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Còn mở', [
              '26 ca Final trên máy thật',
              'Exploratory ≥ 15 phút',
              'Checklist web trên URL deploy',
            ], color: PdfColors.amber50),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Nguyên tắc bằng chứng', [
              'Giả lập ≠ thiết bị thật',
              'Unit test ≠ E2E',
              'Không suy diễn kết quả chưa chạy',
            ]),
          ),
        ],
      ),
    ]),
  );

  // 13 — Review & lessons
  doc.addPage(
    slide(13, 'Review code và bài học', 'Chất lượng', [
      table(
        ['ID', 'Finding', 'Quyết định'],
        [
          ['CR-15', 'ViewModel import SDK Firebase/AI', 'Tách AiService, inject'],
          ['CR-18', 'Sync Vault để lại task rác', 'Marker + xóa đúng bản ghi'],
          ['CR-20', 'Rules cho tự khai admin', 'Chặn admin=false, giới hạn trường'],
          ['CR-21', 'Web lỗi để màn trắng', 'Banner lỗi + thử lại'],
        ],
        widths: [70, 300, 365],
        size: 8.5,
      ),
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Bài học', [
              'Quyền phải ở backend, không ở UI',
              'Listener cần trạng thái lỗi',
              'AI cần schema + đường thoát',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Nợ kỹ thuật', [
              'CR-27: 3 widget gọi thẳng FinalFirestore',
              'CR-28/29 đã đóng: event AI + test',
              'CR-30: uv.lock đã ghim ARTEMIS',
            ], color: PdfColors.amber50),
          ),
        ],
      ),
    ]),
  );

  // 14 — Demo & links
  doc.addPage(
    slide(14, 'Demo và tài liệu', 'Kết thúc', [
      pw.Row(
        children: [
          pw.Expanded(
            child: box('Thứ tự demo 8–12 phút', [
              'Mobile: đăng nhập, tra môn, việc, ghi chú',
              'Web: từng màn Staff/Admin',
              'Cross-role: gửi và duyệt song song',
              'AI: bật/tắt bằng Remote Config',
              'Chạy một test + xem kết quả',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Tài liệu', [
              'docs/gap-review.md',
              'docs/data-model.md',
              'docs/cross-role-flow.md',
              'docs/ai-feature.md',
              'docs/test-report.md',
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: box('Link nộp', [
              'Repo: PRM393_Final_GR6',
              'Web: prm323-lab2-gr6.web.app',
              'Video: chờ quay 8–12 phút',
            ], color: PdfColors.amber50),
          ),
        ],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cảm ơn thầy/cô và các bạn — Q&A',
                style: t(12, bold: true, color: PdfColors.blue900)),
            pw.Text('GR6 · StudyPilot', style: t(9, bold: true)),
          ],
        ),
      ),
    ]),
  );

  final out = File(kSlidesPath);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(await doc.save());
  print('Đã tạo $kSlidesPath ($kTotalSlides slide)');
}
