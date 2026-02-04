/// Enums used across the SpotMizoram app

/// Spot categories (matching web implementation)
enum SpotCategory {
  mountains('Mountains'),
  waterfalls('Waterfalls'),
  culturalSites('Cultural Sites'),
  viewpoints('Viewpoints'),
  adventure('Adventure'),
  hotel('Hotel'),
  restaurant('Restaurant'),
  cafe('Cafe'),
  homestay('Homestay'),
  river('River'),
  historicalPlace('Historical Place'),
  park('Park');

  final String displayName;
  const SpotCategory(this.displayName);
}

/// User roles for permissions
enum UserRole {
  tourist('Tourist'),
  contributor('Contributor'),
  admin('Admin'),
  moderator('Moderator');

  final String displayName;
  const UserRole(this.displayName);
}

/// Spot approval status
enum ApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String displayName;
  const ApprovalStatus(this.displayName);
}

/// Price range (matching web: $, $$, $$$, $$$$)
enum PriceRange {
  cheap('\$'),
  moderate('\$\$'),
  expensive('\$\$\$'),
  premium('\$\$\$\$');

  final String displayName;
  const PriceRange(this.displayName);
}

/// Difficulty levels for adventure spots (matching web)
enum DifficultyLevel {
  easy('Easy'),
  moderate('Moderate'),
  hard('Hard'),
  expert('Expert');

  final String displayName;
  const DifficultyLevel(this.displayName);
}

/// Badge categories
enum BadgeCategory {
  visitor('Visitor'),
  contributor('Contributor'),
  explorer('Explorer'),
  social('Social'),
  achievement('Achievement');

  final String displayName;
  const BadgeCategory(this.displayName);
}

/// Badge rarity levels
enum BadgeRarity {
  common('Common'),
  rare('Rare'),
  epic('Epic'),
  legendary('Legendary');

  final String displayName;
  const BadgeRarity(this.displayName);
}

/// Contribution types
enum ContributionType {
  newSpot('New Spot'),
  spotUpdate('Spot Update'),
  photoSubmission('Photo Submission'),
  reviewSubmission('Review Submission'),
  informationCorrection('Information Correction');

  final String displayName;
  const ContributionType(this.displayName);
}

/// Shopping area types
enum ShoppingType {
  market('Market'),
  mall('Mall'),
  street('Street'),
  bazaar('Bazaar');

  final String displayName;
  const ShoppingType(this.displayName);
}

/// Leaderboard period filters
enum LeaderboardPeriod {
  allTime('All Time'),
  monthly('Monthly'),
  weekly('Weekly');

  final String displayName;
  const LeaderboardPeriod(this.displayName);
}

/// Sort options for listings
enum SortOption {
  rating('Rating'),
  popularity('Popularity'),
  nearest('Nearest'),
  newest('Newest');

  final String displayName;
  const SortOption(this.displayName);
}
