import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/shopping_area_entity.dart';

/// Repository interface for shopping areas
abstract class ShoppingRepository {
  /// Get shopping areas sorted by rating
  Future<Either<Failure, List<ShoppingAreaEntity>>> getShoppingAreas({
    int limit = 12,
  });

  /// Get popular shopping areas
  Future<Either<Failure, List<ShoppingAreaEntity>>> getPopularShoppingAreas({
    int limit = 12,
  });

  /// Get shopping area by ID
  Future<Either<Failure, ShoppingAreaEntity>> getShoppingAreaById(String id);

  /// Get shopping areas by type
  Future<Either<Failure, List<ShoppingAreaEntity>>> getShoppingAreasByType(
    String type,
  );

  /// Search shopping areas
  Future<Either<Failure, List<ShoppingAreaEntity>>> searchShoppingAreas(
    String query,
  );
}
