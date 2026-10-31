import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Firebase Cloud Storage implementation.
///
/// Follows Lab 3 requirement: All files scoped under user directories
/// `reports/{userId}/...` or `notes/{userId}/...`.
class FirebaseStorageService implements StorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ??
            (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  final FirebaseStorage? _storage;

  /// Fail loud (T04 / guide v5 §1.4): an unconfigured Storage must surface as
  /// an error, never as a fabricated mock URL.
  FirebaseStorage get _client {
    final client = _storage;
    if (client == null) {
      throw StateError(
          'Cloud Storage chưa được khởi tạo (thiếu google-services.json / '
          'Firebase.initializeApp thất bại). Từ chối trả về URL giả lập.');
    }
    return client;
  }

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final client = _client;

    try {
      final ref = client.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final total = event.totalBytes;
          if (total > 0) {
            onProgress((event.bytesTransferred / total).clamp(0.0, 1.0));
          }
        });
      }

      final completed = await uploadTask;
      final downloadUrl = await completed.ref.getDownloadURL();
      debugPrint('[Storage] Uploaded successfully to $path');
      return downloadUrl;
    } catch (e) {
      debugPrint('[Storage] uploadFile error: $e');
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadFile(String path) async {
    final client = _client;
    try {
      final ref = client.ref().child(path);
      // Limit download size to 10MB as safety constraint
      const maxSizeBytes = 10 * 1024 * 1024;
      final data = await ref.getData(maxSizeBytes);
      if (data == null) {
        throw StateError('File at path $path was empty or not found');
      }
      return data;
    } catch (e) {
      debugPrint('[Storage] downloadFile error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    final client = _client;
    try {
      final ref = client.ref().child(path);
      await ref.delete();
      debugPrint('[Storage] Deleted file at $path');
    } catch (e) {
      debugPrint('[Storage] deleteFile error: $e');
      rethrow;
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    final client = _client;
    try {
      final ref = client.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] getDownloadUrl error: $e');
      rethrow;
    }
  }
}
