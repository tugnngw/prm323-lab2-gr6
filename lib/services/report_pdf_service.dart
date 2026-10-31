import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/course_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';

/// Generates the Lab 3 study-report PDF from live, already-displayed data.
///
/// Vietnamese-capable via bundled DejaVu Sans (asset), so no network fonts.
/// Pure generation — no Firebase here; upload/persistence is the caller's job
/// ([ReportExportService]), which keeps this testable and SDK-free per the
/// MVVM boundary.
class ReportPdfService {
  static const _regularFontAsset = 'assets/fonts/DejaVuSans.ttf';
  static const _boldFontAsset = 'assets/fonts/DejaVuSans-Bold.ttf';

  pw.Font? _regular;
  pw.Font? _bold;

  Future<void> _loadFonts() async {
    if (_regular != null && _bold != null) return;
    _regular ??= pw.Font.ttf(await rootBundle.load(_regularFontAsset));
    _bold ??= pw.Font.ttf(await rootBundle.load(_boldFontAsset));
  }

  /// Builds a PDF summarizing the student's roadmap, tasks and notes —
  /// exactly the data currently shown in the app (guide v5 §6.5).
  ///
  /// Personal identifiers (email, full name, phone) are intentionally NOT
  /// rendered; only aggregate counts and a short opaque uid hint appear.
  Future<List<int>> buildStudyReport({
    required DateTime generatedAt,
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    String? uidHint,
  }) async {
    await _loadFonts();

    final doc = pw.Document(
      title: 'FPTU Second Brain — Báo cáo học tập',
      author: 'FPTU Second Brain',
    );

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final gradeValues =
        courses.map((c) => c.currentGrade).whereType<double>().toList();
    final avgGrade = gradeValues.isEmpty
        ? null
        : gradeValues.reduce((a, b) => a + b) / gradeValues.length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : _buildRunningHeader(),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Trang ${ctx.pageNumber}/${ctx.pagesCount}',
            style: _bodyStyle(size: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _buildTitle(uidHint, generatedAt),
          pw.SizedBox(height: 16),
          _buildSummary(
            courses: courses.length,
            tasksTotal: tasks.length,
            tasksDone: completedTasks,
            notes: notes.length,
            avgGrade: avgGrade,
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Lộ trình môn học'),
          pw.SizedBox(height: 6),
          _buildCoursesTable(courses),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Việc cần làm'),
          pw.SizedBox(height: 6),
          _buildTasksTable(tasks),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Ghi chú'),
          pw.SizedBox(height: 6),
          _buildNotesTable(notes),
          pw.SizedBox(height: 24),
          _buildDisclaimer(),
        ],
      ),
    );

    return doc.save();
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  pw.TextStyle _titleStyle({double size = 20}) => pw.TextStyle(
        font: _bold,
        fontSize: size,
        color: PdfColors.blue900,
      );

  pw.TextStyle _bodyStyle({double size = 10, PdfColor? color}) => pw.TextStyle(
        font: _regular,
        fontSize: size,
        color: color ?? PdfColors.black,
      );

  pw.Widget _buildRunningHeader() => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          'FPTU Second Brain — Báo cáo học tập',
          style: _bodyStyle(size: 9, color: PdfColors.grey700),
        ),
      );

  pw.Widget _buildTitle(String? uidHint, DateTime generatedAt) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Báo cáo học tập', style: _titleStyle(size: 24)),
          pw.SizedBox(height: 4),
          pw.Text(
            'FPTU Second Brain',
            style: _bodyStyle(size: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text('Thời gian xuất: ', style: _bodyStyle(size: 10)),
              pw.Text(_fmtDate(generatedAt),
                  style: _bodyStyle(size: 10, color: PdfColors.blue800)),
            ],
          ),
          if (uidHint != null)
            pw.Row(
              children: [
                pw.Text('Mã người dùng: ', style: _bodyStyle(size: 10)),
                pw.Text(uidHint, style: _bodyStyle(size: 10)),
              ],
            ),
        ],
      );

  pw.Widget _buildSectionTitle(String title) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 1, color: PdfColors.blue300),
          ),
        ),
        child: pw.Text(title, style: _titleStyle(size: 14)),
      );

  pw.Widget _buildSummary({
    required int courses,
    required int tasksTotal,
    required int tasksDone,
    required int notes,
    double? avgGrade,
  }) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _summaryStat('Môn học', '$courses'),
            _summaryStat('Việc cần làm', '$tasksDone/$tasksTotal hoàn thành'),
            _summaryStat('Ghi chú', '$notes'),
            if (avgGrade != null)
              _summaryStat('Điểm TB các môn', avgGrade.toStringAsFixed(2)),
          ],
        ),
      );

  pw.Widget _summaryStat(String label, String value) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _bodyStyle(size: 9, color: PdfColors.grey700)),
          pw.Text(value, style: _bodyStyle(size: 13)),
        ],
      );

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: pw.Text(text, style: _bodyStyle(size: 9)),
      );

  pw.Widget _td(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: pw.Text(
          text.isEmpty ? '—' : text,
          style: bold
              ? pw.TextStyle(font: _bold, fontSize: 9)
              : _bodyStyle(size: 9),
        ),
      );

  pw.Widget _buildCoursesTable(List<CourseModel> courses) {
    if (courses.isEmpty) return _emptyRow('Chưa có môn học nào.');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _th('Mã môn'),
            _th('Tên môn'),
            _th('Kỳ'),
            _th('TC'),
            _th('Tiến độ'),
          ],
        ),
        for (final c in courses)
          pw.TableRow(children: [
            _td(c.code, bold: true),
            _td(c.name),
            _td('${c.semester}'),
            _td('${c.credits}'),
            _td(_progressLabel(c)),
          ]),
      ],
    );
  }

  String _progressLabel(CourseModel c) {
    if (c.totalSlots == 0) return '—';
    final pct = (c.progress * 100).round();
    return '${c.completedSlots}/${c.totalSlots} ($pct%)';
  }

  pw.Widget _buildTasksTable(List<TaskModel> tasks) {
    if (tasks.isEmpty) return _emptyRow('Chưa có việc cần làm nào.');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _th('Trạng thái'),
            _th('Tiêu đề'),
            _th('Môn'),
            _th('Hạn'),
          ],
        ),
        for (final t in tasks)
          pw.TableRow(children: [
            _td(t.isCompleted ? 'Đã xong' : 'Chưa'),
            _td(t.title),
            _td(t.courseCode),
            _td(t.dueDate),
          ]),
      ],
    );
  }

  pw.Widget _buildNotesTable(List<NoteModel> notes) {
    if (notes.isEmpty) return _emptyRow('Chưa có ghi chú nào.');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _th('Tiêu đề'),
            _th('Môn'),
            _th('Cập nhật'),
          ],
        ),
        for (final n in notes)
          pw.TableRow(children: [
            _td(n.title),
            _td(n.courseCode),
            _td(n.updatedAt),
          ]),
      ],
    );
  }

  pw.Widget _emptyRow(String message) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(message,
            style: _bodyStyle(size: 9, color: PdfColors.grey700)),
      );

  pw.Widget _buildDisclaimer() => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'Báo cáo được tạo tự động từ dữ liệu đang hiển thị trong ứng dụng '
          'FPTU Second Brain. Không chứa thông tin cá nhân (email, họ tên, '
          'SĐT) theo quy tắc tối thiểu hóa dữ liệu.',
          style: _bodyStyle(size: 8, color: PdfColors.grey700),
        ),
      );
}
