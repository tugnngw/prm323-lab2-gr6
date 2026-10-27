/// Interface for Cloud Storage operations (file upload/download).
///
/// Will be implemented with Firebase Cloud Storage in the Integrate phase.
abstract class StorageService {
  Future<String> uploadFile(String path, List<int> bytes, {String? contentType});
  Future<List<int>> downloadFile(String path);
  Future<void> deleteFile(String path);
  Future<String> getDownloadUrl(String path);
}
