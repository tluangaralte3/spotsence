// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spot_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SpotEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  SpotCategory get category => throw _privateConstructorUsedError;
  String get locationAddress => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  List<String> get imagesUrl => throw _privateConstructorUsedError;
  String? get placeStory => throw _privateConstructorUsedError;
  double? get averageRating => throw _privateConstructorUsedError;
  int? get popularity => throw _privateConstructorUsedError;
  bool get featured => throw _privateConstructorUsedError;
  ApprovalStatus get status => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  String? get contributorId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get approvedAt => throw _privateConstructorUsedError;
  int? get visitCount => throw _privateConstructorUsedError;
  int? get reviewCount => throw _privateConstructorUsedError;

  /// Create a copy of SpotEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpotEntityCopyWith<SpotEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpotEntityCopyWith<$Res> {
  factory $SpotEntityCopyWith(
    SpotEntity value,
    $Res Function(SpotEntity) then,
  ) = _$SpotEntityCopyWithImpl<$Res, SpotEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    SpotCategory category,
    String locationAddress,
    double latitude,
    double longitude,
    List<String> imagesUrl,
    String? placeStory,
    double? averageRating,
    int? popularity,
    bool featured,
    ApprovalStatus status,
    List<String>? tags,
    String? contributorId,
    DateTime? createdAt,
    DateTime? approvedAt,
    int? visitCount,
    int? reviewCount,
  });
}

/// @nodoc
class _$SpotEntityCopyWithImpl<$Res, $Val extends SpotEntity>
    implements $SpotEntityCopyWith<$Res> {
  _$SpotEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpotEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? locationAddress = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? imagesUrl = null,
    Object? placeStory = freezed,
    Object? averageRating = freezed,
    Object? popularity = freezed,
    Object? featured = null,
    Object? status = null,
    Object? tags = freezed,
    Object? contributorId = freezed,
    Object? createdAt = freezed,
    Object? approvedAt = freezed,
    Object? visitCount = freezed,
    Object? reviewCount = freezed,
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
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as SpotCategory,
            locationAddress: null == locationAddress
                ? _value.locationAddress
                : locationAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            imagesUrl: null == imagesUrl
                ? _value.imagesUrl
                : imagesUrl // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            placeStory: freezed == placeStory
                ? _value.placeStory
                : placeStory // ignore: cast_nullable_to_non_nullable
                      as String?,
            averageRating: freezed == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double?,
            popularity: freezed == popularity
                ? _value.popularity
                : popularity // ignore: cast_nullable_to_non_nullable
                      as int?,
            featured: null == featured
                ? _value.featured
                : featured // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ApprovalStatus,
            tags: freezed == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            contributorId: freezed == contributorId
                ? _value.contributorId
                : contributorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            approvedAt: freezed == approvedAt
                ? _value.approvedAt
                : approvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            visitCount: freezed == visitCount
                ? _value.visitCount
                : visitCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            reviewCount: freezed == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SpotEntityImplCopyWith<$Res>
    implements $SpotEntityCopyWith<$Res> {
  factory _$$SpotEntityImplCopyWith(
    _$SpotEntityImpl value,
    $Res Function(_$SpotEntityImpl) then,
  ) = __$$SpotEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    SpotCategory category,
    String locationAddress,
    double latitude,
    double longitude,
    List<String> imagesUrl,
    String? placeStory,
    double? averageRating,
    int? popularity,
    bool featured,
    ApprovalStatus status,
    List<String>? tags,
    String? contributorId,
    DateTime? createdAt,
    DateTime? approvedAt,
    int? visitCount,
    int? reviewCount,
  });
}

