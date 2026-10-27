/// Interface for analytics tracking.
///
/// Will be implemented with Firebase Analytics in the Instrument phase.
/// Must track ≥7 custom events (Lab 3 requirement).
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
  Future<void> setUserId(String id);
  Future<void> setCurrentScreen(String screenName);
}
