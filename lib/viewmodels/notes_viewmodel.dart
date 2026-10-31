import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../models/note_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'base_viewmodel.dart';

class NotesViewModel extends BaseViewModel<List<NoteModel>> {
  NotesViewModel({
    this.authService,
    this.firestoreService,
    this.storageService,
    this.analyticsService,
  }) {
    loadData();
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final AnalyticsService? analyticsService;

  /// Authenticated UID, or null when no identity is available. Used for all
  /// user-owned reads/writes; never falls back to a persona ID or constant.
  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  List<NoteModel> _allNotes = [];
  String _searchQuery = '';

  String get searchQuery => _searchQuery;
  List<NoteModel> get allNotes => List.unmodifiable(_allNotes);

  List<NoteModel> get filteredNotes {
    if (_searchQuery.isEmpty) return List.unmodifiable(_allNotes);
    final q = _searchQuery.toLowerCase();
    return _allNotes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.courseCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      final uid = currentUserId;
      if (firestore == null || uid == null) {
        // No backend / no identity: empty state — never seeded mock notes.
        _allNotes = [];
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getNotes(uid);
      _allNotes = docs.map(NoteModel.fromMap).toList();

      if (_allNotes.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredNotes));
      }
    } catch (e) {
      setState(AsyncViewState.error('Không thể tải danh sách ghi chú: $e'));
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    setState(AsyncViewState.data(filteredNotes));
  }

  NoteModel? findNoteById(String noteId) {
    try {
      return _allNotes.firstWhere((n) => n.id == noteId);
    } catch (_) {
      return null;
    }
  }

  /// Uploads a note attachment to Cloud Storage and returns its real
  /// download URL (Lab 3 §2.3). Storage rules cap uploads at 10 MB; a larger
  /// file, a missing identity, or any transport failure returns null and sets
  /// [lastError] — the caller must not persist a fabricated URL.
  Future<String?> uploadAttachment({
    required String fileName,
    required List<int> bytes,
  }) async {
    final storage = storageService;
    final uid = currentUserId;
    if (storage == null) {
      setLastError('Cloud Storage chưa sẵn sàng — không thể đính kèm tệp.');
      return null;
    }
    if (uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể tải tệp lên.');
      return null;
    }
    if (bytes.isEmpty) {
      setLastError('Tệp rỗng — không thể tải lên.');
      return null;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      setLastError('Tệp vượt 10 MB — quy định Storage từ chối.');
      return null;
    }
    final contentType = _contentTypeFor(fileName);
    // Storage rules only accept image/*, application/pdf, text/plain —
    // reject others here with a clear message instead of PERMISSION_DENIED.
    if (contentType == 'application/octet-stream') {
      setLastError(
          'Định dạng tệp chưa được hỗ trợ (chỉ nhận PDF, ảnh, .txt).');
      return null;
    }

    final sanitizedName =
        fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'notes/$uid/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
    try {
      final url = await storage.uploadFile(path, bytes,
          contentType: contentType);
      debugPrint('[Notes] Attachment uploaded to $path');
      return url;
    } catch (e) {
      setLastError('Tải tệp lên thất bại. Kiểm tra kết nối và thử lại.');
      return null;
    }
  }

  static String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  /// Saves a note and persists it. Returns true on success; on failure the
  /// optimistic local change is reverted, [lastError] is set, and false is
  /// returned so the editor never shows success for a failed save.
  Future<bool> saveNote({
    String? id,
    required String title,
    required String content,
    required String courseCode,
    String? attachmentUrl,
    List<String> tags = const [],
  }) async {
    if (_isSaving) return false;
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể lưu ghi chú.');
      return false;
    }

    final isNew = id == null || id.isEmpty;
    final noteId = isNew ? 'note_${DateTime.now().millisecondsSinceEpoch}' : id;

    final note = NoteModel(
      id: noteId,
      title: title,
      content: content,
      courseCode: courseCode,
      updatedAt: 'Vừa xong',
      attachmentUrl: attachmentUrl,
      tags: tags,
    );

    // Capture the previous state so a failed write can be reverted exactly.
    final oldIndex = isNew ? -1 : _allNotes.indexWhere((n) => n.id == id);
    final oldNote = oldIndex != -1 ? _allNotes[oldIndex] : null;

    if (isNew) {
      _allNotes.insert(0, note);
    } else if (oldIndex != -1) {
      _allNotes[oldIndex] = note;
    } else {
      _allNotes.insert(0, note);
    }
    setState(AsyncViewState.data(filteredNotes));

    final firestore = firestoreService;
    if (firestore != null) {
      _isSaving = true;
      notifyListeners();
      try {
        await firestore.saveNote({
          ...note.toMap(),
          'userId': uid!,
        });
      } catch (e) {
        if (isNew) {
          _allNotes.removeWhere((n) => n.id == noteId);
        } else if (oldNote != null) {
          _allNotes[oldIndex] = oldNote;
        } else {
          _allNotes.removeWhere((n) => n.id == noteId);
        }
        setState(AsyncViewState.data(filteredNotes));
        setLastError('Không thể lưu ghi chú. Kiểm tra kết nối và thử lại.');
        return false;
      } finally {
        _isSaving = false;
        notifyListeners();
      }
    }
    clearLastError();

    analyticsService?.logNoteCreate(contentLength: content.length);
    return true;
  }

  /// Deletes a note through the service. On failure the item is restored to
  /// the list, [lastError] is set, and false is returned so the UI never
  /// reports a delete that did not happen.
  Future<bool> deleteNote(String noteId) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể xóa ghi chú.');
      return false;
    }

    final index = _allNotes.indexWhere((n) => n.id == noteId);
    if (index == -1) return false;
    final removed = _allNotes[index];
    _allNotes.removeAt(index);
    setState(AsyncViewState.data(filteredNotes));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.deleteNote(uid!, noteId);
      } catch (e) {
        _allNotes.insert(index, removed);
        setState(AsyncViewState.data(filteredNotes));
        setLastError('Không thể xóa ghi chú. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
    clearLastError();
    return true;
  }
}
