import 'analytics_service.dart';

/// In-memory mock implementation of [AnalyticsService] for hermetic testing.
class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> loggedEvents = [];
  String? currentUserId;
  String? currentScreen;

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
