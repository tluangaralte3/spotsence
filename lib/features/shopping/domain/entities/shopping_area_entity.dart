import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'shopping_area_entity.freezed.dart';

/// Shopping area entity (domain layer) - matches web implementation
@freezed
class ShoppingAreaEntity with _$ShoppingAreaEntity {
  const factory ShoppingAreaEntity({
    required String id,
    required String name,
    required String description,
    required ShoppingType type,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> images,
    required double rating,
    required String openingHours,
    required List<String> products,
    required PriceRange priceRange,
    required bool hasParking,
    required bool acceptsCards,
    required bool hasDelivery,
    required bool isPopular,
    String? phone,
    String? website,
    int? reviewCount,
    DateTime? createdAt,
  }) = _ShoppingAreaEntity;

  const ShoppingAreaEntity._();

  /// Get display image
  String? get displayImage => images.isNotEmpty ? images.first : null;

  /// Get type display name
  String get typeDisplay => type.displayName;

  /// Check if has essential features
  bool get hasEssentialFeatures => hasParking || acceptsCards || hasDelivery;
}
