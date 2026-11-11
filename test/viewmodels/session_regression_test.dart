import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/app_state.dart';
import 'package:prm393_final_gr6/services/crashlytics_service.dart';
import 'package:prm393_final_gr6/viewmodels/advisor_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/auth_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/notes_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/tasks_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_analytics_service.dart';
import '../helpers/mock_auth_service.dart';

class _DelayedStore extends FakeFirestoreService {
  final taskRead = Completer<List<Map<String, dynamic>>>();
  final noteRead = Completer<List<Map<String, dynamic>>>();
  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) => taskRead.future;
  @override
  Future<List<Map<String, dynamic>>> getNotes(String userId) => noteRead.future;
}

class _DelayedDelete extends FakeFirestoreService {
  final deletion = Completer<void>();
  @override
  Future<void> deleteTask(String userId, String taskId) => deletion.future;
}

class _Crashlytics extends CrashlyticsService {
  final ids = <String>[];
  @override
  Future<void> setUserId(String userId) async => ids.add(userId);
}

void main() {
  test(
    'late task and note reads cannot restore private rows after logout',
    () async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final store = _DelayedStore();
      final tasks = TasksViewModel(authService: auth, firestoreService: store);
      final notes = NotesViewModel(authService: auth, firestoreService: store);
      await Future<void>.delayed(Duration.zero); // Deliver auth stream replay.
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      store.taskRead.complete([
        {'id': 'private-task', 'title': 'Private'},
      ]);
      store.noteRead.complete([
        {'id': 'private-note', 'title': 'Private'},
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(tasks.allTasks, isEmpty);
      expect(notes.allNotes, isEmpty);
      expect(tasks.state.state, ViewState.empty);
      expect(notes.state.state, ViewState.empty);
      tasks.dispose();
      notes.dispose();
      auth.dispose();
    },
  );

  test(
    'failed deletion arriving after logout cannot roll back private data',
    () async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final store = _DelayedDelete()
        ..tasks.add({'id': 't1', 'title': 'Private'});
      final vm = TasksViewModel(authService: auth, firestoreService: store);
      await Future<void>.delayed(Duration.zero);
      await vm.loadData();
      final pending = vm.deleteTask('t1');
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      store.deletion.completeError(StateError('network unavailable'));
      expect(await pending, isFalse);
      expect(vm.allTasks, isEmpty);
      expect(vm.lastError, isNull);
      vm.dispose();
      auth.dispose();
    },
  );

  test(
    'disposing during a pending read does not notify disposed listeners',
    () async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final store = _DelayedStore();
      final vm = TasksViewModel(authService: auth, firestoreService: store);
      final pending = vm.loadData();
      vm.dispose();
      store.taskRead.complete([
        {'id': 't1'},
      ]);
      await pending;
      auth.dispose();
    },
  );

  test(
    'logout clears advisor consent, questions and pending replies',
    () async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final vm = AdvisorViewModel(authService: auth);
      vm.grantConsent();
      final pending = vm.askQuestion('private question');
      await auth.signOut();
      await pending;
      expect(vm.hasConsent, isFalse);
      expect(
        vm.messages.any((m) => m.text.contains('private question')),
        isFalse,
      );
      expect(vm.isLoading, isFalse);
      expect(vm.messages, hasLength(1));
      vm.dispose();
      auth.dispose();
    },
  );

  test(
    'logout records one event and clears analytics and crash identity',
    () async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final analytics = MockAnalyticsService();
      final crash = _Crashlytics();
      final vm = AuthViewModel(
        authService: auth,
        analyticsService: analytics,
        crashlyticsService: crash,
      );
      await Future<void>.delayed(Duration.zero);
      await vm.signOut();
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'logout'),
        hasLength(1),
      );
      expect(analytics.currentUserId, '');
      expect(crash.ids.last, '');
      vm.dispose();
      auth.dispose();
    },
  );
}
