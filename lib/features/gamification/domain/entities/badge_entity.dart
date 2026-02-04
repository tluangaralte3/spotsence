import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'badge_entity.freezed.dart';

/// Badge entity (domain layer)
@freezed
class BadgeEntity with _$BadgeEntity {
  const factory BadgeEntity({
    required String id,
    required String name,
    required String description,
    required String iconUrl,
    required BadgeCategory category,
    required BadgeRarity rarity,
    required int pointsRequired,
    int? visitRequired,
    int? contributionRequired,
    DateTime? earnedAt,
    bool? isEarned,
  }) = _BadgeEntity;

  const BadgeEntity._();

  /// Get rarity color code
  String get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return '#9E9E9E';
      case BadgeRarity.rare:
        return '#2196F3';
      case BadgeRarity.epic:
        return '#9C27B0';
      case BadgeRarity.legendary:
        return '#FF9800';
    }
  }
}
