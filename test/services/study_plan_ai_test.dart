import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/services/study_plan_ai.dart';

void main() {
  test('converts structured output to editable plan text', () {
    final draft = StudyPlanDraft.fromJson(
      '{"goal":"Ôn tập","actions":["Làm bài"]}',
    );
    expect(draft.editableText, 'Ôn tập\n• Làm bài');
  });

  test('rejects bad schema and blank steps before rendering AI output', () {
    for (final value in [
      '{"goal":"Ôn tập","actions":[3]}',
      '{"goal":"Ôn tập","actions":[" "]}',
      '{"goal":"Ôn tập","actions":[]}',
      '{"actions":["Làm bài"]}',
    ]) {
      expect(() => StudyPlanDraft.fromJson(value), throwsFormatException);
    }
  });
}
