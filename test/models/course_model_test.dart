import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/course_model.dart';

void main() {
  group('CourseModel, CourseSlot & CourseLab parsing', () {
    test('MajorModel parses from map without inventing a default major', () {
      final custom = MajorModel.fromMap({
        'code': 'BIT_SE_K19B',
        'name': 'Software Engineering',
        'totalSemesters': 9,
      });
      expect(custom.code, equals('BIT_SE_K19B'));
      expect(custom.name, equals('Software Engineering'));
      expect(custom.totalSemesters, equals(9));
      expect(custom.toMap()['code'], equals('BIT_SE_K19B'));

      final empty = MajorModel.fromMap(const {});
      expect(empty.code, isEmpty);
      expect(empty.name, isEmpty);
    });

    test('CourseSlot parses topic, materials, tasks, and CQs', () {
      final slot = CourseSlot.fromMap({
        'number': 1,
        'topic': 'Flutter Architecture',
        'materials': 'Slide 1, Flutter Docs',
        'tasks': 'Install Flutter SDK',
        'cqs': 'Why use Dart for Flutter?',
      });

      expect(slot.number, equals(1));
      expect(slot.displayTopic, equals('Flutter Architecture'));
      expect(slot.materials, equals('Slide 1, Flutter Docs'));
      expect(slot.tasks, equals('Install Flutter SDK'));
      expect(slot.cqs, equals('Why use Dart for Flutter?'));
      expect(slot.toMap()['topic'], equals('Flutter Architecture'));
    });

    test('CourseLab parses category, duration, weight string, and grading criteria', () {
      final lab = CourseLab.fromMap({
        'id': 'lab1',
        'title': 'Lab 1 Flutter UI',
        'category': 'Lab Assignment',
        'weight': '15%',
        'duration': '90 phút',
        'gradingCriteria': 'Chấm theo rubric M3',
        'deadline': '15/12/2024',
      });

      expect(lab.id, equals('lab1'));
      expect(lab.category, equals('Lab Assignment'));
      expect(lab.weight, equals(15.0));
      expect(lab.duration, equals('90 phút'));
      expect(lab.gradingCriteria, equals('Chấm theo rubric M3'));
      expect(lab.deadline, equals('15/12/2024'));
      expect(lab.toMap()['duration'], equals('90 phút'));
    });

    test('CourseModel keeps missing syllabus data empty instead of fabricating it', () {
      const course = CourseModel(
        id: 'BIT_SE_K19B__PRM323',
        code: 'PRM323',
        name: 'Mobile Programming with Flutter',
        credits: 3,
        semester: 5,
        major: 'BIT_SE_K19B',
      );

      expect(course.slots, isEmpty);
      expect(course.labs, isEmpty);
      expect(course.learningOutcomes, isEmpty);
      expect(course.courseMaterials, isEmpty);
      expect(course.totalSlots, equals(0));
      expect(course.progress, equals(0));
    });

    test('CourseModel.fromMap handles string syllabus, string scores, and string numbers safely', () {
      final course = CourseModel.fromMap({
        'id': 'BIT_SE_K19B__PRM323',
        'code': 'PRM323',
        'name': 'Flutter Mobile',
        'credits': '3',
        'semester': '5',
        'major': 'BIT_SE_K19B',
        'syllabus': 'This is a string syllabus from scraper',
        'totalSlots': '30',
        'completedSlots': '15',
        'currentGrade': '8.75',
        'slots': [
          {
            'slot': '1',
            'topic': 'Intro',
            'cqs': ['Question 1', 'Question 2'],
          },
        ],
        'labs': [
          {
            'id': 101,
            'name': 'Lab 1',
            'weight': '15%',
            'score': '9.0',
          },
        ],
      });

      expect(course.credits, equals(3));
      expect(course.semester, equals(5));
      expect(course.totalSlots, equals(30));
      expect(course.completedSlots, equals(15));
      expect(course.currentGrade, equals(8.75));
      expect(course.slots.first.number, equals(1));
      expect(course.slots.first.cqs, contains('Question 1'));
      expect(course.labs.first.id, equals('101'));
      expect(course.labs.first.weight, equals(15.0));
      expect(course.labs.first.score, equals(9.0));
    });

    test('CourseModel.fromMap parses Desktop FLM scraper Markdown strings into slots and labs', () {
      final course = CourseModel.fromMap({
        'id': 'BIT_SE_K19B__PRM393',
        'code': 'PRM393',
        'name': 'Mobile Programming with Flutter',
        'credits': 3,
        'semester': 5,
        'major': 'BIT_SE_K19B',
        'schedule': '### Slot 1\n- **Topic:** Kiến trúc Flutter & Dart SDK\n- **Materials:** Slide 1\n- **Tasks:** Cài đặt môi trường\n### Slot 2\n- **Topic:** Dart Null Safety\n',
        'assessments': '### Practical Exam (25%)\n- **Thời gian:** 90 phút\n- **Hướng dẫn/Tiêu chí:** Làm bài trên máy\n### Final Exam (30%)\n- **Thời gian:** 60 phút\n',
        'materials': '- **Flutter in Action**\n  - *Tác giả:* Eric Windmill\n  - *Giáo trình chính:* Có\n',
        'los': '- **LO1:** Xây dựng ứng dụng Flutter.\n',
        'cqs': '- **Slot 1 - Q1:** Tại sao Flutter sử dụng ngôn ngữ Dart?\n',
      });

      expect(course.slots.length, equals(2));
      expect(course.slots.first.number, equals(1));
      expect(course.slots.first.topic, equals('Kiến trúc Flutter & Dart SDK'));
      expect(course.slots.first.materials, equals('Slide 1'));
      expect(course.slots.first.tasks, equals('Cài đặt môi trường'));
      expect(course.slots.first.cqs, contains('Tại sao Flutter sử dụng ngôn ngữ Dart?'));
      expect(course.slots[1].number, equals(2));
      expect(course.slots[1].topic, equals('Dart Null Safety'));

      expect(course.labs.length, equals(2));
      expect(course.labs.first.title, equals('Practical Exam'));
      expect(course.labs.first.weight, equals(25.0));
      expect(course.labs.first.duration, equals('90 phút'));
      expect(course.labs.last.title, equals('Final Exam'));
      expect(course.labs.last.weight, equals(30.0));

      expect(course.courseMaterials.length, equals(1));
      expect(course.courseMaterials.first.description, equals('Flutter in Action'));
      expect(course.courseMaterials.first.isMain, isTrue);

      expect(course.learningOutcomes.length, equals(1));
      expect(course.learningOutcomes.first.name, equals('LO1'));
      expect(course.learningOutcomes.first.description, contains('Xây dựng ứng dụng Flutter'));
    });
  });
}
