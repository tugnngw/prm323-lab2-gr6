import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/note_attachment.dart';
import 'package:prm393_final_gr6/models/note_model.dart';
import 'package:prm393_final_gr6/viewmodels/notes_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/fake_storage_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  late FakeStorageService storage;
  late FakeFirestoreService firestore;
  late NotesViewModel notes;

  setUp(() {
    final auth = MockAuthService(initialUserId: 'student-a');
    storage = FakeStorageService();
    firestore = FakeFirestoreService();
    notes = NotesViewModel(
      authService: auth,
      storageService: storage,
      firestoreService: firestore,
    );
    addTearDown(() {
      notes.dispose();
      auth.dispose();
    });
  });

  test(
    'replacing an attachment deletes the old object only after a guarded save',
    () async {
      const oldPath = 'notes/student-a/original.md';
      const newPath = 'notes/student-a/replacement.md';
      firestore.notes.add({
        'id': 'n1',
        'title': 'Example',
        'content': '',
        'courseCode': 'PRM323',
        'attachmentPath': oldPath,
      });
      await notes.loadData();
      Future<bool> replace(String expectedPath) => notes.saveNote(
        id: 'n1',
        title: 'Example',
        content: '',
        courseCode: 'PRM323',
        attachmentPath: newPath,
        attachmentBefore: (expectedPath, null),
      );
      expect(await replace('notes/student-a/stale.md'), isFalse);
      expect(storage.deletedPaths, isEmpty);
      expect(await replace(oldPath), isTrue);
      expect(firestore.notes.single['attachmentPath'], newPath);
      expect(storage.deletedPaths, [oldPath]);
    },
  );

  test(
    'uploads documents with their MIME types and saves private metadata',
    () async {
      await notes.loadData();
      final types = {
        'lecture.MD': 'text/markdown',
        'sample.pdf': 'application/pdf',
        'outline.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      };
      for (final entry in types.entries) {
        final progress = <double>[];
        final path = await notes.uploadAttachment(
          fileName: entry.key,
          bytes: [1, 2, 3],
          onProgress: progress.add,
        );
        expect(path, startsWith('notes/student-a/'));
        expect(storage.uploads.last['path'], path);
        expect(storage.uploads.last['contentType'], entry.value);
        expect(storage.uploads.last['createDownloadUrl'], isFalse);
        expect(progress, [0.5, 1.0]);
        expect(
          await notes.saveNote(
            title: entry.key,
            content: '',
            courseCode: 'PRM323',
            attachmentPath: path,
            attachmentName: entry.key,
          ),
          isTrue,
        );
        await notes.loadData();
        final stored = notes.allNotes.firstWhere(
          (note) => note.title == entry.key,
        );
        expect(stored.attachmentPath, path);
        expect(stored.attachmentName, entry.key);
        expect(stored.attachmentUrl, isNull);
      }
    },
  );

  test(
    'rejects unsupported, empty and oversized attachments before upload',
    () async {
      expect(
        await notes.uploadAttachment(fileName: 'program.exe', bytes: [1]),
        isNull,
      );
      expect(
        await notes.uploadAttachment(fileName: 'empty.md', bytes: []),
        isNull,
      );
      expect(
        await notes.uploadAttachment(
          fileName: 'large.docx',
          bytes: List<int>.filled(NoteAttachment.maxBytesExclusive, 0),
        ),
        isNull,
      );
      expect(storage.uploads, isEmpty);
    },
  );

  test(
    'downloads an owned attachment and rejects paths outside its folder',
    () async {
      storage.downloadBytesToReturn = [1, 2, 3];
      expect(await notes.downloadAttachment('notes/student-a/outline.docx'), [
        1,
        2,
        3,
      ]);
      await expectLater(
        notes.downloadAttachment('notes/student-b/outline.docx'),
        throwsStateError,
      );
      await expectLater(
        notes.downloadAttachment('reports/student-a/report.pdf'),
        throwsStateError,
      );
      expect(storage.downloadPaths, ['notes/student-a/outline.docx']);
    },
  );

  test(
    'routes Cloudinary attachments and existing Firebase attachments',
    () async {
      final auth = MockAuthService(initialUserId: 'student-a');
      final cloud = FakeStorageService()..downloadBytesToReturn = [4];
      storage.downloadBytesToReturn = [8];
      final configured = NotesViewModel(
        authService: auth,
        storageService: storage,
        mediaStorageService: cloud,
      );
      addTearDown(() {
        configured.dispose();
        auth.dispose();
      });
      final path = await configured.uploadAttachment(
        fileName: 'Study plan.DOCX',
        bytes: [1],
      );
      expect(path, matches(r'^notes/student-a/cloudinary/note_\d{16}\.docx$'));
      expect(cloud.uploads.single['createDownloadUrl'], isFalse);
      expect(storage.uploads, isEmpty);
      expect(await configured.downloadAttachment(path!), [4]);
      expect(
        await configured.downloadAttachment('notes/student-a/legacy.pdf'),
        [8],
      );
    },
  );

  test('keeps reading legacy attachment URLs', () {
    const url = 'https://example.test/old-note.pdf';
    final note = NoteModel.fromMap({'attachmentUrl': url});
    expect(note.attachmentUrl, url);
    expect(note.attachmentPath, isNull);
    expect(note.toMap()['attachmentUrl'], url);
  });
}
