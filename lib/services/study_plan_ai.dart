import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

class StudyPlanDraft {
  const StudyPlanDraft(this.goal, this.actions);

  factory StudyPlanDraft.fromJson(String json) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> ||
        data['goal'] is! String ||
        data['actions'] is! List) {
      throw const FormatException('Invalid study plan');
    }
    final goal = (data['goal'] as String).trim();
    final actions = data['actions'] as List;
    if (goal.isEmpty ||
        goal.length > 120 ||
        actions.isEmpty ||
        actions.length > 4 ||
        actions.any(
          (item) => item is! String || item.trim().isEmpty || item.length > 100,
        )) {
      throw const FormatException('Invalid study plan fields');
    }
    return StudyPlanDraft(goal, actions.cast<String>());
  }

  final String goal;
  final List<String> actions;

  String get editableText =>
      [goal, ...actions.map((item) => '• $item')].join('\n');
}

/// Desktop-grade AI Tutor prompt instruction for study plan generation.
const String kDesktopStudyPlanSystemInstruction =
    'Bạn là AI Tutor cho StudyPilot (Cố vấn kế hoạch học tập sinh viên FPTU). '
    'Nhiệm vụ: Gợi ý một mục tiêu học tập (goal, tối đa 120 ký tự) và từ 1 đến 4 hành động ôn tập (actions, mỗi hành động tối đa 100 ký tự) '
    'thiết thực, bám sát đề cương đào tạo (30 slots, bài tập thực hành, bài thi PE/FE) của kỳ học được yêu cầu.\n'
    'Quy tắc nghiêm ngặt:\n'
    '1. Tuân thủ nghiêm ngặt ngữ cảnh đề cương và cấu trúc chương trình học FPTU.\n'
    '2. Zero-Hallucination: Tuyệt đối không tự bịa đặt thông tin; nếu không rõ, tập trung vào phương pháp học chuẩn.\n'
    '3. Đưa ra lời khuyên thực tế về cách ôn luyện các kỳ thi khó (Practical Exam PE, Final Exam FE) và các slot học then chốt.\n'
    '4. Tuân thủ bảo mật Zero-PII (không yêu cầu hay tạo thông tin cá nhân).\n'
    '5. Trả về đúng định dạng JSON theo schema đã quy định.';

Future<StudyPlanDraft> generateStudyPlan({
  required int semester,
  required String model,
  required String prompt,
  String? curriculumContext,
}) async {
  if (semester < 1 || semester > 12) throw ArgumentError.value(semester);

  // Combine remote prompt with desktop-grade system guidelines
  final systemInstructionText = prompt.trim().isNotEmpty
      ? '$prompt\n\n$kDesktopStudyPlanSystemInstruction'
      : kDesktopStudyPlanSystemInstruction;

  final promptText = curriculumContext != null && curriculumContext.trim().isNotEmpty
      ? 'Kỳ học: $semester.\n\nNGỮ CẢNH ĐỀ CƯƠNG ĐÀO TẠO FPTU (RAG CONTEXT):\n$curriculumContext\n\nNhiệm vụ: Gợi ý mục tiêu học tập và từ 1 đến 4 hành động ôn tập cụ thể cho các môn học/kỳ thi then chốt của Kỳ $semester. Trả lời bằng tiếng Việt chuẩn JSON.'
      : 'Kỳ học: $semester. Trả lời bằng tiếng Việt chuẩn JSON.';

  final generator = FirebaseAI.googleAI().generativeModel(
    model: model,
    systemInstruction: Content.system(systemInstructionText),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: Schema.object(
        properties: {
          'goal': Schema.string(),
          'actions': Schema.array(items: Schema.string()),
        },
      ),
    ),
  );
  final result = await generator
      .generateContent([
        Content.text(promptText),
      ])
      .timeout(const Duration(seconds: 25));
  return StudyPlanDraft.fromJson(result.text ?? '');
}
