import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/enums.dart';
import '../entities/spot_entity.dart';

/// Repository interface for spots
abstract class SpotsRepository {
  /// Get featured spots
  Future<Either<Failure, List<SpotEntity>>> getFeaturedSpots({int limit = 12});

  /// Get spots by category
  Future<Either<Failure, List<SpotEntity>>> getSpotsByCategory(
    SpotCategory category, {
    int limit = 12,
  });

  /// Get all approved spots
  Future<Either<Failure, List<SpotEntity>>> getApprovedSpots({int limit = 12});

  /// Get spot by ID
  Future<Either<Failure, SpotEntity>> getSpotById(String id);

  /// Search spots
  Future<Either<Failure, List<SpotEntity>>> searchSpots(String query);

  /// Get nearby spots
  Future<Either<Failure, List<SpotEntity>>> getNearbySpots({
    required double latitude,
    required double longitude,
    double radiusInKm = 10,
  });

  /// Submit new spot
  Future<Either<Failure, void>> submitSpot(SpotEntity spot);

  /// Update spot
  Future<Either<Failure, void>> updateSpot(SpotEntity spot);

  /// Delete spot
  Future<Either<Failure, void>> deleteSpot(String id);
}
