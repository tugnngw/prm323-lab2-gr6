import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../utils/version_utils.dart';

// Re-exported so existing call sites keep importing one file (rubric §2 puts
// pure helpers under `lib/utils/`).
export '../utils/version_utils.dart' show compareVersions, isOutdatedVersion;

/// Version of this build. Must match `version:` in `pubspec.yaml`; a test
/// asserts that, so the forced-update gate cannot silently drift (no
/// `package_info_plus` dependency is needed for one constant).
const String kAppVersion = '1.0.0';

/// Firebase Remote Config service.
///
/// Lab 3 Requirement: ≥2 Remote Config parameters.
/// Here we configure 4 parameters with safe default fallbacks:
/// 1. `maintenance_mode` (bool)
/// 2. `feature_ai_advisor_enabled` (bool)
/// 3. `min_app_version` (String)
/// 4. `vault_sync_interval_mins` (int)
///
/// Defaults mirror `firebase/remote-config-defaults.json` (the committed,
/// externalized copy required by audit M-09).
class RemoteConfigService extends ChangeNotifier {
  /// [overrides] lets tests pose as a given Remote Config state without a
  /// Firebase app or a Console deploy (see `test/services/version_gate_test.dart`).
  RemoteConfigService({
    FirebaseRemoteConfig? remoteConfig,
    Map<String, dynamic>? overrides,
  }) : _remoteConfig =
           remoteConfig ??
           (Firebase.apps.isNotEmpty ? FirebaseRemoteConfig.instance : null),
       _overrides = overrides ?? const {};

  final FirebaseRemoteConfig? _remoteConfig;
  final Map<String, dynamic> _overrides;
  String? lastFetchError;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Override → live Remote Config → committed default.
  T _value<T>(String key, T Function(FirebaseRemoteConfig) read) {
    final override = _overrides[key];
    final client = _remoteConfig;
    if (override != null && client == null) return override as T;
    if (client == null) return _defaults[key] as T;
    if (override is T) return override;
    return read(client);
  }

  // Default values
  static const Map<String, dynamic> _defaults = {
    'study_plan_ai_enabled': false,
    'study_plan_ai_model': "gemini-3.5-flash-lite",
    'study_plan_ai_prompt': "Bạn là AI Tutor cho StudyPilot. Gợi ý một mục tiêu học tập và từ 1 đến 4 hành động ngắn, thiết thực phù hợp với đề cương kỳ học (tập trung vào kỹ năng then chốt và các bài thi PE/FE). Không bịa đặt thông tin (Zero-Hallucination), không yêu cầu hay tạo dữ liệu cá nhân (Zero-PII).",
    'maintenance_mode': false,
    'feature_ai_advisor_enabled': true,
    'ai_advisor_model': 'gemini-3.5-flash-lite',
    'ai_advisor_prompt': 'Bạn là Cố vấn học tập AI cho sinh viên Đại học FPT (chuyên ngành Kỹ thuật phần mềm SE). Tư vấn dựa trên đề cương môn học (30 slots, bài tập, chuẩn đầu ra). Trả lời tiếng Việt, súc tích, cấu trúc rõ ràng. Không yêu cầu hay tiết lộ thông tin cá nhân (Zero-PII).',
    'min_app_version': '1.0.0',
    'vault_sync_interval_mins': 30,
  };

  Future<void> initialize() async {
    final client = _remoteConfig;
    if (client == null) {
      debugPrint(
        '[RemoteConfig] No Firebase App initialized, using fallback defaults.',
      );
      return;
    }

    try {
      await client.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(hours: 1),
        ),
      );

      await client.setDefaults(_defaults);
      await fetchAndActivate();
      debugPrint('[RemoteConfig] Initialized successfully with defaults.');
    } catch (e) {
      debugPrint('[RemoteConfig] Initialization error: $e');
    }
  }

  Future<bool> fetchAndActivate() async {
    final client = _remoteConfig;
    if (client == null) {
      lastFetchError = 'Remote Config chưa được kết nối.';
      return false;
    }

    try {
      final updated = await client.fetchAndActivate();
      lastFetchError = null;
      if (!_disposed) notifyListeners();
      debugPrint('[RemoteConfig] fetchAndActivate: updated = $updated');
      return updated;
    } catch (e) {
      lastFetchError = 'Không tải được cấu hình. Đang giữ giá trị hiện hành.';
      if (!_disposed) notifyListeners();
      debugPrint('[RemoteConfig] fetchAndActivate error: $e');
      return false;
    }
  }

  bool get isStudyPlanAiEnabled => _value(
    'study_plan_ai_enabled',
    (c) => c.getBool('study_plan_ai_enabled'),
  );

  String get studyPlanModel =>
      _value('study_plan_ai_model', (c) => c.getString('study_plan_ai_model'));

  String get studyPlanPrompt => _value(
    'study_plan_ai_prompt',
    (c) => c.getString('study_plan_ai_prompt'),
  );

  // Parameter getters
  bool get isMaintenanceMode =>
      _value('maintenance_mode', (c) => c.getBool('maintenance_mode'));

  bool get isAiAdvisorEnabled => _value(
    'feature_ai_advisor_enabled',
    (c) => c.getBool('feature_ai_advisor_enabled'),
  );

  String get aiAdvisorModel =>
      _value('ai_advisor_model', (c) => c.getString('ai_advisor_model'));

  String get aiAdvisorPrompt =>
      _value('ai_advisor_prompt', (c) => c.getString('ai_advisor_prompt'));

  String get minAppVersion =>
      _value('min_app_version', (c) => c.getString('min_app_version'));

  /// True when Remote Config demands a version newer than this build (M-09).
  bool get isVersionBelowMinimum =>
      isOutdatedVersion(kAppVersion, minAppVersion);

  int get vaultSyncIntervalMins => _value(
    'vault_sync_interval_mins',
    (c) => c.getInt('vault_sync_interval_mins'),
  );
}
