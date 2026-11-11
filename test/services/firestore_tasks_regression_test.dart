// SDK interfaces are faked only in this adapter regression test, never in production.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/services/firebase_firestore_service.dart';

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.rows);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rows;
  final List<String> paths = [];

  @override
  set settings(Settings value) {}

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    paths.add(path);
    return _Collection(this);
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.store);
  final _Firestore store;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    store.paths.add(path!);
    return _Document(store);
  }

  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) => this;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(store.rows);
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.store);
  final _Firestore store;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    store.paths.add(path);
    return _Collection(store);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Row extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Row(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
}

void main() {
  test(
    'Firestore adapter returns every task and preserves canonical legacy IDs',
    () async {
      final legacy = {'id': 'old-app-id', 'title': 'Legacy'};
      final store = _Firestore([
        _Row('doc-legacy', legacy),
        _Row('task-new', {'id': 'task-new', 'title': 'New'}),
        _Row('doc-no-id', {'title': 'No embedded ID'}),
      ]);
      final result = await FirebaseFirestoreService(firestore: store)
          .getTasks('owner-a');
      expect(result, hasLength(3));
      expect(result.map((t) => t['id']), [
        'doc-legacy',
        'task-new',
        'doc-no-id',
      ]);
      expect(result.first['legacyId'], 'old-app-id');
      expect(result[1].containsKey('legacyId'), isFalse);
      expect(legacy['id'], 'old-app-id');
      expect(store.paths, ['users', 'owner-a', 'tasks']);
    },
  );

  test('Firestore adapter returns an empty list for no tasks', () async {
    final service = FirebaseFirestoreService(firestore: _Firestore([]));
    expect(await service.getTasks('owner-a'), isEmpty);
  });
}
