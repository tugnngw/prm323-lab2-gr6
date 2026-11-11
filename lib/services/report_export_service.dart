import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'firestore_service.dart';
import 'report_pdf_service.dart';
import 'storage_service.dart';

/// Result of a completed report export: where the file went and its size.
class ReportExportResult {
  const ReportExportResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.pdfBytes,
    this.metadataSynced = true,
  });

  final String storagePath;
  final String downloadUrl;
  final Uint8List pdfBytes;

  /// False when the cloud upload finished but the Firestore metadata write was
  /// still unacknowledged after the deadline (offline/DNS failure). The write
  /// stays queued in Firestore's local cache and lands when connectivity
  /// returns, so this is a warning rather than a failed export.
  final bool metadataSynced;
  int get bytes => pdfBytes.length;
}

class StudyReportEntry {
  const StudyReportEntry({
    required this.path,
    required this.fileName,
    required this.provider,
    required this.generatedAt,
  });

  final String path;
  final String fileName;
  final String provider;
  final DateTime? generatedAt;
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
    StorageService? firebaseStorageService,
    CrashlyticsService? crashlyticsService,
    this.storageProvider = 'Firebase Cloud Storage',
    this.metadataTimeout = const Duration(seconds: 12),
  }) : _pdf = pdfService ?? ReportPdfService(),
       _storage = storageService,
       _firebaseStorage = firebaseStorageService,
       _firestore = firestoreService,
       _analytics = analyticsService,
       _crashlytics = crashlyticsService;

  final String storageProvider;
  final Duration metadataTimeout;
  final ReportPdfService _pdf;
  final StorageService _storage;
  final StorageService? _firebaseStorage;
  final FirestoreService _firestore;
  final AnalyticsService _analytics;
  final CrashlyticsService? _crashlytics;

  Future<Uint8List> downloadStudyReport(String path) async =>
      Uint8List.fromList(await _storage.downloadFile(path));

  Future<List<StudyReportEntry>> recentReports(String uid) async {
    final records = await _firestore.getRecentReportMetadata(uid);
    final pattern = RegExp(r'^study_report_\d{13}\.pdf$');
    final reports = <StudyReportEntry>[];
    for (final record in records) {
      final path = record['storagePath'];
      final name = record['fileName'];
      if (path is! String ||
          name is! String ||
          !pattern.hasMatch(name) ||
          path != 'reports/$uid/$name') {
        continue;
      }
      final date = record['generatedAt'];
      final provider = record['storageProvider'];
      reports.add(
        StudyReportEntry(
          path: path,
          fileName: name,
          provider: provider is String ? provider : 'Firebase Cloud Storage',
          generatedAt: date is String ? DateTime.tryParse(date) : null,
        ),
      );
    }
    return reports;
  }

  Future<Uint8List> downloadSavedReport(StudyReportEntry report) async {
    final storage = report.provider == storageProvider
        ? _storage
        : report.provider == 'Firebase Cloud Storage'
        ? _firebaseStorage
        : null;
    if (storage == null) {
      throw StateError('Dịch vụ lưu báo cáo này chưa được cấu hình.');
    }
    return Uint8List.fromList(await storage.downloadFile(report.path));
  }

  /// Builds a real PDF without contacting Storage or creating cloud metadata.
  Future<Uint8List> generateLocalStudyReport({
    required String userId,
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    DateTime? generatedAt,
  }) async => Uint8List.fromList(
    await _pdf.buildStudyReport(
      generatedAt: generatedAt ?? DateTime.now(),
      courses: courses,
      tasks: tasks,
      notes: notes,
      uidHint: userId.length > 8
          ? '…${userId.substring(userId.length - 8)}'
          : userId,
    ),
  );

  /// Generates and uploads the report. [onProgress] receives 0.0–1.0.
  ///
  /// Throws on any failing step (fail-loud: the caller surfaces the error and
  /// the event carries status='failed'); never returns a partial success.
  Future<void> recordLocalReport({
    required String userId,
    required String fileName,
    required int sizeBytes,
    required DateTime generatedAt,
  }) => _firestore.saveReportMetadata(userId, {
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'source': 'local_pdf',
  });

  Future<ReportExportResult> exportStudyReport({
    required String userId,
    required List<CourseModel> courses,
    required List<TaskModel> tasks,
    required List<NoteModel> notes,
    void Function(double progress)? onProgress,
    DateTime? generatedAt,
  }) async {
    final startedAt = DateTime.now();
    final timestamp = generatedAt ?? startedAt;
    final fileName = 'study_report_${timestamp.millisecondsSinceEpoch}.pdf';
    final path = 'reports/$userId/$fileName';

    try {
      final bytes = await generateLocalStudyReport(
        userId: userId,
        generatedAt: timestamp,
        courses: courses,
        tasks: tasks,
        notes: notes,
      );

      final downloadUrl = await _storage.uploadFile(
        path,
        bytes,
        contentType: 'application/pdf',
        onProgress: onProgress,
      );

      var metadataSynced = true;
      try {
        await _firestore
            .saveReportMetadata(userId, {
              'fileName': fileName,
              'storagePath': path,
              'storageProvider': storageProvider,
              'downloadUrl': downloadUrl,
              'sizeBytes': bytes.length,
              'generatedAt': timestamp.toIso8601String(),
              'courseCount': courses.length,
              'taskCount': tasks.length,
              'noteCount': notes.length,
              'source': 'firebase_demo_area',
            })
            .timeout(metadataTimeout);
      } on TimeoutException {
        metadataSynced = false;
        debugPrint(
          '[ReportExport] Firestore metadata not acknowledged within 12s; '
          'write stays queued in the local cache.',
        );
      }

      await _logExport(
        status: 'success',
        fileSizeKb: (bytes.length / 1024).ceil(),
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );

      debugPrint('[ReportExport] Uploaded $path (${bytes.length} bytes)');
      return ReportExportResult(
        storagePath: path,
        downloadUrl: downloadUrl,
        pdfBytes: Uint8List.fromList(bytes),
        metadataSynced: metadataSynced,
      );
    } catch (e, stack) {
      try {
        await _crashlytics?.recordError(
          StateError("Study report export failed (${e.runtimeType})"),
          stack,
          reason: "report_export",
        );
      } catch (_) {
        // Preserve the export failure even when diagnostics are unavailable.
      }
      await _logExport(
        status: 'failed',
        fileSizeKb: 0,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      debugPrint('[ReportExport] FAILED: $e');
      rethrow;
    }
  }

  Future<void> _logExport({
    required String status,
    required int fileSizeKb,
    required int durationMs,
  }) async {
    try {
      await _analytics.logExportReport(
        status: status,
        fileSizeKb: fileSizeKb,
        durationMs: durationMs,
      );
    } catch (error) {
      debugPrint('[ReportExport] Analytics failed: ${error.runtimeType}');
    }
  }
}
