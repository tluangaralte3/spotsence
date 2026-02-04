import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'spot_entity.freezed.dart';

/// Spot entity (domain layer) - matches web implementation
@freezed
class SpotEntity with _$SpotEntity {
  const factory SpotEntity({
    required String id,
    required String name,
    required SpotCategory category,
    required String locationAddress,
    required double latitude,
    required double longitude,
    required List<String> imagesUrl,
    String? placeStory,
    double? averageRating,
    int? popularity,
    required bool featured,
    required ApprovalStatus status,
    List<String>? tags,
    String? contributorId,
    DateTime? createdAt,
    DateTime? approvedAt,
    int? visitCount,
    int? reviewCount,
  }) = _SpotEntity;

  const SpotEntity._();

  /// Check if spot is approved
  bool get isApproved => status == ApprovalStatus.approved;

  /// Get display image URL
  String? get displayImage => imagesUrl.isNotEmpty ? imagesUrl.first : null;

  /// Check if spot is popular
  bool get isPopular => (popularity ?? 0) >= 7;
}
