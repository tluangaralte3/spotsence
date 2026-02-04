/// App-wide constants for SpotMizoram
class AppConstants {
  // App Info
  static const String appName = 'SpotMizoram';
  static const String appTagline = 'Spot the Soul of Mizoram';
  static const String appVersion = '1.0.0';

  // Firestore Collections (matching web implementation)
  static const String spotsCollection = 'spots';
  static const String restaurantsCollection = 'restaurants';
  static const String adventureSpotsCollection = 'adventureSpots';
  static const String shoppingAreasCollection = 'shoppingAreas';
  static const String usersCollection = 'users';
  static const String badgesCollection = 'badges';
  static const String contributionsCollection = 'contributions';
  static const String leaderboardCollection = 'leaderboard';
  static const String reviewsCollection = 'reviews';
  static const String visitsCollection = 'visits';

  // Firebase Storage Paths
  static const String spotsImagesPath = 'spots';
  static const String restaurantImagesPath = 'restaurants';
  static const String adventureImagesPath = 'adventureSpots';
  static const String shoppingImagesPath = 'shoppingAreas';
  static const String userProfilesPath = 'users';
  static const String badgeIconsPath = 'badges';
  static const String contributionsPath = 'contributions';

  // Pagination
  static const int itemsPerPage = 12;
  static const int defaultLimit = 12;

  // Cache Keys
  static const String cachedSpotsKey = 'cached_spots';
  static const String cachedRestaurantsKey = 'cached_restaurants';
  static const String cachedAdventureKey = 'cached_adventure';
  static const String cachedShoppingKey = 'cached_shopping';
  static const String userPreferencesKey = 'user_preferences';

  // Map Configuration
  static const double defaultZoom = 14.0;
  static const double mizoramLatitude = 23.1645;
  static const double mizoramLongitude = 92.9376;

  // Animation Durations (milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Gamification Points (matching web system)
  static const int checkInPoints = 10;
  static const int submitSpotPoints = 50;
  static const int approvedSpotBonusPoints = 50;
  static const int photoSubmissionPoints = 20;
  static const int writeReviewPoints = 5;
  static const int reviewUpvotePoints = 2;
  static const int shareSpotPoints = 3;

  // Image Settings
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;
  static const int thumbnailSize = 300;

  // Debounce/Throttle
  static const int searchDebounceMs = 500;
  static const int locationUpdateThrottleMs = 5000;
}
