import 'package:firebase_analytics/firebase_analytics.dart';

/// Simple analytics wrapper that exposes a FirebaseAnalytics instance and an
/// observer. We keep this intentionally small: we only track page/screen views
/// and tab changes (no button-level tracking).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Firebase-provided NavigatorObserver that will emit `screen_view` events
  /// for standard Navigator pushes. We still provide helper methods to log
  /// tab changes explicitly (the bottom nav uses programmatic navigation).
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: analytics);

  Future<void> setCurrentScreen(String screenName) async {
    try {
      // `setCurrentScreen` was removed/changed in recent firebase_analytics
      // versions. Log a `screen_view` event which is the recommended way to
      // record screen changes for analytics pipelines.
      await analytics.logEvent(
        name: 'screen_view',
        parameters: {'screen_name': screenName},
      );
    } catch (_) {
      // noop - analytics may be disabled in tests or unavailable.
    }
  }

  Future<void> logTabChange({
    required String tabName,
    required int index,
  }) async {
    try {
      await analytics.logEvent(
        name: 'tab_change',
        parameters: {'tab_name': tabName, 'tab_index': index},
      );
    } catch (_) {
      // noop
    }
  }
}
