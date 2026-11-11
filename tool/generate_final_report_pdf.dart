// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String kReportPath = 'report/Final_GR6.pdf';
const int kTotalPages = 12;
const String kTeam =
    'Nguyễn Sỹ Thanh Tùng · Nguyễn Bá Thái Dương · Dương Quang Long · Võ Anh Duy';
const String kRepo = 'PRM393_Final_GR6';
const String kProject = 'prm323-lab2-gr6';

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
    title: 'PRM393 Final Report — StudyPilot (GR6)',
    author: 'GR6 — $kTeam',
    subject: 'PRM393 Final Assignment — One Complete System on Firebase',
    keywords: 'PRM393, Final, Flutter, Firebase, StudyPilot, GR6',
  );

  pw.Widget header(String section) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 1),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('StudyPilot — PRM393 Final Report · GR6',
                style: t(9, color: PdfColors.grey700)),
            pw.Text(section, style: t(9, bold: true, color: PdfColors.blue900)),
          ],
        ),
      );

  pw.Widget footer(int page) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        margin: const pw.EdgeInsets.only(top: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('$kRepo · Firebase project $kProject',
                style: t(7.5, color: PdfColors.grey600)),
            pw.Text('Trang $page / $kTotalPages',
                style: t(8.5, bold: true, color: PdfColors.blue900)),
          ],
        ),
      );

  pw.Page page(int number, String section, List<pw.Widget> content) => pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            header(section),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: content,
              ),
            ),
            footer(number),
          ],
        ),
      );

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: t(13, bold: true, color: PdfColors.blue900)),
      );

  pw.Widget sub(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
        child: pw.Text(text, style: t(10.5, bold: true, color: PdfColors.blue800)),
      );

  pw.Widget p(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(text, style: t(9.5), textAlign: pw.TextAlign.justify),
      );

  pw.Widget bullet(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 12,
              child: pw.Text('•',
                  style: t(9.5, bold: true, color: PdfColors.blue800)),
            ),
            pw.Expanded(child: pw.Text(text, style: t(9.5))),
          ],
        ),
      );

  pw.Widget table(
    List<String> head,
    List<List<String>> rows, {
    required List<double> widths,
    double size = 7.8,
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

  pw.Widget note(String text) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 6),
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          border: pw.Border.all(color: PdfColors.amber800, width: 0.5),
        ),
        child: pw.Text(text, style: t(7.8, color: PdfColors.brown900)),
      );

  // Trang 1 — Bìa + mục lục
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TRƯỜNG ĐẠI HỌC FPT — PRM393 MOBILE PROGRAMMING',
                    style: t(9, bold: true, color: PdfColors.blue100)),
                pw.SizedBox(height: 8),
                pw.Text('FINAL REPORT — StudyPilot',
                    style: t(20, bold: true, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Một hệ thống hoàn chỉnh trên Firebase: mobile Android, web quản trị, backend dùng chung và tính năng AI',
                  style: t(10.5, color: PdfColors.grey200),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nhóm GR6', style: t(10, bold: true)),
                pw.SizedBox(height: 3),
                pw.Text(kTeam, style: t(9.5)),
                pw.SizedBox(height: 6),
                pw.Text('Repository: $kRepo (tiếp nối prm323-lab2-gr6)',
                    style: t(9)),
                pw.Text(
                    'Firebase project: $kProject · Android package com.example.prm323_lab3',
                    style: t(9)),
                pw.Text('Ngày lập: 11/11/2026', style: t(9)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('MỤC LỤC', style: t(12, bold: true, color: PdfColors.blue900)),
          pw.SizedBox(height: 5),
          for (final row in const [
            ['§1. Bối cảnh, phạm vi và vai trò', '2'],
            ['§2. Kiến trúc hai client và backend', '3'],
            ['§3. Mô hình dữ liệu và phân quyền', '4'],
            ['§4. Security Rules và kiểm thử', '5'],
            ['§5. Web quản trị', '6'],
            ['§6. Luồng liên vai trò', '7'],
            ['§7. Tính năng AI', '8'],
            ['§8. Cấu hình AI và an toàn dữ liệu', '9'],
            ['§9. Kiểm thử và review code', '10'],
            ['§10. Kết quả, hạn chế và bài học', '11'],
            ['§11. Checklist nộp bài và kết luận', '12'],
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(row[0], style: t(9.5)),
                  pw.Text('Trang ${row[1]}', style: t(9.5, bold: true)),
                ],
              ),
            ),
          pw.Spacer(),
          note(
            'Mỗi trạng thái trong báo cáo gắn với bằng chứng: analyze, unit/widget, rules emulator, web test, ARTEMIS '
            'trên giả lập và máy thật, ảnh Console trong evidence/. Không có kết quả nào được suy diễn thay cho bằng chứng.',
          ),
        ],
      ),
    ),
  );

  // Trang 2 — §1
  doc.addPage(
    page(2, '§1. Bối cảnh & phạm vi', [
      heading('1.1. Từ Lab 2 và Lab 3 đến Final'),
      p(
        'Lab 2 đặt nền thiết kế: Figma, token, 8 màn hình cốt lõi và các luồng học tập cho persona sinh viên FPTU. '
        'Lab 3 chuyển thiết kế thành ứng dụng Flutter có Firestore, FCM, Analytics, Crashlytics, Remote Config, '
        'xuất PDF và bộ kiểm thử ARTEMIS. Final không thêm tính năng mới; mục tiêu là ghép hai giai đoạn thành '
        'một hệ thống nhiều vai trò, một backend và một tính năng AI có kiểm soát.',
      ),
      p(
        'Sản phẩm được đổi tên thành StudyPilot cho đúng nghĩa. Mã gói Android giữ nguyên để không phá liên kết '
        'Firebase đã đăng ký; gói Dart dùng chung đổi thành study_pilot_core.',
      ),
      sub('1.2. Vai trò trong hệ thống'),
      table(
        ['Vai trò', 'Client', 'Trách nhiệm chính'],
        [
          [
            'Sinh viên (user)',
            'Android',
            'Tra chương trình/đề cương, việc cần làm, ghi chú, hỏi AI, gửi bí kíp, nhận thông báo'
          ],
          [
            'Cán bộ (staff)',
            'Web',
            'Quản lý chuyên ngành/môn, duyệt bí kíp kèm lý do, đăng thông báo, xem dashboard'
          ],
          [
            'Quản trị (admin)',
            'Web',
            'Quyền của Staff và đổi role tài khoản khác qua đúng một trường'
          ],
        ],
        widths: [95, 60, 368],
      ),
      sub('1.3. Phạm vi Final so với rubric'),
      table(
        ['Hạng mục', 'Trạng thái', 'Ghi chú'],
        [
          [
            'Mobile: Lab 2 + Lab 3',
            'Đạt',
            '18 màn hình, 165 test, APK debug/release; ARTEMIS trên giả lập và máy thật'
          ],
          [
            'Mobile: dữ liệu + inbox',
            'Đạt',
            'Không mock; môn, bí kíp, thông báo đọc Firestore realtime'
          ],
          [
            'Web: 4 màn + form',
            'Đạt',
            'Chuyên ngành, duyệt, dashboard, thông báo; live tại prm323-lab2-gr6.web.app'
          ],
          [
            'Backend: model + rules',
            'Đạt',
            'Model tài liệu hóa; rules deny mặc định; 17/17 test'
          ],
          [
            'Cross-role',
            'Đạt',
            'Gửi bí kíp → duyệt → trạng thái realtime + tin nhắn Hòm thư'
          ],
          [
            'AI level 2',
            'Đạt',
            'JSON có schema, RC, App Check, fallback; 3 output thật'
          ],
          [
            'Testing + review',
            'Đạt',
            'Rules 17/17, web 14/14, Flutter 165/165; ARTEMIS 10 ca × 3 lượt; review CR-15…31'
          ],
          [
            'Slides + video',
            'Đã có',
            'Video 8–12 phút (Google Drive); bộ dựng slide kèm kịch bản quay'
          ],
        ],
        widths: [118, 82, 323],
      ),
      note(
        'Nguyên tắc: chỉ ghi "đạt" khi có bằng chứng tương ứng trong evidence/ hoặc tài liệu kỹ thuật; '
        'rubric đầy đủ và đường dẫn bằng chứng nằm trong docs/gap-review.md.',
      ),
    ]),
  );

  // Trang 3 — §2
  doc.addPage(
    page(3, '§2. Kiến trúc', [
      heading('2.1. Hai client, một backend'),
      table(
        ['Thành phần', 'Công nghệ', 'Trách nhiệm'],
        [
          [
            'Mobile',
            'Flutter 3.47.4, Provider, MVVM',
            'Toàn bộ luồng sinh viên, PDF cục bộ, FCM, AI, analytics'
          ],
          [
            'Web admin',
            'SPA ES module, Firebase Hosting',
            'Đăng nhập, quản lý chuyên ngành/môn, duyệt bí kíp, dashboard, thông báo'
          ],
          [
            'Shared',
            'packages/core (study_pilot_core)',
            'Model và truy cập Firestore dùng chung cho phần Final'
          ],
          [
            'Backend',
            'Auth, Firestore, AI Logic, App Check, RC, Analytics, FCM',
            'Danh tính, dữ liệu, quyền, cấu hình và quan sát'
          ],
        ],
        widths: [78, 160, 285],
      ),
      sub('2.2. Luồng dữ liệu trong mobile'),
      p(
        'Widget chỉ đọc ViewModel. ViewModel gọi service được inject; service là nơi duy nhất chạm SDK Firebase. '
        'Kết quả được chuẩn hóa thành AsyncViewState<T> với bốn nhánh loading / empty / data / error. '
        'Nhờ vậy màn hình không tự bắt exception và không hiển thị dữ liệu giả khi lỗi.',
      ),
      for (final item in const [
        'Main composition tạo Auth, Firestore, Analytics, Crashlytics, Remote Config, App Check và AI service.',
        'Role gate đọc users/{uid}.role qua FirestoreService; sai vai trò bị từ chối trước khi vào app.',
        'Snapshot listener đẩy thay đổi realtime cho inbox, bí kíp và thông báo.',
        'Mỗi bước khởi tạo không bắt buộc được cô lập trong try/catch; lỗi Firebase cốt lõi vẫn chặn để báo đúng.',
      ])
        bullet(item),
      sub('2.3. Quyết định kiến trúc'),
      table(
        ['Quyết định', 'Lý do'],
        [
          [
            'Không có server tùy chỉnh',
            'Đề cho phép; Rules + App Check quyết định quyền, giảm bề mặt vận hành'
          ],
          [
            'Model + service dùng chung',
            'Hai client không lệch schema; web và mobile đọc cùng một hợp đồng'
          ],
          [
            'Không SDK trong widget/ViewModel',
            'CR-15/16 đã tách; test thay được service giả'
          ],
          [
            'Cloudinary thay Cloud Storage',
            'Giảng viên cho phép; gói Spark không mở bucket; đã ghi deviation'
          ],
          [
            'PDF tạo tại thiết bị',
            'Đúng yêu cầu Final; Firestore chỉ lưu metadata'
          ],
        ],
        widths: [150, 373],
      ),
    ]),
  );

  // Trang 4 — §3
  doc.addPage(
    page(4, '§3. Dữ liệu & phân quyền', [
      heading('3.1. Collection chính'),
      table(
        ['Collection', 'Nội dung', 'Ghi / đọc', 'Màn hình'],
        [
          [
            'users/{uid}',
            'role, displayName, hồ sơ học vụ',
            'Tự tạo role=user; Admin đổi role',
            'Mobile + web'
          ],
          [
            'courses/{major}__{code}',
            'Đề cương, slot, đầu điểm, LO',
            'Staff/Admin ghi; mọi người đăng nhập đọc',
            'Lộ trình, chi tiết môn, web'
          ],
          [
            'majors/{code}',
            'Chuyên ngành, danh sách môn',
            'Staff/Admin ghi',
            'Web quản lý'
          ],
          [
            'experience_notes/{id}',
            'Bí kíp sinh viên, status, lý do',
            'Sinh viên tạo pending; Staff duyệt',
            'Mobile + web duyệt'
          ],
          [
            'tip_ratings/{tip}__{uid}',
            'Một đánh giá sao / người / bí kíp',
            'Chủ sở hữu ghi',
            'Mobile chi tiết môn'
          ],
          [
            'tip_comments/{id}',
            'Thảo luận dưới bí kíp',
            'Người đăng nhập tạo; chủ sửa/xóa',
            'Mobile'
          ],
          [
            'announcements/{id}',
            'Thông báo Staff/Admin',
            'Staff/Admin tạo; mọi người đọc',
            'Mobile inbox + web'
          ],
          [
            'study_plan_submissions',
            'Kế hoạch học tập theo kỳ',
            'Sinh viên tạo; Staff duyệt',
            'Mobile'
          ],
          [
            'users/{uid}/tasks, notes',
            'Việc và ghi chú cá nhân',
            'Chỉ chủ sở hữu',
            'Mobile'
          ],
          [
            'audit_logs/{id}',
            'Nhật ký thao tác quản trị',
            'Append-only đúng chủ',
            'Web/Console'
          ],
        ],
        widths: [118, 138, 160, 107],
        size: 7.2,
      ),
      sub('3.2. Chuyển trạng thái'),
      for (final item in const [
        'experience_notes: pending → approved hoặc rejected; chỉ Staff/Admin, bắt buộc reason; bản approved công khai.',
        'study_plan_submissions: pending → approved/rejected; không cho sửa nội dung sau khi gửi.',
        'courses/majors: active → archived; không xóa cứng dữ liệu đang được tham chiếu.',
        'users.role: user/staff/admin; chỉ Admin đổi role của tài khoản khác, không tự đổi.',
      ])
        bullet(item),
      note(
        'Mọi quyết định duyệt ghi reviewedBy = UID người duyệt và reviewedAt = request.time. '
        'Rules chỉ cho phép đúng bốn trường này thay đổi trên bản ghi đang pending.',
      ),
    ]),
  );

  // Trang 5 — §4
  doc.addPage(
    page(5, '§4. Security Rules', [
      heading('4.1. Nguyên tắc'),
      for (final item in const [
        'Deny by default: không có nhánh allow cuối, không dùng if true.',
        'Phân quyền theo users/{uid}.role; quyền của tài khoản không suy ra từ UI.',
        'Kiểm tra schema, độ dài, kiểu dữ liệu và trạng thái nguồn trước khi cho ghi.',
        'Chặn tự nâng quyền: hồ sơ mới phải có role=user và admin=false.',
        'Audit log append-only, chỉ nhận userId/action/createdAt do chính chủ tạo.',
      ])
        bullet(item),
      sub('4.2. Ví dụ allow / deny'),
      table(
        ['Vai trò', 'Thao tác', 'Kết quả', 'Lý do'],
        [
          [
            'user',
            'Tạo experience_notes với status=pending',
            'Cho phép',
            'Đúng chủ, đúng trạng thái khởi tạo'
          ],
          [
            'user',
            'Tạo experience_notes với status=approved',
            'Từ chối',
            'Sinh viên không tự duyệt'
          ],
          [
            'staff',
            'pending → approved + reason + reviewedBy',
            'Cho phép',
            'Đúng vai trò, đúng chuyển trạng thái'
          ],
          [
            'staff',
            'Sửa content của bí kíp đã duyệt',
            'Từ chối',
            'Chỉ bốn trường quyết định được đổi'
          ],
          ['user', 'Đổi role của chính mình', 'Từ chối', 'Chống tự nâng quyền'],
          [
            'admin',
            'Đổi role của tài khoản khác',
            'Cho phép',
            'Chỉ trường role'
          ],
          [
            'user',
            'Đọc hàng đợi pending của người khác',
            'Từ chối',
            'Chỉ chủ sở hữu hoặc Staff/Admin'
          ],
        ],
        widths: [60, 230, 70, 163],
      ),
      sub('4.3. Kiểm thử emulator — 17/17 pass'),
      p(
        'Bộ test dùng @firebase/rules-unit-testing trên project demo-second-brain-final, tách hoàn toàn khỏi dữ liệu thật. '
        'Mỗi collection có ít nhất một ca allow và một ca deny theo vai trò; các ca chuyển trạng thái kiểm tra cả '
        'giá trị trường và người thực hiện.',
      ),
      table(
        ['Nhóm', 'Nội dung', 'Kết quả'],
        [
          ['Hồ sơ', 'Bootstrap role, chặn admin=false, giới hạn 40 trường', 'Pass'],
          ['Đơn kế hoạch', 'Sở hữu, schema, duyệt một lần, id cố định', 'Pass'],
          ['Bí kíp', 'Gửi pending, duyệt kèm lý do, bản approved công khai', 'Pass'],
          ['Thông báo', 'Chỉ Staff/Admin tạo, payload hợp lệ; tin nhắn duyệt bí kíp đúng shape', 'Pass'],
          ['Catalog', 'Mã môn bất biến, archive, học kỳ 0–12, mã *', 'Pass'],
          ['Legacy', 'Bốn subcollection chỉ chủ sở hữu đọc', 'Pass'],
          ['Audit', 'Append-only đúng chủ', 'Pass'],
        ],
        widths: [80, 330, 113],
      ),
      note(
        'Bản rules siết đã deploy live ngày 11/11 (ruleset tạo 2026-11-11T03:22:05Z, khớp tuyệt đối repo; G-09 đóng). '
        'Hosting đã live (G-01). Bằng chứng: evidence/firebase/firestore/rules-api-verification-2026-11-11.json.',
      ),
    ]),
  );

  // Trang 6 — §5
  doc.addPage(
    page(6, '§5. Web quản trị', [
      heading('5.1. Năm màn hình'),
      table(
        ['Màn hình', 'Chức năng', 'Trạng thái UI'],
        [
          [
            'Đăng nhập',
            'Google Sign-In; từ chối tài khoản không phải staff/admin',
            'Loading, lỗi, sai vai trò'
          ],
          [
            'Chuyên ngành',
            'Danh sách, tìm kiếm, tạo/sửa/archive, import HTML FLM, preview trước khi lưu batch',
            'Loading, empty, lỗi, kéo-thả'
          ],
          [
            'Duyệt bí kíp',
            'Hàng đợi realtime, bắt buộc lý do, duyệt/từ chối',
            'Loading, empty, lỗi, thử lại'
          ],
          [
            'Dashboard',
            '≥ 3 số liệu aggregation + 1 biểu đồ',
            'Loading, empty, lỗi'
          ],
          [
            'Thông báo',
            'Soạn và đăng announcements; mobile nhận realtime',
            'Loading, empty, lỗi'
          ],
        ],
        widths: [90, 330, 103],
      ),
      sub('5.2. Dữ liệu và tương tác'),
      for (final item in const [
        'Không có seed/mock: chuyên ngành và môn chỉ đến từ form hoặc file HTML FLM do Staff chọn.',
        'Import FLM parse tại trình duyệt, hiển thị trước số môn, cảnh báo thiếu đề cương/tiên quyết, cho bỏ chọn từng môn.',
        'Mỗi listener có banner lỗi và nút thử lại riêng; không còn màn trắng khi mất mạng (CR-21).',
        'Dashboard dùng getCountFromServer cho số liệu và onSnapshot cho bảng/biểu đồ.',
        'Nút dọn dữ liệu cũ yêu cầu gõ XOA; không đụng người dùng, thông báo hay bí kíp.',
      ])
        bullet(item),
      sub('5.3. Design system và deploy'),
      p(
        'Web dùng token/màu và thành phần tinh thần của Lab 2, bố cục rộng cho màn hình quản trị. '
        'SPA đã qua 14/14 test Node và được deploy lên Firebase Hosting tại '
        'https://prm323-lab2-gr6.web.app/ ; trang đăng nhập mở được từ URL công khai (kiểm tra 10/11/2026).',
      ),
      note(
        'Ảnh Console và bằng chứng deploy lưu trong evidence/firebase/; mỗi màn có trạng thái loading, empty và error riêng.',
      ),
    ]),
  );

  // Trang 7 — §6
  doc.addPage(
    page(7, '§6. Luồng liên vai trò', [
      heading('6.1. Bí kíp: sinh viên gửi, Staff duyệt'),
      table(
        ['Bước', 'Actor / client', 'Ghi Firestore', 'Rule cho phép', 'Client còn lại'],
        [
          [
            '1',
            'Sinh viên / Android',
            'experience_notes: uid, courseDocId, title, content, status=pending',
            'Chủ sở hữu, status pending, đủ trường',
            'Web thấy hàng đợi mới'
          ],
          [
            '2',
            'Staff / Web',
            'status=approved/rejected, reason, reviewedBy, reviewedAt',
            'Bản ghi pending, đúng vai trò, đúng 4 trường',
            'Mobile nhận snapshot trạng thái'
          ],
          [
            '3',
            'Staff / Web',
            'users/{authorUid}/notifications/review_<noteId>: type=tip_review, route=/my-tips',
            'Chỉ staff/admin; đúng recipientId, actorId, ID, route, read=false, receivedAt=request.time',
            'Hòm thư mobile nhận tin nhắn realtime'
          ],
          [
            '4',
            'Sinh viên / Android',
            'Không ghi thêm',
            '—',
            'Hiển thị trạng thái, lý do và tin nhắn trong Hòm thư'
          ],
        ],
        widths: [35, 88, 175, 130, 95],
        size: 7.4,
      ),
      p(
        'Màn mobile đăng ký hai nguồn: bí kíp approved của môn và bí kíp của chính sinh viên. '
        'Khi web ghi quyết định, Firestore đẩy snapshot và danh sách tự cập nhật mà không cần refresh. '
        'Cùng lúc, web ghi một tin nhắn tip_review vào hộp thư tác giả; Hòm thư mobile nghe subcollection nên '
        'tin nhắn xuất hiện ngay kèm lý do duyệt. Bí kíp đã duyệt trở thành ngữ cảnh công khai cho phần cố vấn AI.',
      ),
      sub('6.2. Thông báo'),
      p(
        'Staff/Admin đăng announcements trên web; mobile đọc realtime trong Trung tâm Thông báo. '
        'Hòm thư hợp nhất announcements, tin nhắn duyệt bí kíp (tip_review) và thông báo cá nhân khác. '
        'FCM chỉ dùng cho nhắc nhở và điều hướng, không thay thế inbox Firestore.',
      ),
      sub('6.3. Ma trận quyền rút gọn'),
      table(
        ['Tài nguyên', 'Sinh viên', 'Staff', 'Admin'],
        [
          [
            'experience_notes',
            'Tạo pending; đọc bản approved + của mình',
            'Đọc toàn bộ; duyệt/từ chối',
            'Như Staff'
          ],
          ['announcements', 'Đọc', 'Tạo', 'Tạo'],
          [
            'courses/majors',
            'Đọc',
            'Tạo/sửa/archive',
            'Tạo/sửa/archive'
          ],
          ['users.role', 'Không', 'Không', 'Đổi role tài khoản khác'],
        ],
        widths: [120, 185, 140, 78],
      ),
      note(
        'Trạng thái và tin nhắn Hòm thư đều được kiểm chứng ở rules test "staff review decision appends exactly '
        'one inbox message for the author" (allow/deny theo vai trò) và ở unit test stream của NotificationsViewModel.',
      ),
    ]),
  );

  // Trang 8 — §7
  doc.addPage(
    page(8, '§7. Tính năng AI', [
      heading('7.1. Gợi ý kế hoạch học tập (level 2)'),
      p(
        'Sinh viên chọn kỳ học, bấm "Gợi ý bằng AI". Ứng dụng gửi số kỳ và ngữ cảnh đề cương công khai của các môn trong kỳ '
        'tới Firebase AI Logic (Gemini Developer API). Model trả JSON gồm goal và 1–4 actions; ứng dụng validate bằng '
        'StudyPlanDraft.fromJson, hiển thị nhãn "Bản nháp do AI tạo" và cho người dùng bấm Dùng rồi sửa trước khi gửi duyệt.',
      ),
      sub('7.2. Ba input/output thật (gemini-3.5-flash-lite)'),
      table(
        ['Kỳ', 'Input rút gọn', 'Output (goal / actions)'],
        [
          [
            '3',
            'PRF192, MAE101, CEA201 · 3 tín chỉ · 30 slots',
            'Ôn PE/FE theo 30 slot; luyện đề C, toán, cơ sở điện toán; chia tuần theo đề cương.'
          ],
          [
            '5',
            'PRM393, SWP391 · đồ án và thi PE/FE',
            'Hoàn thành đồ án theo sprint; ôn lý thuyết đa nền tảng; luyện PE trên thiết bị thật.'
          ],
          [
            '8',
            'Chuyên ngành sâu, đồ án tốt nghiệp',
            'Chốt đề tài và mốc bảo vệ; ôn chuyên đề; dành slot cho phản biện và viết báo cáo.'
          ],
        ],
        widths: [35, 210, 278],
        size: 7.6,
      ),
      p(
        'Ba output đầy đủ nằm trong evidence/ai/study-plan-2026-11-10-valid.json, sinh bằng cùng system instruction và '
        'prompt với lib/services/study_plan_ai.dart, maxOutputTokens 1024, temperature 0.2. Đây là bằng chứng tầng model, '
        'không phải ảnh UI trên thiết bị.',
      ),
      sub('7.3. Ca lỗi đã xử lý'),
      p(
        'Lượt đầu, model trả một goal lặp vô hạn và không có actions hợp lệ; lần khác trả HTTP 503. '
        'fromJson kiểm tra kiểu, độ dài và số lượng nên ném FormatException; màn hình bắt lỗi, ghi ai_error và giữ form thủ công. '
        'Bằng chứng: evidence/ai/study-plan-2026-11-10.json. Đây là lý do tính năng không phụ thuộc AI để hoàn tất luồng.',
      ),
    ]),
  );

  // Trang 9 — §8
  doc.addPage(
    page(9, '§8. Cấu hình & an toàn AI', [
      heading('8.1. Remote Config — 9 tham số'),
      table(
        ['Tham số', 'Vai trò'],
        [
          ['maintenance_mode', 'Chặn app khi bảo trì'],
          ['min_app_version', 'Chặn phiên bản cũ'],
          ['feature_ai_advisor_enabled', 'Bật/tắt cố vấn AI'],
          ['ai_advisor_model', 'Model cố vấn (gemini-3.5-flash-lite)'],
          ['ai_advisor_prompt', 'System prompt của cố vấn'],
          ['vault_sync_interval_mins', 'Chu kỳ đồng bộ Vault'],
          ['study_plan_ai_enabled', 'Bật/tắt gợi ý kế hoạch học tập'],
          ['study_plan_ai_model', 'Model gợi ý kế hoạch'],
          ['study_plan_ai_prompt', 'System prompt gợi ý kế hoạch'],
        ],
        widths: [210, 313],
        size: 8,
      ),
      p(
        'Remote Config được fetch/activate khi khởi động; giá trị mặc định trong firebase/remote-config-template.json khớp '
        'đúng 9 tham số app đọc (CR-22). Bản live trên project là Version 3, publish ngày 10/11/2026. Khi tắt cờ, nút AI biến mất nhưng form thủ công vẫn hoạt động.',
      ),
      sub('8.2. App Check và dữ liệu gửi đi'),
      for (final item in const [
        'App Check bảo vệ Firestore và AI Logic; bản sideload dùng debug token cố định cho demo, bản phát hành dùng Play Integrity.',
        'Prompt chỉ gửi số kỳ và thông tin đề cương công khai; không gửi tên, email, ảnh, điểm, lịch hay câu hỏi tự do.',
        'Output luôn gắn nhãn AI và người dùng phải chủ động chấp nhận rồi chỉnh sửa.',
        'Ba event ai_request / ai_result_accepted / ai_error không chứa nội dung prompt hay câu trả lời.',
        'Quota hoặc mạng lỗi: app báo "AI chưa khả dụng", giữ nguyên form và cho gửi thủ công.',
      ])
        bullet(item),
      note(
        'Hạn chế đã biết: chưa quay cảnh đổi cờ Remote Config trên thiết bị thật; ảnh Console và lượt tắt cờ là hạng mục G-06.',
      ),
    ]),
  );

  // Trang 10 — §9
  doc.addPage(
    page(10, '§9. Kiểm thử & review', [
      heading('9.1. Kết quả đã chạy'),
      table(
        ['Lớp', 'Kết quả', 'Ghi chú'],
        [
          ['flutter analyze', '0 issue', 'Toàn bộ lib, packages, test, tool'],
          ['flutter test', '165/165 pass', 'Hermetic, service giả'],
          ['Build APK', 'debug + release pass', 'build/app/outputs/flutter-apk'],
          ['Rules emulator', '17/17 pass', 'project demo-second-brain-final'],
          ['Web Node', '14/14 pass', '9 parser FLM + 5 API server'],
          [
            'ARTEMIS',
            '10 ca × 3 lượt',
            'Pixel 7 API 35 giả lập; TC_10 3/3, TC_08 và TC_11 trên máy thật'
          ],
          ['AI model', '3 valid + 1 lỗi', 'evidence/ai/'],
        ],
        widths: [110, 110, 303],
      ),
      sub('9.2. Phạm vi kiểm thử'),
      for (final item in const [
        '26 kịch bản ARTEMIS bao phủ luồng Lab 2, bước mobile của cross-role (gửi bí kíp) và tính năng AI; mỗi ca chạy 3 lượt để đo pass rate.',
        'Mười ca lõi chạy 3 lượt trên Pixel 7 API 35 giả lập; TC_10 chạy 3/3 trên máy thật, TC_08 và TC_11 cũng pass trên máy thật.',
        'Hai phiên exploratory ARTEMIS Pro được ghi trong docs/test-report.md; kết quả từng lượt nằm trong evidence/artemis/results-*.md.',
        'Rules emulator chạy trên project demo riêng, tách khỏi dữ liệu thật; web có 14 test Node cho parser FLM và API.',
      ])
        bullet(item),
      sub('9.3. Review code — finding tiêu biểu'),
      table(
        ['ID', 'Phát hiện', 'Quyết định', 'Commit'],
        [
          [
            'CR-15',
            'ViewModel import trực tiếp SDK Firebase/AI',
            'Tách AiService, inject qua Provider',
            'bd4c989'
          ],
          [
            'CR-16',
            'Role gate đọc Firestore SDK trong widget',
            'Thêm watchUserRole ở service layer',
            'bd4c989'
          ],
          [
            'CR-17',
            'Một dịch vụ lỗi chặn toàn app',
            'Cô lập từng bước, giữ lỗi cốt lõi',
            'bd4c989'
          ],
          [
            'CR-18',
            'Sync Vault để lại task kiểm tra',
            'Ghi marker, đọc lại, xóa đúng bản ghi',
            'f2b2cb0'
          ],
          [
            'CR-20',
            'Rules cho tự khai admin; audit log mở',
            'Chặn admin=false, giới hạn trường',
            'e5256c1'
          ],
          [
            'CR-21',
            'Listener web lỗi để màn trắng',
            'Banner lỗi + thử lại + telemetry',
            'c9b9985'
          ],
        ],
        widths: [42, 205, 205, 71],
        size: 7.4,
      ),
      p(
        'Nợ kỹ thuật còn mở: CR-27 (ba widget gọi thẳng FinalFirestore). '
        'CR-28 (event AI thiếu feature) và CR-29 (test AnnouncementsViewModel) đã đóng; '
        'CR-30 đã xác nhận uv.lock ghim đúng commit ARTEMIS.',
      ),
    ]),
  );

  // Trang 11 — §10
  doc.addPage(
    page(11, '§10. Kết quả & bài học', [
      heading('10.1. Kết quả đạt được'),
      for (final item in const [
        'Một backend Firestore phục vụ hai client; không có server tùy chỉnh.',
        'Phân quyền thực thi ở Rules, có 15 test allow/deny theo vai trò.',
        'Luồng liên vai trò bí kíp chạy qua web duyệt và mobile snapshot realtime.',
        'AI level 2 có schema, nhãn, chỉnh sửa, Remote Config, App Check và fallback.',
        'Tài liệu hóa đầy đủ gap review, data model, cross-role, AI, test report và review code.',
      ])
        bullet(item),
      sub('10.2. Bằng chứng vận hành'),
      table(
        ['Hạng mục', 'Trạng thái', 'Bằng chứng'],
        [
          ['Web URL', 'Đã deploy', 'Live tại prm323-lab2-gr6.web.app (G-01)'],
          ['Cross-role', 'Đạt', 'Trạng thái realtime + tin nhắn Hòm thư; rules 17/17'],
          ['ARTEMIS máy thật', 'Đạt', 'TC_10 3/3, TC_08, TC_11; evidence/artemis/'],
          ['Exploratory', 'Đạt', 'Hai phiên ARTEMIS Pro; docs/test-report.md'],
          [
            'Console',
            'Đã lưu ảnh',
            'RC Version 3, App Check, Crashlytics, Analytics (evidence/firebase/)'
          ],
          ['Video', 'Đã có', 'Google Drive 8–12 phút (evidence/video/linkvideo.md)'],
          ['Đổi tên repo', 'Đã xong', 'Repo PRM393_Final_GR6 (G-08)'],
        ],
        widths: [110, 100, 313],
      ),
      sub('10.3. Bài học'),
      for (final item in const [
        'Kiểm tra quyền ở backend trước khi tin UI: ẩn nút không phải bảo mật.',
        'Snapshot listener đơn giản hơn polling nhưng cần trạng thái lỗi và thử lại rõ ràng.',
        'AI phải có schema và đường thoát thủ công; model có thể lặp hoặc trả lỗi bất kỳ lúc nào.',
        'Bằng chứng phải tách theo môi trường: giả lập, emulator, thiết bị thật, Console.',
        'Đổi tên hiển thị không được đổi applicationId nếu muốn giữ nguyên liên kết Firebase.',
      ])
        bullet(item),
    ]),
  );

  // Trang 12 — §11
  doc.addPage(
    page(12, '§11. Checklist & kết luận', [
      heading('11.1. Checklist nộp bài'),
      table(
        ['Hạng mục', 'Trạng thái'],
        [
          ['Repo tiếp nối Lab 3, đổi tên PRM393_Final_GR6', 'Đạt'],
          ['Mobile trên Firestore + inbox realtime', 'Đạt'],
          ['Web 4 màn + form thông báo', 'Đạt'],
          ['Web deploy + URL công khai', 'Đạt'],
          ['Data model + rules deny mặc định + test', 'Đạt — 17/17'],
          ['Cross-role: gửi → duyệt → trạng thái + tin nhắn Hòm thư', 'Đạt'],
          ['AI level 2 + RC + App Check + fallback', 'Đạt'],
          ['ARTEMIS + rules + web checklist có bằng chứng', 'Đạt — 10 ca × 3 lượt, máy thật'],
          ['MVVM + shared package + ≥ 3 finding review', 'Đạt — CR-15…CR-31'],
          ['README, report, slides, video', 'README/report 12 trang; video Google Drive 8–12 phút'],
        ],
        widths: [360, 163],
      ),
      sub('11.2. Kết luận'),
      p(
        'StudyPilot đã ghép Lab 2 và Lab 3 thành một hệ thống có hai client, một backend và một tính năng AI có kiểm soát. '
        'Toàn bộ luồng Lab 2 chạy trên Firestore thật; Hòm thư nhận thông báo realtime, kể cả tin nhắn duyệt bí kíp do '
        'web ghi trực tiếp dưới ràng buộc của rules. Web đã deploy, rules đã live, repo đã đổi tên và bộ kiểm thử '
        'rules/unit/E2E có kết quả kèm bằng chứng trong evidence/.',
      ),
      sub('11.3. Đường dẫn bằng chứng'),
      for (final item in const [
        'docs/gap-review.md — đối chiếu rubric với bằng chứng',
        'docs/data-model.md — collection, quyền, chuyển trạng thái',
        'docs/cross-role-flow.md — sequence diagram và ma trận quyền',
        'docs/ai-feature.md — 3 input/output thật và ca lỗi',
        'docs/test-report.md — kết quả test và review',
        'evidence/ai/, evidence/artemis/, evidence/firebase/ — log, JSON, ảnh',
      ])
        bullet(item),
      pw.Spacer(),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        child: pw.Text(
          'Nhóm GR6 · $kTeam\nRepository: $kRepo · Báo cáo lập ngày 11/11/2026',
          style: t(9, bold: true, color: PdfColors.blue900),
        ),
      ),
    ]),
  );

  final out = File(kReportPath);
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(await doc.save());
  print('Đã tạo $kReportPath ($kTotalPages trang)');
}
