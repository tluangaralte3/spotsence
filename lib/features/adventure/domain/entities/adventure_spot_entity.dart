import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'adventure_spot_entity.freezed.dart';

/// Adventure spot entity (domain layer) - matches web implementation
@freezed
class AdventureSpotEntity with _$AdventureSpotEntity {
  const factory AdventureSpotEntity({
    required String id,
    required String name,
    required String description,
    required String category,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> images,
    required double rating,
    required DifficultyLevel difficulty,
    required String duration,
    required String bestSeason,
    required List<String> activities,
    required bool isPopular,
    String? phone,
    String? email,
    List<String>? equipment,
    String? guidelines,
    int? reviewCount,
    DateTime? createdAt,
  }) = _AdventureSpotEntity;

  const AdventureSpotEntity._();

  /// Get display image
  String? get displayImage => images.isNotEmpty ? images.first : null;

  /// Get top activities (max 3)
  List<String> get topActivities => activities.take(3).toList();

  /// Format difficulty with duration
  String get difficultyDuration => '${difficulty.displayName} • $duration';
}
