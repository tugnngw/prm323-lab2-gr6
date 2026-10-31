import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import 'analytics_service.dart';
import 'firestore_service.dart';
import 'report_pdf_service.dart';
import 'storage_service.dart';

/// Result of a completed report export: where the file went and its size.
class ReportExportResult {
  const ReportExportResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.pdfBytes,
  });

  final String storagePath;
  final String downloadUrl;
  final Uint8List pdfBytes;
  int get bytes => pdfBytes.length;
}

/// Orchestrates the Lab 3 §6.5 export flow end-to-end:
/// generate PDF → upload to Storage (with progress) → store metadata in
/// Firestore → emit the `export_report` analytics event.
///
/// All collaborators are injected through interfaces so the whole flow is
/// testable without Firebase (audit S-07: no type checks on the impl).
class ReportExportService {
  ReportExportService({
    ReportPdfService? pdfService,
    required StorageService storageService,
    required FirestoreService firestoreService,
    required AnalyticsService analyticsService,
  })  : _pdf = pdfService ?? ReportPdfService(),
        _storage = storageService,
        _firestore = firestoreService,
        _analytics = analyticsService;

  final ReportPdfService _pdf;
  final StorageService _storage;
  final FirestoreService _firestore;
  final AnalyticsService _analytics;

  /// Generates and uploads the report. [onProgress] receives 0.0–1.0.
  ///
  /// Throws on any failing step (fail-loud: the caller surfaces the error and
  /// the event carries status='failed'); never returns a partial success.
  Future<ReportExportResult> exportStudyReport({
    required String userId,
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    void Function(double progress)? onProgress,
    DateTime? generatedAt,
  }) async {
    final startedAt = DateTime.now();
    final timestamp = startedAt;
    final fileName = 'study_report_${timestamp.millisecondsSinceEpoch}.pdf';
    final path = 'reports/$userId/$fileName';

    try {
      final bytes = await _pdf.buildStudyReport(
        generatedAt: timestamp,
        courses: courses,
        tasks: tasks,
        notes: notes,
        // Short opaque hint only — no email/name in the document body.
        uidHint: userId.length > 8 ? '…${userId.substring(userId.length - 8)}' : userId,
      );

      final downloadUrl = await _storage.uploadFile(
        path,
        bytes,
        contentType: 'application/pdf',
        onProgress: onProgress,
      );

      await _firestore.saveReportMetadata(userId, {
        'fileName': fileName,
        'storagePath': path,
        'downloadUrl': downloadUrl,
        'sizeBytes': bytes.length,
        'generatedAt': timestamp.toIso8601String(),
        'courseCount': courses.length,
        'taskCount': tasks.length,
        'noteCount': notes.length,
        'source': 'firebase_demo_area',
      });

      await _analytics.logExportReport(
        status: 'success',
        fileSizeKb: (bytes.length / 1024).ceil(),
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );

      debugPrint('[ReportExport] Uploaded $path (${bytes.length} bytes)');
      return ReportExportResult(
        storagePath: path,
        downloadUrl: downloadUrl,
        pdfBytes: Uint8List.fromList(bytes),
      );
    } catch (e) {
      await _analytics.logExportReport(
        status: 'failed',
        fileSizeKb: 0,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      debugPrint('[ReportExport] FAILED: $e');
      rethrow;
    }
  }
}
