import 'package:flutter/widgets.dart' show NavigatorObserver;
import 'package:prm323_lab3/services/analytics_service.dart';

/// In-memory mock implementation of [AnalyticsService] for hermetic testing.
///
/// Extends the abstract [AnalyticsService] so the named Lab 3 event helpers
/// (concrete on the base class) funnel into the overridden [logEvent] and are
/// recorded uniformly.
class MockAnalyticsService extends AnalyticsService {
  final List<Map<String, dynamic>> loggedEvents = [];
  String? currentUserId;
  String? currentScreen;

  @override
  List<NavigatorObserver> get navigatorObservers => const [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    loggedEvents.add({
      'name': name,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setUserId(String id) async {
    currentUserId = id;
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    currentScreen = screenName;
  }
}
