import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/badge_entity.dart';

/// Repository interface for gamification features
abstract class GamificationRepository {
  /// Get all available badges
  Future<Either<Failure, List<BadgeEntity>>> getAllBadges();

  /// Get user's earned badges
  Future<Either<Failure, List<BadgeEntity>>> getUserBadges(String userId);

  /// Award badge to user
  Future<Either<Failure, void>> awardBadge({
    required String userId,
    required String badgeId,
  });

  /// Get user points
  Future<Either<Failure, int>> getUserPoints(String userId);

  /// Add points to user
  Future<Either<Failure, void>> addPoints({
    required String userId,
    required int points,
    required String reason,
  });

  /// Get leaderboard
  Future<Either<Failure, List<Map<String, dynamic>>>> getLeaderboard({
    int limit = 100,
  });

  /// Record visit
  Future<Either<Failure, void>> recordVisit({
    required String userId,
    required String spotId,
  });

  /// Check if user can check in (nearby)
  Future<Either<Failure, bool>> canCheckIn({
    required String spotId,
    required double userLat,
    required double userLon,
  });
}
