import 'package:prm393_final_gr6/services/storage_service.dart';

/// Test double for [StorageService] — records uploads, supports failures,
/// and exercises the progress callback like the real Firebase upload does.
class FakeStorageService implements StorageService {
  final List<Map<String, dynamic>> uploads = [];

  bool shouldFailUpload = false;
  String? downloadUrlToReturn;
  List<int> downloadBytesToReturn = const [];
  final List<String> downloadPaths = [];

  /// Progress fractions to emit before completion (default: mid + done).
  List<double> progressSteps = const [0.5, 1.0];

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    bool createDownloadUrl = true,
    void Function(double progress)? onProgress,
  }) async {
    if (shouldFailUpload) {
      throw Exception('Simulated storage upload failure');
    }
    uploads.add({
      'path': path,
      'size': bytes.length,
      'contentType': contentType,
      'createDownloadUrl': createDownloadUrl,
    });
    for (final p in progressSteps) {
      onProgress?.call(p);
    }
    return createDownloadUrl
        ? downloadUrlToReturn ?? 'https://fake.storage/$path'
        : path;
  }

  @override
  Future<List<int>> downloadFile(String path) async {
    downloadPaths.add(path);
    return downloadBytesToReturn;
  }

  @override
  Future<void> deleteFile(String path) async => deletedPaths.add(path);

  final deletedPaths = <String>[];

  @override
  Future<String> getDownloadUrl(String path) async =>
      downloadUrlToReturn ?? 'https://fake.storage/$path';
}
