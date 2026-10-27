import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config service.
///
/// Lab 3 Requirement: ≥2 Remote Config parameters.
/// Here we configure 4 parameters with safe default fallbacks:
/// 1. `maintenance_mode` (bool)
/// 2. `feature_ai_advisor_enabled` (bool)
/// 3. `min_app_version` (String)
/// 4. `vault_sync_interval_mins` (int)
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ??
            (Firebase.apps.isNotEmpty ? FirebaseRemoteConfig.instance : null);

  final FirebaseRemoteConfig? _remoteConfig;

  // Default values
  static const Map<String, dynamic> _defaults = {
    'maintenance_mode': false,
    'feature_ai_advisor_enabled': true,
    'min_app_version': '1.0.0',
    'vault_sync_interval_mins': 15,
  };

  Future<void> initialize() async {
    final client = _remoteConfig;
    if (client == null) {
      debugPrint('[RemoteConfig] No Firebase App initialized, using fallback defaults.');
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
    if (client == null) return false;

    try {
      final updated = await client.fetchAndActivate();
      debugPrint('[RemoteConfig] fetchAndActivate: updated = $updated');
      return updated;
    } catch (e) {
      debugPrint('[RemoteConfig] fetchAndActivate error: $e');
      return false;
    }
  }

  // Parameter getters
  bool get isMaintenanceMode =>
      _remoteConfig?.getBool('maintenance_mode') ??
      (_defaults['maintenance_mode'] as bool);

  bool get isAiAdvisorEnabled =>
      _remoteConfig?.getBool('feature_ai_advisor_enabled') ??
      (_defaults['feature_ai_advisor_enabled'] as bool);

  String get minAppVersion =>
      _remoteConfig?.getString('min_app_version') ??
      (_defaults['min_app_version'] as String);

  int get vaultSyncIntervalMins =>
      _remoteConfig?.getInt('vault_sync_interval_mins') ??
      (_defaults['vault_sync_interval_mins'] as int);
}
