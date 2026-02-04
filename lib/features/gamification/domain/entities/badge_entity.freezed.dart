// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BadgeEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  BadgeCategory get category => throw _privateConstructorUsedError;
  BadgeRarity get rarity => throw _privateConstructorUsedError;
  int get pointsRequired => throw _privateConstructorUsedError;
  int? get visitRequired => throw _privateConstructorUsedError;
  int? get contributionRequired => throw _privateConstructorUsedError;
  DateTime? get earnedAt => throw _privateConstructorUsedError;
  bool? get isEarned => throw _privateConstructorUsedError;

  /// Create a copy of BadgeEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BadgeEntityCopyWith<BadgeEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BadgeEntityCopyWith<$Res> {
  factory $BadgeEntityCopyWith(
    BadgeEntity value,
    $Res Function(BadgeEntity) then,
  ) = _$BadgeEntityCopyWithImpl<$Res, BadgeEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String iconUrl,
    BadgeCategory category,
    BadgeRarity rarity,
    int pointsRequired,
    int? visitRequired,
    int? contributionRequired,
    DateTime? earnedAt,
    bool? isEarned,
  });
}

/// @nodoc
class _$BadgeEntityCopyWithImpl<$Res, $Val extends BadgeEntity>
    implements $BadgeEntityCopyWith<$Res> {
  _$BadgeEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BadgeEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? category = null,
    Object? rarity = null,
    Object? pointsRequired = null,
    Object? visitRequired = freezed,
    Object? contributionRequired = freezed,
    Object? earnedAt = freezed,
    Object? isEarned = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            iconUrl: null == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as BadgeCategory,
            rarity: null == rarity
                ? _value.rarity
                : rarity // ignore: cast_nullable_to_non_nullable
                      as BadgeRarity,
            pointsRequired: null == pointsRequired
                ? _value.pointsRequired
                : pointsRequired // ignore: cast_nullable_to_non_nullable
                      as int,
            visitRequired: freezed == visitRequired
                ? _value.visitRequired
                : visitRequired // ignore: cast_nullable_to_non_nullable
                      as int?,
            contributionRequired: freezed == contributionRequired
                ? _value.contributionRequired
                : contributionRequired // ignore: cast_nullable_to_non_nullable
                      as int?,
            earnedAt: freezed == earnedAt
                ? _value.earnedAt
                : earnedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isEarned: freezed == isEarned
                ? _value.isEarned
                : isEarned // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BadgeEntityImplCopyWith<$Res>
    implements $BadgeEntityCopyWith<$Res> {
  factory _$$BadgeEntityImplCopyWith(
    _$BadgeEntityImpl value,
    $Res Function(_$BadgeEntityImpl) then,
  ) = __$$BadgeEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String iconUrl,
    BadgeCategory category,
    BadgeRarity rarity,
    int pointsRequired,
    int? visitRequired,
    int? contributionRequired,
    DateTime? earnedAt,
    bool? isEarned,
  });
}

/// @nodoc
class __$$BadgeEntityImplCopyWithImpl<$Res>
    extends _$BadgeEntityCopyWithImpl<$Res, _$BadgeEntityImpl>
    implements _$$BadgeEntityImplCopyWith<$Res> {
  __$$BadgeEntityImplCopyWithImpl(
    _$BadgeEntityImpl _value,
    $Res Function(_$BadgeEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BadgeEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? category = null,
    Object? rarity = null,
    Object? pointsRequired = null,
    Object? visitRequired = freezed,
    Object? contributionRequired = freezed,
    Object? earnedAt = freezed,
    Object? isEarned = freezed,
  }) {
    return _then(
      _$BadgeEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        iconUrl: null == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as BadgeCategory,
        rarity: null == rarity
            ? _value.rarity
            : rarity // ignore: cast_nullable_to_non_nullable
                  as BadgeRarity,
        pointsRequired: null == pointsRequired
            ? _value.pointsRequired
            : pointsRequired // ignore: cast_nullable_to_non_nullable
                  as int,
        visitRequired: freezed == visitRequired
            ? _value.visitRequired
            : visitRequired // ignore: cast_nullable_to_non_nullable
                  as int?,
        contributionRequired: freezed == contributionRequired
            ? _value.contributionRequired
            : contributionRequired // ignore: cast_nullable_to_non_nullable
                  as int?,
        earnedAt: freezed == earnedAt
            ? _value.earnedAt
            : earnedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isEarned: freezed == isEarned
            ? _value.isEarned
            : isEarned // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc

class _$BadgeEntityImpl extends _BadgeEntity {
  const _$BadgeEntityImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.rarity,
    required this.pointsRequired,
    this.visitRequired,
    this.contributionRequired,
    this.earnedAt,
    this.isEarned,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String iconUrl;
  @override
  final BadgeCategory category;
  @override
  final BadgeRarity rarity;
  @override
  final int pointsRequired;
  @override
  final int? visitRequired;
  @override
  final int? contributionRequired;
  @override
  final DateTime? earnedAt;
  @override
  final bool? isEarned;

  @override
  String toString() {
    return 'BadgeEntity(id: $id, name: $name, description: $description, iconUrl: $iconUrl, category: $category, rarity: $rarity, pointsRequired: $pointsRequired, visitRequired: $visitRequired, contributionRequired: $contributionRequired, earnedAt: $earnedAt, isEarned: $isEarned)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BadgeEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.rarity, rarity) || other.rarity == rarity) &&
            (identical(other.pointsRequired, pointsRequired) ||
                other.pointsRequired == pointsRequired) &&
            (identical(other.visitRequired, visitRequired) ||
                other.visitRequired == visitRequired) &&
            (identical(other.contributionRequired, contributionRequired) ||
                other.contributionRequired == contributionRequired) &&
            (identical(other.earnedAt, earnedAt) ||
                other.earnedAt == earnedAt) &&
            (identical(other.isEarned, isEarned) ||
                other.isEarned == isEarned));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    iconUrl,
    category,
    rarity,
    pointsRequired,
    visitRequired,
    contributionRequired,
    earnedAt,
    isEarned,
  );

  /// Create a copy of BadgeEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BadgeEntityImplCopyWith<_$BadgeEntityImpl> get copyWith =>
      __$$BadgeEntityImplCopyWithImpl<_$BadgeEntityImpl>(this, _$identity);
}

abstract class _BadgeEntity extends BadgeEntity {
  const factory _BadgeEntity({
    required final String id,
    required final String name,
    required final String description,
    required final String iconUrl,
    required final BadgeCategory category,
    required final BadgeRarity rarity,
    required final int pointsRequired,
    final int? visitRequired,
    final int? contributionRequired,
    final DateTime? earnedAt,
    final bool? isEarned,
  }) = _$BadgeEntityImpl;
  const _BadgeEntity._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get iconUrl;
  @override
  BadgeCategory get category;
  @override
  BadgeRarity get rarity;
  @override
  int get pointsRequired;
  @override
  int? get visitRequired;
  @override
  int? get contributionRequired;
  @override
  DateTime? get earnedAt;
  @override
  bool? get isEarned;

  /// Create a copy of BadgeEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BadgeEntityImplCopyWith<_$BadgeEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
