import '../models/app_state.dart';
import '../models/course_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_analytics_service.dart';
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

  // Student P02 (Nguyễn Minh Đức) transcript of passed courses
  final Set<String> _passedCourses = {
    'PRO192',
    'CSD201',
    'MAD101',
    'OSG202',
    'NWC203c',
    'SSG104',
  };

  // Default seed list for Semester 5
  static final List<CourseModel> _defaultCourses = [
    const CourseModel(
      id: 'PRM323',
      code: 'PRM323',
      name: 'Lập trình Di động với Flutter',
      credits: 3,
      semester: 5,
      major: 'SE',
      prerequisites: ['CSD201', 'PRO192'],
      totalSlots: 30,
      completedSlots: 12,
      currentGrade: 8.5,
      lecturer: 'ThS. Nguyễn Văn A',
      status: 'enrolled',
      labs: [
        CourseLab(
          id: 'lab1',
          title: 'Lab 1 — Flutter Basics & M3 Design Tokens',
          deadline: '15/10/2024',
          score: 9.0,
          status: 'graded',
        ),
        CourseLab(
          id: 'lab2',
          title: 'Lab 2 — Figma UI Design & Prototypes',
          deadline: '05/11/2024',
          score: 8.5,
          status: 'graded',
        ),
        CourseLab(
          id: 'lab3',
          title: 'Lab 3 — Firebase Cloud & ARTEMIS Test',
          deadline: '15/12/2024',
          status: 'pending',
        ),
      ],
    ),
    const CourseModel(
      id: 'SWP391',
      code: 'SWP391',
      name: 'Dự án Phát triển Phần mềm',
      credits: 5,
      semester: 5,
      major: 'SE',
      prerequisites: ['SWT301', 'SWE201c'],
      totalSlots: 30,
      completedSlots: 15,
      currentGrade: 7.8,
      lecturer: 'TS. Trần Thị B',
      status: 'enrolled',
      labs: [
        CourseLab(
          id: 'swp_sprint1',
          title: 'Sprint 1 — Inception & Architecture Spec',
          deadline: '20/10/2024',
          score: 8.0,
          status: 'graded',
        ),
        CourseLab(
          id: 'swp_sprint2',
          title: 'Sprint 2 — Core Features MVP',
          deadline: '20/11/2024',
          status: 'pending',
        ),
      ],
    ),
    const CourseModel(
      id: 'SWR302',
      code: 'SWR302',
      name: 'Kỹ thuật Yêu cầu Phần mềm',
      credits: 3,
      semester: 5,
      major: 'SE',
      prerequisites: ['CSD201'],
      totalSlots: 30,
      completedSlots: 10,
      currentGrade: 8.0,
      lecturer: 'ThS. Lê Hoàng C',
      status: 'enrolled',
      labs: [
        CourseLab(
          id: 'swr_a1',
          title: 'Assignment 1 — SRS Document Review',
          deadline: '12/10/2024',
          score: 8.5,
          status: 'graded',
        ),
      ],
    ),
    const CourseModel(
      id: 'SWT301',
      code: 'SWT301',
      name: 'Kiểm thử Phần mềm',
      credits: 3,
      semester: 4,
      major: 'SE',
      prerequisites: ['PRO192'],
      totalSlots: 30,
      completedSlots: 30,
      currentGrade: 8.2,
      status: 'completed',
    ),
  ];

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
      if (firestore != null) {
        if (uid != null) {
          final docs = await firestore.getCourses(uid);
          if (docs.isNotEmpty) {
            _allCourses = docs.map(CourseModel.fromMap).toList();
          } else {
            _allCourses = List.from(_defaultCourses);
          }
        } else {
          // Demo/mock mode: no authenticated identity — keep seeded defaults
          // instead of fabricating one.
          _allCourses = List.from(_defaultCourses);
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _allCourses = List.from(_defaultCourses);
      }

      if (_allCourses.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredCourses));
      }
    } catch (e) {
      setState(AsyncViewState.error('Không thể tải lộ trình môn học: $e'));
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    setState(AsyncViewState.data(filteredCourses));
  }

  void togglePrerequisiteFilter() {
    _filterPrerequisitesOnly = !_filterPrerequisitesOnly;
    setState(AsyncViewState.data(filteredCourses));
  }

  void selectSemester(int semester) {
    _selectedSemester = semester;
    setState(AsyncViewState.data(filteredCourses));
  }

  /// Checks if student P02 satisfies all prerequisites for [course]
  bool isEligibleForCourse(CourseModel course) {
    if (course.prerequisites.isEmpty) return true;
    final isEligible = course.prerequisites.every(_passedCourses.contains);

    final analytics = analyticsService;
    if (analytics is FirebaseAnalyticsService) {
      analytics.logPrerequisiteCheck(
        courseId: course.id,
        isEligible: isEligible,
      );
    }
    return isEligible;
  }

  /// Returns missing prerequisites for [course]
  List<String> getMissingPrerequisites(CourseModel course) =>
      course.prerequisites.where((p) => !_passedCourses.contains(p)).toList();

  CourseModel? findCourseById(String courseId) {
    try {
      final course = _allCourses.firstWhere((c) => c.id == courseId);
      final analytics = analyticsService;
      if (analytics is FirebaseAnalyticsService) {
        analytics.logCourseView(
          courseId: course.id,
          code: course.code,
        );
      }
      return course;
    } catch (_) {
      return null;
    }
  }
}
