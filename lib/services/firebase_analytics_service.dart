import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;

import 'analytics_service.dart';

/// Firebase Analytics implementation with strict PII filtering.
///
/// Lab 3 Requirement: Track ≥7 custom events (defined on [AnalyticsService]).
/// Security Rule: Do NOT log personal data (real name, personal email, phone).
/// Extends (not implements) [AnalyticsService] to inherit the 9 named Lab 3
/// event helpers; every one funnels into [logEvent] below.
class FirebaseAnalyticsService extends AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ??
            (Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null);

  final FirebaseAnalytics? _analytics;

  @override
  List<NavigatorObserver> get navigatorObservers {
    final client = _analytics;
    return client != null ? [FirebaseAnalyticsObserver(analytics: client)] : const [];
  }

  // Blacklist of forbidden PII parameter keys
  static const _piiKeys = {
    'email',
    'user_email',
    'name',
    'user_name',
    'full_name',
    'student_name',
    'phone',
    'phone_number',
    'address',
  };

  /// Sanitizes parameters by removing any potential PII keys
  Map<String, Object>? _sanitizeParameters(Map<String, Object>? params) {
    if (params == null) return null;
    final sanitized = <String, Object>{};
    for (final entry in params.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (!_piiKeys.contains(lowerKey)) {
        sanitized[entry.key] = entry.value;
      } else {
        debugPrint('[Analytics] Sanitized PII key "${entry.key}" removed.');
      }
    }
    return sanitized;
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final client = _analytics;
    final sanitized = _sanitizeParameters(parameters);
    if (client == null) {
      // Fail-LOUD-adjacent: production never reaches here (main() gates on
      // Firebase init). If it does, the drop is explicit — never a fake log.
      debugPrint('[Analytics] Firebase not initialized — event DROPPED: $name');
      return;
    }

    try {
      await client.logEvent(name: name, parameters: sanitized);
      debugPrint('[Analytics] Logged event: $name with params: $sanitized');
    } catch (e) {
      debugPrint('[Analytics] logEvent error: $e');
    }
  }

  @override
  Future<void> setUserId(String id) async {
    final client = _analytics;
    if (client == null) {
      debugPrint('[Analytics] Firebase not initialized — setUserId skipped.');
      return;
    }

    try {
      await client.setUserId(id: id);
    } catch (e) {
      debugPrint('[Analytics] setUserId error: $e');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    final client = _analytics;
    if (client == null) {
      debugPrint('[Analytics] Firebase not initialized — screen view skipped.');
      return;
    }

    try {
      await client.logScreenView(screenName: screenName);
      debugPrint('[Analytics] ScreenView: $screenName');
    } catch (e) {
      debugPrint('[Analytics] setCurrentScreen error: $e');
    }
  }

  // The 9 named Lab 3 events are inherited from [AnalyticsService] and all
  // funnel through [logEvent] above, keeping PII sanitization in one place.
}
