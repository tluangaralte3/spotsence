import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/restaurant_entity.dart';

/// Repository interface for restaurants
abstract class RestaurantsRepository {
  /// Get trending restaurants (sorted by rating)
  Future<Either<Failure, List<RestaurantEntity>>> getTrendingRestaurants({
    int limit = 12,
  });

  /// Get restaurants by location
  Future<Either<Failure, List<RestaurantEntity>>> getRestaurantsByLocation(
    String location,
  );

  /// Get restaurant by ID
  Future<Either<Failure, RestaurantEntity>> getRestaurantById(String id);

  /// Search restaurants
  Future<Either<Failure, List<RestaurantEntity>>> searchRestaurants(
    String query,
  );

  /// Get restaurants by cuisine type
  Future<Either<Failure, List<RestaurantEntity>>> getRestaurantsByCuisine(
    String cuisineType,
  );

  /// Get nearby restaurants
  Future<Either<Failure, List<RestaurantEntity>>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusInKm = 10,
  });
}
