/// Interface for Cloud Storage operations (file upload/download).
///
/// Will be implemented with Firebase Cloud Storage in the Integrate phase.
abstract class StorageService {
  /// Uploads [bytes] to [path] and returns the public download URL.
  ///
  /// [onProgress], when given, is called with a 0.0–1.0 fraction as the
  /// transfer proceeds (Lab 3 §6.5: upload must show progress).
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    void Function(double progress)? onProgress,
  });
  Future<List<int>> downloadFile(String path);
  Future<void> deleteFile(String path);
  Future<String> getDownloadUrl(String path);
}
