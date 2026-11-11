import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../services/app_check_service.dart';

/// Turns a Firebase AI failure into one actionable Vietnamese line. The
/// concrete SDK error is named so "no network", a disabled AI Logic service
/// and a failed App Check attestation are distinguishable.
String describeAiFailure(Object error) {
  if (error is TimeoutException) {
    return 'Gemini không phản hồi trong thời gian chờ (timeout). Mạng chậm '
        'hoặc kết nối bị chặn.';
  }
  if (error is ServiceApiNotEnabled) {
    return 'Firebase AI Logic chưa được bật cho dự án (service-api-not-enabled). '
        'Vào Firebase Console → AI Logic → Get started, đợi vài phút rồi thử lại.';
  }
  if (error is InvalidApiKey) {
    return 'Gemini từ chối API key (invalid-api-key). Cần cấu hình lại dự án Firebase.';
  }
  if (error is UnsupportedUserLocation) {
    return 'Gemini không hỗ trợ vị trí hiện tại (unsupported-user-location).';
  }
  if (error is QuotaExceeded) {
    return 'Gemini đã hết hạn mức (quota-exceeded). Thử lại sau.';
  }
  if (error is ServerException) {
    return _describeServerFailure(error.message);
  }
  if (error is FirebaseAIException) {
    return 'Gemini báo lỗi: ${error.message}';
  }
  if (error is FirebaseException) {
    if (error.plugin == 'firebase_app_check') {
      return _describeAppCheckFailure(error);
    }
    switch (error.code) {
      case 'unauthenticated':
        return 'Gemini từ chối xác thực (unauthenticated): App Check chưa có '
            'token hợp lệ. APK cài tay thường vướng Play Integrity.';
      case 'permission-denied':
        return 'Gemini từ chối quyền (permission-denied): App Check / Play '
            'Integrity không qua.';
      case 'failed-precondition':
        return 'Gemini báo failed-precondition: App Check hoặc Firebase AI '
            'Logic chưa được bật cho dự án.';
      case 'unavailable':
        return 'Không kết nối được Gemini (unavailable). Kiểm tra mạng rồi thử lại.';
      default:
        final message = (error.message ?? '').trim();
        return 'Gemini báo lỗi ${error.code}'
            '${message.isEmpty ? '' : ': $message'}.';
    }
  }
  return 'Không kết nối được Gemini (${error.runtimeType}).';
}

String _describeAppCheckFailure(FirebaseException error) {
  final message = (error.message ?? '').trim();
  final integrityFailed =
      message.contains('-14') || message.contains('Integrity API');
  if (integrityFailed) {
    return 'App Check không cấp được token: Play Integrity báo lỗi -14 '
        '(Play Store trên thiết bị chưa cập nhật hoặc APK cài tay không được '
        'chứng thực). Cách xử lý: cập nhật Play Store trên thiết bị, hoặc '
        'build với --dart-define=APP_CHECK_DEBUG=true rồi đăng ký debug token '
        'trong Firebase Console → App Check.';
  }
  final debugTokenRejected = AppCheckService.usesDebugProvider &&
      (message.contains('attestation failed') || message.contains('403'));
  if (debugTokenRejected) {
    return 'Bản này dùng App Check debug provider nhưng debug token chưa được '
        'đăng ký (lỗi 403 App attestation failed). Lấy token ở Logcat bằng '
        'lệnh: adb logcat -d | grep "Firebase App Check debug token", rồi '
        'thêm vào Firebase Console → App Check → Apps → Manage debug tokens. '
        'Token giữ nguyên miễn là không gỡ app hoặc đổi bản debug/release.';
  }
  return 'App Check từ chối yêu cầu (${error.code})'
      '${message.isEmpty ? '' : ': $message'}.';
}

String _describeServerFailure(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('app check') || lower.contains('appcheck')) {
    return 'Gemini từ chối App Check: bản APK cài tay ký bằng debug keystore '
        'nên Play Integrity không qua. Cần build ký release hợp lệ hoặc đăng '
        'ký debug token.';
  }
  if (lower.contains('permission_denied') ||
      lower.contains('permission denied')) {
    return 'Gemini từ chối quyền (permission-denied). Kiểm tra App Check và '
        'AI Logic của dự án.';
  }
  if (lower.contains('unauthenticated')) {
    return 'Gemini từ chối xác thực (unauthenticated). App Check hoặc phiên '
        'đăng nhập chưa hợp lệ.';
  }
  if (lower.contains('no longer available')) {
    return 'Model Gemini đã cấu hình không còn mở cho dự án này. Đổi Remote '
        'Config ai_advisor_model sang gemini-3.5-flash-lite rồi thử lại.';
  }
  if (lower.contains('not found') || lower.contains('not_found')) {
    return 'Không tìm thấy mô hình Gemini đã cấu hình (model-not-found). '
        'Kiểm tra Remote Config ai_advisor_model.';
  }
  if (lower.contains('thinking') && lower.contains('not supported')) {
    return 'Model Gemini không hỗ trợ mức thinking đang cấu hình. Đổi '
        'ai_advisor_model hoặc bỏ cấu hình thinking trong app.';
  }
  if (lower.contains('failed_precondition') ||
      lower.contains('failed precondition')) {
    return 'Gemini báo failed-precondition: bật App Check / Firebase AI Logic '
        'trong Firebase Console.';
  }
  final short = message.length > 160 ? '${message.substring(0, 160)}…' : message;
  return 'Gemini lỗi máy chủ: $short';
}
