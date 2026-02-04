import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants/enums.dart';

part 'user_entity.freezed.dart';

/// User entity (domain layer)
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String displayName,
    UserRole? role,
    String? photoUrl,
    String? bio,
    String? phone,
    int? totalPoints,
    List<String>? earnedBadges,
    int? visitCount,
    int? contributionCount,
    DateTime? joinedAt,
    DateTime? lastActive,
  }) = _UserEntity;

  const UserEntity._();

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is contributor
  bool get isContributor => role == UserRole.contributor || isAdmin;

  /// Get user initials for avatar
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName.substring(0, 1).toUpperCase();
  }
}
