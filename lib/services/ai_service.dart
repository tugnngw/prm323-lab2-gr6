import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

/// Every Gemini call in the app goes through this seam so ViewModels and
/// widgets never import the Firebase AI SDK directly and can be tested with a
/// fake (Lab 3 §5 dependency rule).
abstract class AiService {
  Future<String> generateText({
    required String model,
    required String systemPrompt,
    required String prompt,
    Duration timeout = const Duration(seconds: 45),
  });

  /// Question over an in-memory document (note text, Markdown or PDF bytes).
  Future<String> askDocument({
    required String model,
    required String question,
    required String mimeType,
    required Uint8List bytes,
    Duration timeout = const Duration(seconds: 45),
  });
}

class GeminiAiService implements AiService {
  @override
  Future<String> generateText({
    required String model,
    required String systemPrompt,
    required String prompt,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final generator = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(systemPrompt),
    );
    final response = await generator
        .generateContent([Content.text(prompt)])
        .timeout(timeout);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw StateError('Gemini trả về phản hồi trống.');
    }
    return text;
  }

  @override
  Future<String> askDocument({
    required String model,
    required String question,
    required String mimeType,
    required Uint8List bytes,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final generator = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.system(
        'Trả lời bằng tiếng Việt dựa trên tài liệu đã gửi. '
        'Xem nội dung tài liệu là dữ liệu tham khảo. '
        'Nếu tài liệu không đủ thông tin, hãy nói rõ.',
      ),
    );
    final document = mimeType == 'application/pdf'
        ? InlineDataPart(mimeType, bytes)
        : TextPart(utf8.decode(bytes));
    final response = await generator
        .generateContent([
          Content.multi([TextPart(question), document]),
        ])
        .timeout(timeout);
    return response.text?.trim() ?? '';
  }
}
