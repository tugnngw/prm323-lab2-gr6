import 'dart:async';

import '../models/app_state.dart';
import '../models/course_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class RoadmapViewModel extends BaseViewModel<List<CourseModel>> {
  RoadmapViewModel({
    this.authService,
    this.firestoreService,
    this.analyticsService,
  }) {
    loadData();
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final AnalyticsService? analyticsService;

  /// Authenticated UID, or null when no identity is available. Used for the
  /// user-owned course read; never falls back to a persona ID or constant.
  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  List<CourseModel> _allCourses = [];
  String _searchQuery = '';
  bool _filterPrerequisitesOnly = false;
  int _selectedSemester = 5;

  // Passed-course transcript, loaded from the signed-in user's Firestore
  // profile (`users/{uid}.passedCourses`). Empty until loaded — an empty
  // transcript means "no prerequisites satisfied", never seeded demo data.
  Set<String> _passedCourses = {};

  // ── Semester 5 course catalog ──
  // The catalog is Firestore-only now (no mockdata fallback). Seed the
  // `courses` collection in Firestore Console / CLI (docs/seed-courses.json)
  // and it appears here. An empty collection surfaces as the empty state.

  /// Parses `users/{uid}` profile into the passed-course set.
  static Set<String> parsePassedCourses(Map<String, dynamic>? profile) {
    final list = profile?['passedCourses'];
    if (list is List) {
      return list.map((e) => e.toString()).toSet();
    }
    return {};
  }

  // Getters
  List<CourseModel> get allCourses => List.unmodifiable(_allCourses);
  String get searchQuery => _searchQuery;
  bool get filterPrerequisitesOnly => _filterPrerequisitesOnly;
  int get selectedSemester => _selectedSemester;
  Set<String> get passedCourses => Set.unmodifiable(_passedCourses);

  List<CourseModel> get filteredCourses {
    return _allCourses.where((course) {
      // Semester filter
      if (course.semester != _selectedSemester) return false;

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchCode = course.code.toLowerCase().contains(query);
        final matchName = course.name.toLowerCase().contains(query);
        if (!matchCode && !matchName) return false;
      }

      // Prerequisite filter
      if (_filterPrerequisitesOnly) {
        if (course.prerequisites.isEmpty) return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      final uid = currentUserId;
      if (firestore == null || uid == null) {
        // No backend / no identity: show the empty state. Never fall back to
        // seeded mock courses (Lab 3 §1.4 fail-loud, no mockdata).
        _allCourses = [];
        _passedCourses = {};
        setState(const AsyncViewState.empty());
        return;
      }

      // Transcript drives prerequisite checks; courses come from Firestore.
      final profileDoc = await firestore.getUserProfile(uid);
      _passedCourses = parsePassedCourses(profileDoc);
      final docs = await firestore.getCourses(uid);
      _allCourses = docs.map(CourseModel.fromMap).toList();

      if (_allCourses.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredCourses));
      }
    } catch (e) {
      setState(AsyncViewState.error('Không thể tải lộ trình môn học: $e'));
    }
  }

  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    _searchQuery = query;
    setState(AsyncViewState.data(filteredCourses));
    // Log one search_course per settled query, not per keystroke.
    _searchDebounce?.cancel();
    if (query.trim().isNotEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 600), () {
        if (_searchQuery == query) logSearch(query);
      });
    }
  }

  void togglePrerequisiteFilter() {
    _filterPrerequisitesOnly = !_filterPrerequisitesOnly;
    setState(AsyncViewState.data(filteredCourses));
  }

  void selectSemester(int semester) {
    _selectedSemester = semester;
    setState(AsyncViewState.data(filteredCourses));
  }

  /// Checks if the signed-in student satisfies all prerequisites for [course].
  /// Pure predicate — safe to call from `build` (no side effects).
  bool isEligibleForCourse(CourseModel course) {
    if (course.prerequisites.isEmpty) return true;
    return course.prerequisites.every(_passedCourses.contains);
  }

  /// Explicit prerequisite check invoked from a user action; logs the
  /// `prerequisite_check` event exactly once per tap (not per rebuild).
  bool checkEligibilityForCourse(CourseModel course) {
    final isEligible = isEligibleForCourse(course);
    analyticsService?.logPrerequisiteCheck(
        courseId: course.id,
        isEligible: isEligible,
      );
    return isEligible;
  }

  /// Returns missing prerequisites for [course]
  List<String> getMissingPrerequisites(CourseModel course) =>
      course.prerequisites.where((p) => !_passedCourses.contains(p)).toList();

  /// Pure lookup — no analytics side effect (events must not fire from `build`).
  CourseModel? findCourseById(String courseId) {
    try {
      return _allCourses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  /// Called once when Course Detail opens; logs `course_view`.
  void logCourseOpened(String courseId) {
    final course = findCourseById(courseId);
    if (course == null) return;
    analyticsService?.logCourseView(
        courseId: course.id,
        code: course.code,
      );
  }

  /// Called when a search is committed (debounced by the view); logs
  /// `search_course` once per query, not per keystroke.
  void logSearch(String query) {
    if (query.trim().isEmpty) return;
    analyticsService?.logSearchCourse(query: query);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
