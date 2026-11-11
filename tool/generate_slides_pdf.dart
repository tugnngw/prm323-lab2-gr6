// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final regularBytes = File('assets/fonts/DejaVuSans.ttf').readAsBytesSync();
  final boldBytes = File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytesSync();

  final fontRegular = pw.Font.ttf(ByteData.view(regularBytes.buffer));
  final fontBold = pw.Font.ttf(ByteData.view(boldBytes.buffer));

  final doc = pw.Document(
    title: 'PRM393 Lab 3 — Presentation Slides — Nhóm GR6',
    author: 'Nhóm GR6',
    subject: 'PRM393 Cloud-Enabled Mobile App Presentation Slides',
    keywords: 'PRM393, Lab 3, Flutter, Firebase, Slides, Nhóm GR6',
  );

  final totalSlides = 15;

  pw.Widget buildSlideHeader(String title, String category, int slideNum) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(category.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue700)),
              pw.Text(title,
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text('Slide $slideNum / $totalSlides',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  pw.Widget buildSlideFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('PRM393 Lab 3: StudyPilot — Cloud-Enabled Academic Assistant',
              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600)),
          pw.Text('Nhóm GR6 | Project: prm323-lab2-gr6',
              style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Page createSlide({
    required int slideNum,
    required String title,
    required String category,
    required List<pw.Widget> body,
    bool isCover = false,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      build: (pw.Context context) {
        if (isCover) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: body,
          );
        }
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildSlideHeader(title, category, slideNum),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: body,
              ),
            ),
            buildSlideFooter(),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // SLIDE 1: COVER
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 1,
    title: 'Bìa trình chiếu',
    category: 'Giới thiệu',
    isCover: true,
    body: [
      pw.Spacer(),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(24),
        decoration: const pw.BoxDecoration(
          color: PdfColors.blue900,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('TRƯỜNG ĐẠI HỌC FPT — KHOA CÔNG NGHỆ THÔNG TIN',
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue200)),
            pw.SizedBox(height: 8),
            pw.Text('PRM393: MOBILE PROGRAMMING — LAB 3 PRESENTATION',
                style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.white)),
            pw.SizedBox(height: 6),
            pw.Text('StudyPilot: Ứng dụng Quản lý Học tập Đám mây tích hợp Firebase & Kiểm thử Tự động E2E',
                style: pw.TextStyle(font: fontRegular, fontSize: 13, color: PdfColors.grey200)),
          ],
        ),
      ),
      pw.SizedBox(height: 20),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Nhóm thực hiện: GR6',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey900)),
            pw.SizedBox(height: 4),
            pw.Text('Repository: PRM393_Final_GR6',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.red800)),
            pw.SizedBox(height: 4),
            pw.Text('Repository nộp: PRM393_Final_GR6 (Gốc: prm323-lab2-gr6)',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Nền tảng: Flutter 3.47.5 / Dart 3.13.4 (Material 3)',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Backend: Firebase Suite (Auth, Firestore, Storage, Analytics, RC, FCM)',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Ngày báo cáo: 04/11/2026',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey800)),
          ]),
        ],
      ),
      pw.Spacer(),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 2: CONTEXT & PERSONAS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 2,
    title: 'Bối cảnh Chuyển đổi & Chân dung Người dùng (Personas)',
    category: '1. Bối cảnh & Mục tiêu',
    body: [
      pw.Text('Từ Lab 2 (Figma Prototype & Mock Data cục bộ) sang Lab 3 (Cloud Production Mobile App thực thụ):',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Persona P01 — An (K19, Năm 1)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text('• Pain point: Mới vào chuyên ngành, bỡ ngỡ với môn tiên quyết, dễ trượt slot điểm danh.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                pw.SizedBox(height: 3),
                pw.Text('• Giải pháp: Lộ trình môn học (Roadmap), tự động kiểm tra prerequisite (PRO192->CSD201).', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue800)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green200, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Persona P02 — Bình (K17, Năm 3)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.green900)),
                pw.SizedBox(height: 4),
                pw.Text('• Pain point: Quá tải deadline đồ án SWP391 và bài tập lab, thất lạc tài liệu ôn thi.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                pw.SizedBox(height: 3),
                pw.Text('• Giải pháp: Tasks & Notes Vault đồng bộ đám mây, đính kèm file, xuất Study Report PDF.', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green800)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.orange50, border: pw.Border.all(color: PdfColors.orange200, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Persona P03 — Chi (K16, Năm 4)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.orange900)),
                pw.SizedBox(height: 4),
                pw.Text('• Pain point: Cần tối ưu GPA trước kỳ OJT/Capstone, phân vân học cải thiện hay học vượt.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                pw.SizedBox(height: 3),
                pw.Text('• Giải pháp: Cố vấn học tập 4 cấp (Course/Semester/Program/Score) & Mô phỏng GPA kỳ 5.', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.orange800)),
              ]),
            ),
          ),
        ],
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 3: ARCHITECTURE & MVVM
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 3,
    title: 'Kiến trúc MVVM 4 Tầng & Nguyên tắc Fail-Loud',
    category: '2. Kiến trúc & Thiết kế',
    body: [
      pw.Text('Tách biệt hoàn toàn trách nhiệm — UI Tuyệt đối không import Firebase SDK:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tầng kiến trúc', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Thư mục đại diện', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Trách nhiệm chính & Ràng buộc kỹ thuật', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('1. View (UI)', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('lib/screens/\nlib/widgets/', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('11 Screens + 9 Reusable Widgets. Chỉ đọc state từ ViewModel qua Provider. 0 import Firebase/Cloud.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('2. ViewModel', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('lib/viewmodels/', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('AuthViewModel, TasksViewModel, NotesViewModel, RoadmapViewModel, AdvisorViewModel. Quản lý AsyncViewState 4 pha.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('3. Service / Repo', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('lib/services/', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Định hình abstract interface. Tương tác Firebase SDK thật hoặc Test Doubles (Fakes) khi chạy Unit Tests.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('4. Backend / Cloud', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Firebase Cloud', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Google Identity, Cloud Firestore, Cloud Storage, Remote Config, Analytics, Crashlytics, FCM.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        child: pw.Text(
          'NGUYÊN TẮC FAIL-LOUD: Khi kết nối mạng hoặc dịch vụ lỗi, ViewModel chuyển state sang AsyncViewState.error '
          'và hiển thị banner/thông báo kèm nút "Thử lại" (Retry). Tuyệt đối không âm thầm nuốt lỗi hoặc chuyển về mock data giả lập.',
          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.blue900),
        ),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 4: DESIGN SYSTEM & TOKENS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 4,
    title: 'Design System, Design Tokens & Trợ năng (Accessibility)',
    category: '2. Kiến trúc & Thiết kế',
    body: [
      pw.Text('Toàn bộ giao diện chuẩn hóa Material 3, loại bỏ hoàn toàn các giá trị hardcode lẻ tẻ:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('AppColors (lib/theme/app_colors.dart)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text('• Primary: #1D4ED8 (Xanh dương FPT)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• Secondary: #0F766E (Teal học thuật)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• Success: #16845B | Warning: #B45309', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• Error: #B42318 | OnPrimary: #FFFFFF', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• Surface: #F8FAFC | OnSurface: #0F172A', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Spacing & Elevation (app_spacing.dart)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text('• Hairline: 2.0 | XXS: 4.0 | Micro: 6.0', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• XS: 8.0 | SM: 12.0 | MD: 16.0 | LG: 20.0', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• XL: 24.0 | XXL: 32.0 (Lưới 4/8pt chuẩn)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• AppElevation: flat (0.0), overlay (6.0)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Typography & A11y Semantics', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text('• AppFontSize: caption(11), label(12), dense(13), displaySmall(18), heading(20)...', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• Semantics Labels: 100% interactive widgets có nhãn cho trình đọc màn hình.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                pw.Text('• LiveRegion: Áp dụng trên thông báo nổi FCM.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              ]),
            ),
          ),
        ],
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 5: 11 SCREENS & ROUTING
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 5,
    title: 'Danh mục 11 Màn hình Ứng dụng & Cây Điều hướng',
    category: '3. Tính năng & Luồng người dùng',
    body: [
      pw.Text('Hệ thống gồm 11 màn hình phân bổ qua Bottom Navigation và Modal Routes:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('TAB ĐIỀU HƯỚNG CHÍNH (BOTTOM NAV):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Bullet(text: 'Tab 0: HomeScreen — Dashboard tổng quan, shortcut, lời chào.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'Tab 1: RoadmapScreen — Lộ trình học tập, lọc theo kỳ, tìm kiếm.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'Tab 2: TasksScreen — Danh sách công việc, lọc trạng thái, checkbox.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'Tab 3: NotesScreen — Danh mục ghi chú, tìm kiếm nhanh, tag môn.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
            ]),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('MÀN HÌNH CHỨC NĂNG & DEMO (MODAL / PUSH):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Bullet(text: 'SignInScreen: Đăng nhập Google, nút thử lại, điều khoản bảo mật.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'CourseDetailScreen: Chi tiết môn, slot học, môn tiên quyết (4 states).', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'NoteEditorScreen: Soạn thảo ghi chú, đính kèm file Cloud Storage.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'AdvisorScreen: Cố vấn học tập 4 cấp, dialog consent, error retry.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'StrategySimScreen: Mô phỏng điểm số, GPA kỳ 5, phân loại danh hiệu.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'SyncVaultScreen: Demo area Firebase: đồng bộ, crashlytics, PDF export.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Bullet(text: 'NotificationsScreen: Trung tâm thông báo, lọc đọc/chưa đọc, xóa tất cả.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
            ]),
          ),
        ],
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 6: FIREBASE AUTH & GOOGLE SIGN-IN
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 6,
    title: 'Firebase Authentication & Phòng thủ Tên miền (@fpt.edu.vn)',
    category: '4. Tích hợp Firebase',
    body: [
      pw.Text('Cơ chế Phòng thủ Chiều sâu 2 lớp (Defense in Depth) — Đảm bảo chỉ sinh viên FPT mới truy cập được:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('LỚP 1: CLIENT OAUTH DOMAIN FILTER', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text('• Cấu hình GoogleSignIn với hostedDomain: "fpt.edu.vn".', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                pw.Text('• Trình chọn tài khoản Google trên điện thoại ưu tiên hiển thị tài khoản FPT Education.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ]),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('LỚP 2: SERVER/CODE GATE KIỂM CHỨNG', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.red900)),
                pw.SizedBox(height: 4),
                pw.Text('• Sau khi nhận AuthCredential, FirebaseAuthService kiểm tra email.endsWith("@fpt.edu.vn").', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                pw.Text('• Nếu vi phạm (ví dụ @gmail.com): Lập tức gọi signOut(), xóa phiên, throw AuthException từ chối.', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
              ]),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp Firebase Authentication Console hiển thị danh sách tài khoản test và UID.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 7: CLOUD FIRESTORE & SECURITY RULES
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 7,
    title: 'Cloud Firestore & Kiến trúc Security Rules Độc lập',
    category: '4. Tích hợp Firebase',
    body: [
      pw.Text('Mô hình dữ liệu phân cấp Owner-Scoped — Dữ liệu người dùng nào chỉ người đó đọc/ghi:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CẤU TRÚC PHÂN CẤP TÀI LIỆU (FIRESTORE SCHEMA):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Text('• /courses/{courseId}: Danh mục môn học chung (Public Read).', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Text('• /users/{uid}/tasks/{taskId}: Công việc cá nhân.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Text('• /users/{uid}/notes/{noteId}: Ghi chú học tập cá nhân.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Text('• /users/{uid}/notifications/{id}: Trung tâm thông báo.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Text('• /users/{uid}/tokens/{token}: Mã FCM push token.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              pw.Text('• /users/{uid}/reports/{reportId}: Metadata báo cáo học tập.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Text(
                '// firestore.rules — Tuyệt đối không có "allow read, write: if true"\n'
                'function isAuthenticated() { return request.auth != null; }\n'
                'function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }\n\n'
                'match /courses/{id} { allow read: if isAuthenticated(); allow write: if false; }\n'
                'match /users/{userId}/{all=**} { allow read, write: if isOwner(userId); }\n'
                'match /{document=**} { allow read, write: if false; } // Default-deny',
                style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.blue900),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp Firestore Console hiển thị cây document users/{uid} và tab Rules đã deploy.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 8: CLOUD STORAGE & PDF REPORTS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 8,
    title: 'Cloud Storage & Tính năng Xuất Báo cáo Học tập (PDF)',
    category: '4. Tích hợp Firebase',
    body: [
      pw.Text('Quy trình Xuất Báo cáo Học tập Khép kín (End-to-End Study Report Flow):',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('1. Consent Dialog', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 2),
                pw.Text('Xin quyền người dùng trước khi tạo và đồng bộ file.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('2. PDF Rendering', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 2),
                pw.Text('Kết xuất bảng điểm, task, note bằng font Unicode DejaVu.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('3. Cloud Upload', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 2),
                pw.Text('Upload lên reports/{uid}/ có thanh tiến độ % trực quan.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('4. Metadata & Share', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 2),
                pw.Text('Lưu Firestore + mở Share Sheet hệ thống để in/chia sẻ.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Text('Storage Security Rules: Giới hạn dung lượng < 10MB, định dạng application/pdf, chỉ chủ sở hữu được ghi.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800)),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp Cloud Storage Console hiển thị bucket và file study_report_*.pdf đã upload.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 9: REMOTE CONFIG & VERSION GATE
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 9,
    title: 'Firebase Remote Config & Cơ chế Cổng Chặn Phiên Bản',
    category: '5. Dịch vụ Firebase Mở rộng',
    body: [
      pw.Text('Quản lý cấu hình ứng dụng động từ Cloud mà không cần phát hành bản cập nhật mới:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Khóa cấu hình (Key)', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Giá trị mặc định', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Hành vi ứng dụng khi kích hoạt', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('maintenance_mode', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('false', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Khi true: Chuyển toàn bộ app sang MaintenanceScreen, tạm dừng mọi thao tác.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('min_app_version', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('"1.0.0"', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Version Gate: Chặn mở app và hiển thị VersionBlockedScreen nếu version hiện tại < min_version.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('feature_ai_advisor_enabled', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('true', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Feature Flag: Bật/tắt tính năng Cố vấn học tập linh hoạt từ console.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('banner_message', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('"StudyPilot"', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cập nhật câu chào/thông điệp khẩn trên thanh AppBar mà không cần re-deploy app.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
          ]),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp Remote Config Console trước/sau khi thay đổi giá trị và giao diện app tương ứng.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 10: FCM NOTIFICATIONS & ROUTING
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 10,
    title: 'Firebase Cloud Messaging (FCM) & Xử lý 3 Trạng thái',
    category: '5. Dịch vụ Firebase Mở rộng',
    body: [
      pw.Text('Trung tâm thông báo đẩy hỗ trợ đầy đủ 3 trạng thái vòng đời ứng dụng di động:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('FOREGROUND (ĐANG MỞ)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 3),
                pw.Text('• Lắng nghe qua onMessage.\n• Hiển thị banner nổi ForegroundPushBanner (elevation 6.0, Semantics liveRegion).\n• Không làm gián đoạn luồng làm việc hiện tại.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BACKGROUND (CHẠY NGẦM)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green900)),
                pw.SizedBox(height: 3),
                pw.Text('• Xử lý qua top-level handler: firebaseMessagingBackgroundHandler.\n• Hiển thị heads-up notification trên khay hệ thống Android.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.purple50, border: pw.Border.all(color: PdfColors.purple300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('TERMINATED (BỊ ĐÓNG)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.purple900)),
                pw.SizedBox(height: 3),
                pw.Text('• Bắt qua getInitialMessage() khi mở app.\n• Điều hướng chính xác theo payload route và course_id đến màn hình đích tương ứng.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp tin nhắn FCM trên thiết bị thật ở cả 3 trạng thái và thao tác tap điều hướng.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 11: ANALYTICS & CRASHLYTICS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 11,
    title: 'Firebase Analytics (13 Events) & Giám sát Crashlytics',
    category: '5. Dịch vụ Firebase Mở rộng',
    body: [
      pw.Text('Giám sát hành vi người dùng và chất lượng ứng dụng theo thời gian thực:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('ANALYTICS: 13 CUSTOM EVENTS (KÈM SANITIZATION)', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Text('• Vượt yêu cầu tối thiểu 7 events của rubric:\n  login_success, course_view, prerequisite_check, search_course,\n  task_create, task_complete, note_create, advisor_query,\n  sync_triggered, export_report, notification_received,\n  strategy_view, strategy_preset_applied.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              pw.SizedBox(height: 3),
              pw.Text('• Gán setUserId(uid) sau khi đăng nhập thành công.\n• Lọc bỏ 100% PII (không gửi email, tên thật, nội dung note).', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.green800)),
            ]),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('CRASHLYTICS: GIÁM SÁT SỰ CỐ & CUSTOM KEYS', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Text('• Tự động bắt lỗi không đồng bộ qua PlatformDispatcher.instance.onError và FlutterError.onError.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              pw.Text('• Gán userIdentifier = uid và Custom Key: auth_method = "google".', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              pw.Text('• Nút kiểm thử non-fatal crash trong SyncVaultScreen để xác nhận log.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
            ]),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(color: PdfColors.yellow50, border: pw.Border.all(color: PdfColors.amber800, width: 0.5)),
        child: pw.Text('[⏳ CHỜ ẢNH RUNTIME]: Ảnh chụp DebugView trên Firebase Console ghi nhận 13 sự kiện và dashboard Crashlytics.',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.brown900)),
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 12: ACADEMIC ADVISOR (4 LEVELS)
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 12,
    title: 'Cố vấn Học tập 4 Cấp (Advisor) & Xác nhận Chia sẻ Dữ liệu',
    category: '3. Tính năng & Luồng người dùng',
    body: [
      pw.Text('Tính năng Cố vấn Học tập đáp ứng đầy đủ yêu cầu Rubric §6.4:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('4 CẤP ĐỘ TƯ VẤN (CHOICECHIP UI):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 3),
                pw.Text('1. Môn học (Course): Tư vấn slot, bài tập, giảng viên.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                pw.Text('2. Kỳ học (Semester): Phân bổ tải học tập, môn tiên quyết.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                pw.Text('3. Chương trình (Program): Lộ trình OJT, đồ án tốt nghiệp.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                pw.Text('4. Điểm số (Score): Mục tiêu GPA, học cải thiện.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BẢO MẬT & TRẢI NGHIỆM NGƯỜI DÙNG:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 3),
                pw.Text('• Share Consent Gate: Hộp thoại _askConsent() bật lên trước khi gửi. Fails closed (không gửi nếu chưa đồng ý).', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                pw.Text('• Error & Retry: Hiển thị thông báo khi lỗi mạng, nút "Thử lại" tự động nạp lại câu hỏi trước đó.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                pw.Text('• Disclaimer minh bạch: Nêu rõ câu trả lời tổng hợp từ quy chế FPT trong app (Rule Engine), không bịa đặt AI ngoài.', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
              ]),
            ),
          ),
        ],
      ),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 13: LOCAL VERIFICATION & AUTOMATED CHECKS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 13,
    title: 'Kiểm tra Tự động Cục bộ (Hermetic Suite): 89/89 Tests Pass',
    category: '6. Kiểm thử & Xác minh',
    body: [
      pw.Text('Kết quả kiểm thử tự động nội bộ trước khi build APK:',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Lệnh kiểm tra', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Phạm vi kiểm tra', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kết quả ghi nhận', style: pw.TextStyle(font: fontBold, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Đánh giá', style: pw.TextStyle(font: fontBold, fontSize: 8))),
            ],
          ),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter analyze', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Toàn bộ mã nguồn lib/ và test/', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('No issues found! (ran in 10.6s) — 0 warnings, 0 errors', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter test', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('89 ca kiểm thử Unit & Widget hermetic', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('All 89 tests passed! (100% pass, 0 fail, 0 skip)', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
          pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('flutter build apk --debug', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Biên dịch gói ứng dụng Android', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Built build/app/outputs/flutter-apk/app-debug.apk', style: pw.TextStyle(font: fontRegular, fontSize: 7.5))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PASS (Exit 0)', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green800))),
          ]),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text('Phân bổ 89 tests: Version Gate (16), Remote Config (12), PDF Export (10), Advisor (9), Auth (8), Tasks/Notes (18), Widgets (16).',
          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 14: ARTEMIS E2E TESTING
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 14,
    title: 'Kiểm thử Tự động ARTEMIS E2E & Sự cố Quota 429',
    category: '6. Kiểm thử & Xác minh',
    body: [
      pw.Text('Thực trạng Bộ kiểm thử Tự động Đầu cuối trên Thiết bị Di động (e2e_test/):',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue200, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('HẠ TẦNG ĐÃ SẴN SÀNG:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 3),
                pw.Text('• Hoàn thiện 26 kịch bản kiểm thử ARTEMIS (vượt mức 10 ca yêu cầu).\n• Máy chủ ARTEMIS daemon và Android Emulator (emulator-5554) ở trạng thái overall_ready: true.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red200, width: 0.5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('SỰ CỐ GEMINI QUOTA (HTTP 429):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.red900)),
                pw.SizedBox(height: 3),
                pw.Text('• Khi gửi lệnh chạy, Gemini Free Tier báo cạn kiệt hạn ngạch 20 requests/ngày.\n• Tuân thủ Liêm chính Học thuật: KHÔNG giả tạo kết quả PASS; giữ nguyên trạng thái BLOCKED và sẵn sàng chạy lại.', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
              ]),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text('Bằng chứng sự cố: Nhật ký chi tiết lưu tại evidence/artemis/RUN_LOG_2026-11-04.md.',
          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
    ],
  ));

  // ----------------------------------------------------
  // SLIDE 15: AI REVIEW, METRICS & READINESS
  // ----------------------------------------------------
  doc.addPage(createSlide(
    slideNum: 15,
    title: 'AI Code Review, Ba Chỉ số Tiến độ & Kế hoạch Nộp bài',
    category: '7. Tổng kết & Sẵn sàng',
    body: [
      pw.Text('Tổng kết 3 Chỉ số Tiến độ Minh bạch (Reconciled Metrics):',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
      pw.SizedBox(height: 6),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('100%', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green900)),
                pw.Text('Hoàn thiện Code', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green900)),
                pw.SizedBox(height: 2),
                pw.Text('11 màn hình, tokens, MVVM, 4 advisor levels, fail-loud, rules.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.blue50, border: pw.Border.all(color: PdfColors.blue300, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('75.0%', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900)),
                pw.Text('Kiểm thử / Xác minh', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blue900)),
                pw.SizedBox(height: 2),
                pw.Text('(Static 100% + Test 100% + Build 100% + E2E 0%) / 4. Trọng số: 70%.', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.orange50, border: pw.Border.all(color: PdfColors.orange300, width: 0.5)),
              child: pw.Column(children: [
                pw.Text('83.95%', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange900)),
                pw.Text('Sẵn sàng Nộp bài', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.orange900)),
                pw.SizedBox(height: 2),
                pw.Text('8 nhóm rubric (G8 tăng lên 82% nhờ hoàn tất 10 trang Report & 15 Slides).', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
              ]),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text('KẾ HOẠCH HÀNH ĐỘNG CUỐI CÙNG TRƯỚC KHI NỘP: '
          'Định danh nhóm: GR6 · Repo: PRM393_Final_GR6.',
          style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey800)),
    ],
  ));

  // Lưu file PDF
  final bytes = await doc.save();
  final outDir = Directory('slides');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File('slides/PRM393_LAB3_GR6_draft.pdf');
  await outFile.writeAsBytes(bytes);

  print('Successfully generated Slides PDF: ${outFile.path}');
  print('Total slides: ${doc.document.pdfPageList.pages.length} (Target: 12-15 slides)');
}
