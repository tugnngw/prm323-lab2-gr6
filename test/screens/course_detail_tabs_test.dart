import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_final_gr6/screens/course_detail_screen.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/tasks_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  group('CourseDetailScreen 4 Tabs & Quick Action Tests', () {
    late FakeFirestoreService firestore;
    late MockAuthService auth;
    late RoadmapViewModel roadmapVm;
    late AcademicViewModel academicVm;
    late TasksViewModel tasksVm;

    setUp(() async {
      auth = MockAuthService(initialUserId: 'user_detail_test');
      firestore = FakeFirestoreService()
        ..userProfile = {
          'id': 'user_detail_test',
          'major': 'SE',
          'passedCourses': ['PRO192', 'CSD201'],
        }
        ..courses.add({
          'id': 'SE__PRM323',
          'code': 'PRM323',
          'name': 'Lập trình Di động Flutter',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
          'totalSlots': 1,
          'completedSlots': 0,
          'prerequisites': ['PRO192', 'CSD201'],
          'slots': [
            {
              'number': 1,
              'topic': 'Kiến trúc Flutter & Dart SDK',
              'materials': 'Slide 1',
              'tasks': 'Cài đặt môi trường',
              'cqs': 'Tại sao Flutter dùng Dart?',
            },
          ],
          'learningOutcomes': [
            {'name': 'CLO1', 'description': 'Xây dựng ứng dụng Flutter hoàn chỉnh.'},
          ],
          'courseMaterials': [
            {
              'description': 'Flutter in Action',
              'author': 'Eric Windmill',
              'isMain': true,
            },
          ],
          'labs': [
            {
              'id': 'lab1',
              'title': 'Lab 1 Flutter Basic UI',
              'category': 'Lab Assignment',
              'weight': 15.0,
              'duration': '90 phút',
              'deadline': '20/12/2026',
              'gradingCriteria': 'UI chuẩn M3',
            },
            {
              'id': 'exam',
              'title': 'Final Exam',
              'category': 'Final Exam',
              'weight': 85.0,
            },
          ],
        })
        ..courses.add({
          'id': 'SE__FLM999',
          'code': 'FLM999',
          'name': 'Imported FLM Course',
          'nameVi': 'Môn nhập từ FLM',
          'credits': 3,
          'semester': 7,
          'major': 'SE',
          'totalSlots': 1,
          'completedSlots': 0,
          'degreeLevel': 'Bachelor',
          'timeAllocation': 'Study hour (150h) = 45h contact + 105h self-study',
          'scoringScale': '10',
          'minAvgMarkToPass': '5',
          'learningTeachingMethod': 'Problem based learning',
          'studentTasks': 'Tham dự tối thiểu 80% buổi học',
          'tools': 'Flutter SDK, Android Studio',
          'note': 'Môn bắt buộc của chuyên ngành',
          'decisionNo': '1286/QĐ-ĐHFPT',
          'approvedDate': '11/22/2024',
          'electiveGroups': ['SE_COM*1', 'SE_COM*2'],
          'slots': [
            {
              'number': 1,
              'topic': 'Kiến trúc Flutter & Dart SDK',
              'materials': 'Slide 1',
              'tasks': 'Cài đặt môi trường',
              'teachingType': 'Online',
              'itu': 'ITU-1',
            },
          ],
          'learningOutcomes': [
            {'name': 'CLO1', 'description': 'Xây dựng ứng dụng Flutter hoàn chỉnh.'},
          ],
          'courseMaterials': [
            {
              'description': 'Flutter in Action',
              'author': 'Eric Windmill',
              'publisher': 'Manning',
              'publishedDate': '2020',
              'edition': '2nd',
              'isbn': '978-1617296147',
              'isMain': true,
            },
          ],
        });

      roadmapVm = RoadmapViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      academicVm = AcademicViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      tasksVm = TasksViewModel(
        authService: auth,
        firestoreService: firestore,
      );

      await roadmapVm.loadData();
      await academicVm.loadData();
      await tasksVm.loadData();
    });

    tearDown(() {
      auth.dispose();
      roadmapVm.dispose();
      academicVm.dispose();
      tasksVm.dispose();
    });

    Widget createWidgetUnderTest({String courseId = 'SE__PRM323'}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<RoadmapViewModel>.value(value: roadmapVm),
          ChangeNotifierProvider<AcademicViewModel>.value(value: academicVm),
          ChangeNotifierProvider<TasksViewModel>.value(value: tasksVm),
        ],
        child: MaterialApp(
          home: CourseDetailScreen(courseId: courseId),
        ),
      );
    }

    testWidgets('Renders real syllabus tabs from Firestore data', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Slots học'), findsOneWidget);
      expect(find.text('Đánh giá & Điểm'), findsOneWidget);
      expect(find.text('Tổng quan & Chuẩn đầu ra'), findsOneWidget);
      expect(find.text('Bí kíp cộng đồng'), findsOneWidget);

      expect(find.text('Lịch học theo đề cương môn PRM323'), findsOneWidget);
      expect(find.text('1 buổi học'), findsOneWidget);
      expect(find.text('Slot 1'), findsOneWidget);
      expect(find.text('Kiến trúc Flutter & Dart SDK'), findsOneWidget);
    });

    testWidgets('Tab 2 renders assessments and Quick Action adds deadline to Tasks', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đánh giá & Điểm'));
      await tester.pumpAndSettle();

      expect(find.text('Bài tập & Điểm thành phần'), findsOneWidget);
      expect(find.text('Lab 1 Flutter Basic UI'), findsOneWidget);
      expect(find.text('Trọng số: 15%'), findsOneWidget);
      expect(find.text('Thời gian: 90 phút'), findsOneWidget);

      expect(find.text('Thêm vào Việc cần làm'), findsNWidgets(2));
      final initialTaskCount = tasksVm.allTasks.length;

      await tester.tap(find.text('Thêm vào Việc cần làm').first);
      await tester.pumpAndSettle();

      expect(tasksVm.allTasks.length, equals(initialTaskCount + 1));
      expect(tasksVm.allTasks.first.title, contains('PRM323: Lab 1 Flutter Basic UI'));
      expect(tasksVm.allTasks.first.dueDate, equals('20/12/2026'));

      expect(
        find.text('Đã thêm "Lab 1 Flutter Basic UI" vào danh sách Việc cần làm!'),
        findsOneWidget,
      );
    });

    testWidgets('Tab 2 computes weighted total from real syllabus weights', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đánh giá & Điểm'));
      await tester.pumpAndSettle();

      final scoreFields = find.byType(TextField);
      expect(scoreFields, findsNWidgets(2));
      await tester.enterText(scoreFields.at(0), '8');
      await tester.enterText(scoreFields.at(1), '6');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Lưu điểm thành phần'),
        250,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Điểm tổng tạm tính'), findsOneWidget);
      expect(find.text('6.30 / 10'), findsOneWidget);
      expect(find.text('Tổng trọng số đề cương: 100%'), findsOneWidget);
      expect(find.text('Kết quả tạm tính: qua môn.'), findsOneWidget);

      await tester.tap(find.text('Lưu điểm thành phần'));
      await tester.pumpAndSettle();

      expect(academicVm.componentScoresFor('PRM323'), {
        'lab1': 8.0,
        'exam': 6.0,
      });
      expect(
        firestore.userProfile!['componentScores'],
        {
          'PRM323': {'lab1': 8.0, 'exam': 6.0},
        },
      );
      // The weighted total is written to the transcript by default so
      // prerequisite checks see the grade immediately.
      expect(academicVm.profile.transcript, hasLength(1));
      expect(academicVm.profile.transcript.single.grade, 6.3);
      expect(find.text('Đã lưu. Điểm tổng tạm tính: 6.30/10.'), findsOneWidget);
    });

    testWidgets('Tab 3 renders real LOs/materials and advisor/note actions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tổng quan & Chuẩn đầu ra'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Chuẩn đầu ra môn học (Learning Outcomes)'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Chuẩn đầu ra môn học (Learning Outcomes)'), findsOneWidget);
      expect(find.text('CLO1'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Giáo trình chính'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Giáo trình & Tài liệu học tập'), findsOneWidget);
      expect(find.text('Giáo trình chính'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Hỏi cố vấn về PRM323'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Hỏi cố vấn về PRM323'), findsOneWidget);
      expect(find.text('Tạo ghi chú cho PRM323'), findsOneWidget);
    });

    testWidgets('Tab 4 hosts the community tips section and submit sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bí kíp cộng đồng'));
      await tester.pumpAndSettle();

      expect(find.text('Kinh nghiệm & Bí kíp từ Tiền bối'), findsOneWidget);
      expect(find.text('Gửi bí kíp'), findsOneWidget);

      await tester.tap(find.text('Gửi bí kíp'));
      await tester.pumpAndSettle();

      expect(find.text('Chia sẻ bí kíp môn PRM323'), findsOneWidget);
      expect(find.text('Gửi duyệt'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Mẹo qua PE');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Nên ôn kỹ Provider và SQLite cho bài thi PE, đề rất sát lab 1 và lab 2.',
      );
      await tester.tap(find.text('Gửi duyệt'));
      await tester.pumpAndSettle();

      expect(
        find.text('Cần đăng nhập tài khoản sinh viên và kết nối Firestore để gửi bí kíp.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    });

    testWidgets('Renders imported FLM metadata, elective groups and bibliography', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(courseId: 'SE__FLM999'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tổng quan & Chuẩn đầu ra'));
      await tester.pumpAndSettle();

      expect(find.text('Tự chọn: SE_COM*1'), findsOneWidget);
      expect(find.text('Tự chọn: SE_COM*2'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Thông tin học phần'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Thông tin học phần'), findsOneWidget);
      expect(find.text('Trình độ'), findsOneWidget);
      expect(find.text('Bachelor'), findsOneWidget);
      expect(find.text('Điểm trung bình tối thiểu'), findsOneWidget);
      expect(find.text('Phương pháp dạy - học'), findsOneWidget);
      expect(find.text('Problem based learning'), findsOneWidget);
      expect(find.text('1286/QĐ-ĐHFPT'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Giáo trình & Tài liệu học tập'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('NXB: Manning'), findsOneWidget);
      expect(find.textContaining('ISBN: 978-1617296147'), findsOneWidget);
    });
  });
}
