import '../models/app_state.dart';
import '../models/note_model.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'base_viewmodel.dart';

class NotesViewModel extends BaseViewModel<List<NoteModel>> {
  NotesViewModel({
    this.firestoreService,
    this.storageService,
    this.analyticsService,
  }) {
    loadData();
  }

  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final AnalyticsService? analyticsService;

  List<NoteModel> _allNotes = [];
  String _searchQuery = '';

  static final List<NoteModel> _defaultNotes = [
    const NoteModel(
      id: 'note_01',
      title: 'Kiến trúc MVVM & Design Tokens PRM323',
      courseCode: 'PRM323',
      content:
          '1. View chỉ phụ trách giao diện và quan sát state qua Provider.\n2. ViewModel quản lý logic và gọi Service.\n3. Service tương tác với Firestore & Storage với bảo mật theo UID.\n4. Design Tokens tập trung tại lib/theme/.',
      updatedAt: 'Hôm nay, 14:30',
      tags: ['PRM323', 'Flutter', 'MVVM'],
    ),
    const NoteModel(
      id: 'note_02',
      title: 'Yêu cầu kiến trúc đồ án SWP391',
      courseCode: 'SWP391',
      content:
          'Sprint 2 tập trung vào MVP cho core features. Cần chuẩn bị tài liệu SRS, kiến trúc cơ sở dữ liệu và kịch bản test.',
      updatedAt: 'Hôm qua, 09:15',
      tags: ['SWP391', 'Sprint2'],
    ),
  ];

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
      if (firestore != null) {
        final docs = await firestore.getNotes('user_p02');
        if (docs.isNotEmpty) {
          _allNotes = docs.map(NoteModel.fromMap).toList();
        } else {
          _allNotes = List.from(_defaultNotes);
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _allNotes = List.from(_defaultNotes);
      }

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

  Future<void> saveNote({
    String? id,
    required String title,
    required String content,
    required String courseCode,
    String? attachmentUrl,
    List<String> tags = const [],
  }) async {
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

    if (isNew) {
      _allNotes.insert(0, note);
    } else {
      final index = _allNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _allNotes[index] = note;
      } else {
        _allNotes.insert(0, note);
      }
    }

    setState(AsyncViewState.data(filteredNotes));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.saveNote({
          ...note.toMap(),
          'userId': 'user_p02',
        });
      } catch (_) {}
    }

    final analytics = analyticsService;
    if (analytics is FirebaseAnalyticsService) {
      analytics.logNoteCreate(
        contentLength: content.length,
      );
    }
  }

  Future<void> deleteNote(String noteId) async {
    _allNotes.removeWhere((n) => n.id == noteId);
    setState(AsyncViewState.data(filteredNotes));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.deleteNote(noteId);
      } catch (_) {}
    }
  }
}
