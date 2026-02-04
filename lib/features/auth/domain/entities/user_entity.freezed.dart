// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserEntity {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  UserRole? get role => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  int? get totalPoints => throw _privateConstructorUsedError;
  List<String>? get earnedBadges => throw _privateConstructorUsedError;
  int? get visitCount => throw _privateConstructorUsedError;
  int? get contributionCount => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get lastActive => throw _privateConstructorUsedError;

  /// Create a copy of UserEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserEntityCopyWith<UserEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserEntityCopyWith<$Res> {
  factory $UserEntityCopyWith(
    UserEntity value,
    $Res Function(UserEntity) then,
  ) = _$UserEntityCopyWithImpl<$Res, UserEntity>;
  @useResult
  $Res call({
    String id,
    String email,
    String displayName,
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
  });
}

/// @nodoc
class _$UserEntityCopyWithImpl<$Res, $Val extends UserEntity>
    implements $UserEntityCopyWith<$Res> {
  _$UserEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = null,
    Object? role = freezed,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? phone = freezed,
    Object? totalPoints = freezed,
    Object? earnedBadges = freezed,
    Object? visitCount = freezed,
    Object? contributionCount = freezed,
    Object? joinedAt = freezed,
    Object? lastActive = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            role: freezed == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as UserRole?,
            photoUrl: freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            bio: freezed == bio
                ? _value.bio
                : bio // ignore: cast_nullable_to_non_nullable
                      as String?,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalPoints: freezed == totalPoints
                ? _value.totalPoints
                : totalPoints // ignore: cast_nullable_to_non_nullable
                      as int?,
            earnedBadges: freezed == earnedBadges
                ? _value.earnedBadges
                : earnedBadges // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            visitCount: freezed == visitCount
                ? _value.visitCount
                : visitCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            contributionCount: freezed == contributionCount
                ? _value.contributionCount
                : contributionCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            joinedAt: freezed == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastActive: freezed == lastActive
                ? _value.lastActive
                : lastActive // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserEntityImplCopyWith<$Res>
    implements $UserEntityCopyWith<$Res> {
  factory _$$UserEntityImplCopyWith(
    _$UserEntityImpl value,
    $Res Function(_$UserEntityImpl) then,
  ) = __$$UserEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String email,
    String displayName,
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
  });
}

/// @nodoc
class __$$UserEntityImplCopyWithImpl<$Res>
    extends _$UserEntityCopyWithImpl<$Res, _$UserEntityImpl>
    implements _$$UserEntityImplCopyWith<$Res> {
  __$$UserEntityImplCopyWithImpl(
    _$UserEntityImpl _value,
    $Res Function(_$UserEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = null,
    Object? role = freezed,
    Object? photoUrl = freezed,
    Object? bio = freezed,
    Object? phone = freezed,
    Object? totalPoints = freezed,
    Object? earnedBadges = freezed,
    Object? visitCount = freezed,
    Object? contributionCount = freezed,
    Object? joinedAt = freezed,
    Object? lastActive = freezed,
  }) {
    return _then(
      _$UserEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: freezed == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as UserRole?,
        photoUrl: freezed == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        bio: freezed == bio
            ? _value.bio
            : bio // ignore: cast_nullable_to_non_nullable
                  as String?,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalPoints: freezed == totalPoints
            ? _value.totalPoints
            : totalPoints // ignore: cast_nullable_to_non_nullable
                  as int?,
        earnedBadges: freezed == earnedBadges
            ? _value._earnedBadges
            : earnedBadges // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        visitCount: freezed == visitCount
            ? _value.visitCount
            : visitCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        contributionCount: freezed == contributionCount
            ? _value.contributionCount
            : contributionCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        joinedAt: freezed == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastActive: freezed == lastActive
            ? _value.lastActive
            : lastActive // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$UserEntityImpl extends _UserEntity {
  const _$UserEntityImpl({
    required this.id,
    required this.email,
    required this.displayName,
    this.role,
    this.photoUrl,
    this.bio,
    this.phone,
    this.totalPoints,
    final List<String>? earnedBadges,
    this.visitCount,
    this.contributionCount,
    this.joinedAt,
    this.lastActive,
  }) : _earnedBadges = earnedBadges,
       super._();

  @override
  final String id;
  @override
  final String email;
  @override
  final String displayName;
  @override
  final UserRole? role;
  @override
  final String? photoUrl;
  @override
  final String? bio;
  @override
  final String? phone;
  @override
  final int? totalPoints;
  final List<String>? _earnedBadges;
  @override
  List<String>? get earnedBadges {
    final value = _earnedBadges;
    if (value == null) return null;
    if (_earnedBadges is EqualUnmodifiableListView) return _earnedBadges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? visitCount;
  @override
  final int? contributionCount;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? lastActive;

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName, role: $role, photoUrl: $photoUrl, bio: $bio, phone: $phone, totalPoints: $totalPoints, earnedBadges: $earnedBadges, visitCount: $visitCount, contributionCount: $contributionCount, joinedAt: $joinedAt, lastActive: $lastActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            const DeepCollectionEquality().equals(
              other._earnedBadges,
              _earnedBadges,
            ) &&
            (identical(other.visitCount, visitCount) ||
                other.visitCount == visitCount) &&
            (identical(other.contributionCount, contributionCount) ||
                other.contributionCount == contributionCount) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.lastActive, lastActive) ||
                other.lastActive == lastActive));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    displayName,
    role,
    photoUrl,
    bio,
    phone,
    totalPoints,
    const DeepCollectionEquality().hash(_earnedBadges),
    visitCount,
    contributionCount,
    joinedAt,
    lastActive,
  );

  /// Create a copy of UserEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      __$$UserEntityImplCopyWithImpl<_$UserEntityImpl>(this, _$identity);
}

abstract class _UserEntity extends UserEntity {
  const factory _UserEntity({
    required final String id,
    required final String email,
    required final String displayName,
    final UserRole? role,
    final String? photoUrl,
    final String? bio,
    final String? phone,
    final int? totalPoints,
    final List<String>? earnedBadges,
    final int? visitCount,
    final int? contributionCount,
    final DateTime? joinedAt,
    final DateTime? lastActive,
  }) = _$UserEntityImpl;
  const _UserEntity._() : super._();

  @override
  String get id;
  @override
  String get email;
  @override
  String get displayName;
  @override
  UserRole? get role;
  @override
  String? get photoUrl;
  @override
  String? get bio;
  @override
  String? get phone;
  @override
  int? get totalPoints;
  @override
  List<String>? get earnedBadges;
  @override
  int? get visitCount;
  @override
  int? get contributionCount;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get lastActive;

  /// Create a copy of UserEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
