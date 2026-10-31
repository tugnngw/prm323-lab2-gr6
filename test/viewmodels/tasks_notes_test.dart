import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_auth_service.dart';
import '../helpers/mock_firestore_service.dart';
import 'package:prm323_lab3/viewmodels/notes_viewmodel.dart';
import 'package:prm323_lab3/viewmodels/tasks_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';

void main() {
  group('TasksViewModel Tests', () {
    late TasksViewModel tasksVm;

    setUp(() {
      final auth = MockAuthService(initialUserId: 'user_default_01');
      final firestore = MockFirestoreService();
      tasksVm = TasksViewModel(
        authService: auth,
        firestoreService: firestore,
      );
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

    test('Passes authenticated UID to user-owned task operations', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_01');
      final fake = FakeFirestoreService();
      final vm = TasksViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      // Add task
      final okAdd = await vm.addTask(
        title: 'Task for user_sec_01',
        courseCode: 'PRM323',
        dueDate: '20/12/2024',
      );
      expect(okAdd, isTrue);
      expect(fake.tasks.length, equals(1));
      expect(fake.tasks.first['userId'], equals('user_sec_01'));

      final addedId = vm.allTasks.first.id;

      // Toggle task
      final okToggle = await vm.toggleTask(addedId);
      expect(okToggle, isTrue);
      expect(fake.tasks.first['userId'], equals('user_sec_01'));
      expect(fake.tasks.first['isCompleted'], isTrue);

      // Delete task
      final okDelete = await vm.deleteTask(addedId);
      expect(okDelete, isTrue);
      expect(fake.deletedTaskCalls, contains('user_sec_01:$addedId'));
    });

    test('Unauthenticated task write is rejected safely without persisting', () async {
      final auth = MockAuthService(initialUserId: null);
      final fake = FakeFirestoreService();
      final vm = TasksViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      // Add task unauthenticated
      final okAdd = await vm.addTask(
        title: 'Unauthorized Task',
        courseCode: 'PRM323',
        dueDate: '20/12/2024',
      );
      expect(okAdd, isFalse);
      expect(vm.lastError, contains('chưa đăng nhập'));
      expect(fake.tasks, isEmpty);

      // Toggle unauthenticated
      final okToggle = await vm.toggleTask('non_existent');
      expect(okToggle, isFalse);
      expect(vm.lastError, contains('chưa đăng nhập'));

      // Delete unauthenticated
      final okDelete = await vm.deleteTask('non_existent');
      expect(okDelete, isFalse);
      expect(vm.lastError, contains('chưa đăng nhập'));
      expect(fake.deletedTaskCalls, isEmpty);
    });

    test('Successful task deletion removes item from list and calls remote service', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_01');
      final fake = FakeFirestoreService();
      final vm = TasksViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      await vm.addTask(
        title: 'Task to be deleted',
        courseCode: 'PRM323',
        dueDate: '20/12/2024',
      );
      final taskId = vm.allTasks.first.id;
      expect(vm.allTasks.any((t) => t.id == taskId), isTrue);

      final ok = await vm.deleteTask(taskId);
      expect(ok, isTrue);
      expect(vm.allTasks.any((t) => t.id == taskId), isFalse);
      expect(fake.deletedTaskCalls, contains('user_sec_01:$taskId'));
      expect(vm.lastError, isNull);
    });

    test('Failed task deletion restores item and surfaces error', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_01');
      final fake = FakeFirestoreService();
      final vm = TasksViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      await vm.addTask(
        title: 'Task fail delete',
        courseCode: 'PRM323',
        dueDate: '20/12/2024',
      );
      final taskId = vm.allTasks.first.id;

      // Arm remote delete to fail
      fake.shouldFailTaskDelete = true;

      final ok = await vm.deleteTask(taskId);
      expect(ok, isFalse);
      // Item must be restored in ViewModel, never silently discarded
      expect(vm.allTasks.any((t) => t.id == taskId), isTrue);
      expect(vm.lastError, contains('Không thể xóa việc cần làm'));
    });
  });

  group('NotesViewModel Tests', () {
    late NotesViewModel notesVm;

    setUp(() {
      final auth = MockAuthService(initialUserId: 'user_default_01');
      final firestore = MockFirestoreService();
      notesVm = NotesViewModel(
        authService: auth,
        firestoreService: firestore,
      );
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

    test('Passes authenticated UID to user-owned note operations', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_02');
      final fake = FakeFirestoreService();
      final vm = NotesViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      final okSave = await vm.saveNote(
        title: 'Note for user_sec_02',
        content: 'Secure content',
        courseCode: 'PRM323',
      );
      expect(okSave, isTrue);
      expect(fake.notes.length, equals(1));
      expect(fake.notes.first['userId'], equals('user_sec_02'));

      final noteId = vm.allNotes.first.id;

      final okDelete = await vm.deleteNote(noteId);
      expect(okDelete, isTrue);
      expect(fake.deletedNoteCalls, contains('user_sec_02:$noteId'));
    });

    test('Unauthenticated note write is rejected safely without persisting', () async {
      final auth = MockAuthService(initialUserId: null);
      final fake = FakeFirestoreService();
      final vm = NotesViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      final okSave = await vm.saveNote(
        title: 'Unauthorized Note',
        content: 'No uid content',
        courseCode: 'PRM323',
      );
      expect(okSave, isFalse);
      expect(vm.lastError, contains('chưa đăng nhập'));
      expect(fake.notes, isEmpty);

      final okDelete = await vm.deleteNote('any_note');
      expect(okDelete, isFalse);
      expect(vm.lastError, contains('chưa đăng nhập'));
      expect(fake.deletedNoteCalls, isEmpty);
    });

    test('Successful note deletion removes item from list and calls remote service', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_02');
      final fake = FakeFirestoreService();
      final vm = NotesViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      await vm.saveNote(
        title: 'Note to delete',
        content: 'Content',
        courseCode: 'PRM323',
      );
      final noteId = vm.allNotes.first.id;
      expect(vm.allNotes.any((n) => n.id == noteId), isTrue);

      final ok = await vm.deleteNote(noteId);
      expect(ok, isTrue);
      expect(vm.allNotes.any((n) => n.id == noteId), isFalse);
      expect(fake.deletedNoteCalls, contains('user_sec_02:$noteId'));
      expect(vm.lastError, isNull);
    });

    test('Failed note deletion restores item and surfaces error', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_02');
      final fake = FakeFirestoreService();
      final vm = NotesViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      await vm.saveNote(
        title: 'Note fail delete',
        content: 'Content',
        courseCode: 'PRM323',
      );
      final noteId = vm.allNotes.first.id;

      // Arm remote delete to fail
      fake.shouldFailNoteDelete = true;

      final ok = await vm.deleteNote(noteId);
      expect(ok, isFalse);
      // Item must be restored in ViewModel, never silently discarded
      expect(vm.allNotes.any((n) => n.id == noteId), isTrue);
      expect(vm.lastError, contains('Không thể xóa ghi chú'));
    });

    test('Failed note save restores previous state and returns false', () async {
      final auth = MockAuthService(initialUserId: 'user_sec_02');
      final fake = FakeFirestoreService();
      final vm = NotesViewModel(authService: auth, firestoreService: fake);
      await vm.loadData();

      // Arm remote save to fail
      fake.shouldFailNoteSave = true;

      final ok = await vm.saveNote(
        title: 'Unsaved Note',
        content: 'This note should fail to persist',
        courseCode: 'PRM323',
      );
      expect(ok, isFalse);
      expect(vm.allNotes.any((n) => n.title == 'Unsaved Note'), isFalse);
      expect(vm.lastError, contains('Không thể lưu ghi chú'));
      expect(vm.isSaving, isFalse);
    });
  });
}