/// @nodoc
class __$$SpotEntityImplCopyWithImpl<$Res>
    extends _$SpotEntityCopyWithImpl<$Res, _$SpotEntityImpl>
    implements _$$SpotEntityImplCopyWith<$Res> {
  __$$SpotEntityImplCopyWithImpl(
    _$SpotEntityImpl _value,
    $Res Function(_$SpotEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SpotEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? locationAddress = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? imagesUrl = null,
    Object? placeStory = freezed,
    Object? averageRating = freezed,
    Object? popularity = freezed,
    Object? featured = null,
    Object? status = null,
    Object? tags = freezed,
    Object? contributorId = freezed,
    Object? createdAt = freezed,
    Object? approvedAt = freezed,
    Object? visitCount = freezed,
    Object? reviewCount = freezed,
  }) {
    return _then(
      _$SpotEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as SpotCategory,
        locationAddress: null == locationAddress
            ? _value.locationAddress
            : locationAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        imagesUrl: null == imagesUrl
            ? _value._imagesUrl
            : imagesUrl // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        placeStory: freezed == placeStory
            ? _value.placeStory
            : placeStory // ignore: cast_nullable_to_non_nullable
                  as String?,
        averageRating: freezed == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double?,
        popularity: freezed == popularity
            ? _value.popularity
            : popularity // ignore: cast_nullable_to_non_nullable
                  as int?,
        featured: null == featured
            ? _value.featured
            : featured // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ApprovalStatus,
        tags: freezed == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        contributorId: freezed == contributorId
            ? _value.contributorId
            : contributorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        approvedAt: freezed == approvedAt
            ? _value.approvedAt
            : approvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        visitCount: freezed == visitCount
            ? _value.visitCount
            : visitCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        reviewCount: freezed == reviewCount
            ? _value.reviewCount
            : reviewCount // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$SpotEntityImpl extends _SpotEntity {
  const _$SpotEntityImpl({
    required this.id,
    required this.name,
    required this.category,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required final List<String> imagesUrl,
    this.placeStory,
    this.averageRating,
    this.popularity,
    required this.featured,
    required this.status,
    final List<String>? tags,
    this.contributorId,
    this.createdAt,
    this.approvedAt,
    this.visitCount,
    this.reviewCount,
  }) : _imagesUrl = imagesUrl,
       _tags = tags,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final SpotCategory category;
  @override
  final String locationAddress;
  @override
  final double latitude;
  @override
  final double longitude;
  final List<String> _imagesUrl;
  @override
  List<String> get imagesUrl {
    if (_imagesUrl is EqualUnmodifiableListView) return _imagesUrl;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_imagesUrl);
  }

  @override
  final String? placeStory;
  @override
  final double? averageRating;
  @override
  final int? popularity;
  @override
  final bool featured;
  @override
  final ApprovalStatus status;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? contributorId;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? approvedAt;
  @override
  final int? visitCount;
  @override
  final int? reviewCount;

  @override
  String toString() {
    return 'SpotEntity(id: $id, name: $name, category: $category, locationAddress: $locationAddress, latitude: $latitude, longitude: $longitude, imagesUrl: $imagesUrl, placeStory: $placeStory, averageRating: $averageRating, popularity: $popularity, featured: $featured, status: $status, tags: $tags, contributorId: $contributorId, createdAt: $createdAt, approvedAt: $approvedAt, visitCount: $visitCount, reviewCount: $reviewCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpotEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.locationAddress, locationAddress) ||
                other.locationAddress == locationAddress) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            const DeepCollectionEquality().equals(
              other._imagesUrl,
              _imagesUrl,
            ) &&
            (identical(other.placeStory, placeStory) ||
                other.placeStory == placeStory) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.popularity, popularity) ||
                other.popularity == popularity) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.contributorId, contributorId) ||
                other.contributorId == contributorId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.visitCount, visitCount) ||
                other.visitCount == visitCount) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    category,
    locationAddress,
    latitude,
    longitude,
    const DeepCollectionEquality().hash(_imagesUrl),
    placeStory,
    averageRating,
    popularity,
    featured,
    status,
    const DeepCollectionEquality().hash(_tags),
    contributorId,
    createdAt,
    approvedAt,
    visitCount,
    reviewCount,
  );

  /// Create a copy of SpotEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpotEntityImplCopyWith<_$SpotEntityImpl> get copyWith =>
      __$$SpotEntityImplCopyWithImpl<_$SpotEntityImpl>(this, _$identity);
}

abstract class _SpotEntity extends SpotEntity {
  const factory _SpotEntity({
    required final String id,
    required final String name,
    required final SpotCategory category,
    required final String locationAddress,
    required final double latitude,
    required final double longitude,
    required final List<String> imagesUrl,
    final String? placeStory,
    final double? averageRating,
    final int? popularity,
    required final bool featured,
    required final ApprovalStatus status,
    final List<String>? tags,
    final String? contributorId,
    final DateTime? createdAt,
    final DateTime? approvedAt,
    final int? visitCount,
    final int? reviewCount,
  }) = _$SpotEntityImpl;
  const _SpotEntity._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  SpotCategory get category;
  @override
  String get locationAddress;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  List<String> get imagesUrl;
  @override
  String? get placeStory;
  @override
  double? get averageRating;
  @override
  int? get popularity;
  @override
  bool get featured;
  @override
  ApprovalStatus get status;
  @override
  List<String>? get tags;
  @override
  String? get contributorId;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get approvedAt;
  @override
  int? get visitCount;
  @override
  int? get reviewCount;

  /// Create a copy of SpotEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpotEntityImplCopyWith<_$SpotEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
