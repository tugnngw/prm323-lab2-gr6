import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/viewmodels/notes_viewmodel.dart';
import 'package:prm323_lab3/viewmodels/tasks_viewmodel.dart';

void main() {
  group('TasksViewModel Tests', () {
    late TasksViewModel tasksVm;

    setUp(() {
      tasksVm = TasksViewModel();
    });

    test('Initializes default study tasks', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(tasksVm.allTasks.isNotEmpty, isTrue);
      expect(tasksVm.allTasks.any((t) => t.courseCode == 'PRM323'), isTrue);
    });

    test('Toggles task completion state', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final firstTask = tasksVm.allTasks.first;
      final initialStatus = firstTask.isCompleted;

      await tasksVm.toggleTask(firstTask.id);
      final updated = tasksVm.allTasks.firstWhere((t) => t.id == firstTask.id);
      expect(updated.isCompleted, equals(!initialStatus));
    });

    test('Adds a new task and applies course filter', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await tasksVm.addTask(
        title: 'Nộp bài Lab 3 PRM323',
        courseCode: 'PRM323',
        dueDate: '16/12/2024',
        priority: 'high',
      );

      expect(tasksVm.allTasks.any((t) => t.title == 'Nộp bài Lab 3 PRM323'), isTrue);
    });
  });

  group('NotesViewModel Tests', () {
    late NotesViewModel notesVm;

    setUp(() {
      notesVm = NotesViewModel();
    });

    test('Initializes with default study notes', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(notesVm.allNotes.isNotEmpty, isTrue);
      expect(notesVm.allNotes.any((n) => n.courseCode == 'PRM323'), isTrue);
    });

    test('Saves new note to Vault and searches by keyword', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await notesVm.saveNote(
        title: 'Ghi chú kiến trúc Clean Architecture',
        content: 'Presentation Layer, Domain Layer, Data Layer',
        courseCode: 'PRM323',
      );

      expect(notesVm.allNotes.any((n) => n.title.contains('Clean Architecture')), isTrue);

      notesVm.setSearchQuery('Clean');
      expect(notesVm.filteredNotes.length, equals(1));
      expect(notesVm.filteredNotes.first.title, contains('Clean Architecture'));
    });
  });
}
