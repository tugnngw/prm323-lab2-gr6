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

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    final client = _storage;
    if (client == null) {
      debugPrint('[Storage Mock] uploadFile to $path (${bytes.length} bytes)');
      return 'https://storage.googleapis.com/mock-bucket/$path';
    }

    try {
      final ref = client.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = await ref.putData(Uint8List.fromList(bytes), metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('[Storage] Uploaded successfully to $path');
      return downloadUrl;
    } catch (e) {
      debugPrint('[Storage] uploadFile error: $e');
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadFile(String path) async {
    final client = _storage;
    if (client == null) {
      debugPrint('[Storage Mock] downloadFile from $path');
      return Uint8List(0);
    }

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
    final client = _storage;
    if (client == null) {
      debugPrint('[Storage Mock] deleteFile at $path');
      return;
    }

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
    final client = _storage;
    if (client == null) {
      return 'https://storage.googleapis.com/mock-bucket/$path';
    }

    try {
      final ref = client.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Storage] getDownloadUrl error: $e');
      rethrow;
    }
  }
}
