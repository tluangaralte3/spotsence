abstract class AppConstants {
  // ── API ──────────────────────────────────────────────────────────────────
  /// Change to your deployed Vercel URL for production.
  /// Android emulator: use 'http://10.0.2.2:3000'
  /// iOS simulator:    use 'http://localhost:3000'
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int featuredSpotsLimit = 8;
  static const int leaderboardLimit = 50;

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyTheme = 'app_theme';

  // ── Gamification ──────────────────────────────────────────────────────────
  static const int pointsReview = 10;
  static const int pointsReviewWithPhoto = 15;
  static const int pointsContribute = 10;
  static const int pointsContributeApproved = 100;
  static const int pointsDailyLogin = 2;

  // ── UI ────────────────────────────────────────────────────────────────────
  static const double borderRadius = 16.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 20.0;
  static const double buttonRadius = 14.0;

  // ── Categories ────────────────────────────────────────────────────────────
  static const List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'All', 'emoji': '🗺️'},
    {'id': 'waterfall', 'label': 'Waterfalls', 'emoji': '💧'},
    {'id': 'mountain', 'label': 'Mountains', 'emoji': '⛰️'},
    {'id': 'restaurant', 'label': 'Restaurants', 'emoji': '🍽️'},
    {'id': 'cafe', 'label': 'Cafes', 'emoji': '☕'},
    {'id': 'hotel', 'label': 'Hotels', 'emoji': '🏨'},
    {'id': 'cultural-site', 'label': 'Culture', 'emoji': '🏛️'},
    {'id': 'adventure', 'label': 'Adventure', 'emoji': '🧗'},
    {'id': 'viewpoint', 'label': 'Viewpoints', 'emoji': '👁️'},
    {'id': 'park', 'label': 'Parks', 'emoji': '🌿'},
    {'id': 'shopping', 'label': 'Shopping', 'emoji': '🛍️'},
    {'id': 'religious', 'label': 'Religious', 'emoji': '🙏'},
  ];
}
