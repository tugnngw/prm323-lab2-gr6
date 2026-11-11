import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/note_model.dart';

void main() {
  group('NoteModel.fromMap', () {
    test('formats Firestore Timestamp values for display', () {
      final timestamp = Timestamp.fromDate(DateTime(2026, 11, 2, 10, 46));

      final note = NoteModel.fromMap({
        'id': 'note-test',
        'title': 'Test note',
        'content': 'Test content',
        'courseCode': 'PRM323',
        'updatedAt': timestamp,
      });

      expect(note.updatedAt, '02/11/2026 10:46');
    });

    test('keeps legacy string timestamps and supplies a fallback', () {
      expect(
        NoteModel.fromMap({'updatedAt': 'Vừa xong'}).updatedAt,
        'Vừa xong',
      );
      expect(NoteModel.fromMap({}).updatedAt, 'Vừa xong');
    });
  });
}
