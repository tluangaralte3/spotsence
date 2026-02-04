import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/adventure_spot_entity.dart';

/// Repository interface for adventure spots
abstract class AdventureRepository {
  /// Get adventure spots sorted by rating
  Future<Either<Failure, List<AdventureSpotEntity>>> getAdventureSpots({
    int limit = 12,
  });

  /// Get popular adventure spots
  Future<Either<Failure, List<AdventureSpotEntity>>> getPopularAdventureSpots({
    int limit = 12,
  });

  /// Get adventure spot by ID
  Future<Either<Failure, AdventureSpotEntity>> getAdventureSpotById(String id);

  /// Get adventure spots by category
  Future<Either<Failure, List<AdventureSpotEntity>>>
  getAdventureSpotsByCategory(String category);

  /// Get adventure spots by difficulty
  Future<Either<Failure, List<AdventureSpotEntity>>>
  getAdventureSpotsByDifficulty(String difficulty);

  /// Search adventure spots
  Future<Either<Failure, List<AdventureSpotEntity>>> searchAdventureSpots(
    String query,
  );
}
