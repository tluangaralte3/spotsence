import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'restaurant_entity.freezed.dart';

/// Restaurant entity (domain layer) - matches web implementation
@freezed
class RestaurantEntity with _$RestaurantEntity {
  const factory RestaurantEntity({
    required String id,
    required String name,
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> images,
    required double rating,
    required PriceRange priceRange,
    required List<String> cuisineTypes,
    required String openingHours,
    required bool hasDelivery,
    required bool hasReservation,
    String? phone,
    String? email,
    String? website,
    List<String>? amenities,
    int? reviewCount,
    bool? isFeatured,
    DateTime? createdAt,
  }) = _RestaurantEntity;

  const RestaurantEntity._();

  /// Get primary cuisine type
  String get primaryCuisine =>
      cuisineTypes.isNotEmpty ? cuisineTypes.first : 'Restaurant';

  /// Get display image
  String? get displayImage => images.isNotEmpty ? images.first : null;

  /// Format price range display
  String get priceDisplay => priceRange.displayName;
}
