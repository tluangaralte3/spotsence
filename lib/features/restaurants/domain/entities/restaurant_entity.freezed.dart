// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RestaurantEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  PriceRange get priceRange => throw _privateConstructorUsedError;
  List<String> get cuisineTypes => throw _privateConstructorUsedError;
  String get openingHours => throw _privateConstructorUsedError;
  bool get hasDelivery => throw _privateConstructorUsedError;
  bool get hasReservation => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  List<String>? get amenities => throw _privateConstructorUsedError;
  int? get reviewCount => throw _privateConstructorUsedError;
  bool? get isFeatured => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantEntityCopyWith<RestaurantEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantEntityCopyWith<$Res> {
  factory $RestaurantEntityCopyWith(
    RestaurantEntity value,
    $Res Function(RestaurantEntity) then,
  ) = _$RestaurantEntityCopyWithImpl<$Res, RestaurantEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String location,
    double latitude,
    double longitude,
    List<String> images,
    double rating,
    PriceRange priceRange,
    List<String> cuisineTypes,
    String openingHours,
    bool hasDelivery,
    bool hasReservation,
    String? phone,
    String? email,
    String? website,
    List<String>? amenities,
    int? reviewCount,
    bool? isFeatured,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$RestaurantEntityCopyWithImpl<$Res, $Val extends RestaurantEntity>
    implements $RestaurantEntityCopyWith<$Res> {
  _$RestaurantEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? images = null,
    Object? rating = null,
    Object? priceRange = null,
    Object? cuisineTypes = null,
    Object? openingHours = null,
    Object? hasDelivery = null,
    Object? hasReservation = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? website = freezed,
    Object? amenities = freezed,
    Object? reviewCount = freezed,
    Object? isFeatured = freezed,
    Object? createdAt = freezed,
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
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            priceRange: null == priceRange
                ? _value.priceRange
                : priceRange // ignore: cast_nullable_to_non_nullable
                      as PriceRange,
            cuisineTypes: null == cuisineTypes
                ? _value.cuisineTypes
                : cuisineTypes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            openingHours: null == openingHours
                ? _value.openingHours
                : openingHours // ignore: cast_nullable_to_non_nullable
                      as String,
            hasDelivery: null == hasDelivery
                ? _value.hasDelivery
                : hasDelivery // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasReservation: null == hasReservation
                ? _value.hasReservation
                : hasReservation // ignore: cast_nullable_to_non_nullable
                      as bool,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            amenities: freezed == amenities
                ? _value.amenities
                : amenities // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            reviewCount: freezed == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            isFeatured: freezed == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RestaurantEntityImplCopyWith<$Res>
    implements $RestaurantEntityCopyWith<$Res> {
  factory _$$RestaurantEntityImplCopyWith(
    _$RestaurantEntityImpl value,
    $Res Function(_$RestaurantEntityImpl) then,
  ) = __$$RestaurantEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    String location,
    double latitude,
    double longitude,
    List<String> images,
    double rating,
    PriceRange priceRange,
    List<String> cuisineTypes,
    String openingHours,
    bool hasDelivery,
    bool hasReservation,
    String? phone,
    String? email,
    String? website,
    List<String>? amenities,
    int? reviewCount,
    bool? isFeatured,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$RestaurantEntityImplCopyWithImpl<$Res>
    extends _$RestaurantEntityCopyWithImpl<$Res, _$RestaurantEntityImpl>
    implements _$$RestaurantEntityImplCopyWith<$Res> {
  __$$RestaurantEntityImplCopyWithImpl(
    _$RestaurantEntityImpl _value,
    $Res Function(_$RestaurantEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? location = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? images = null,
    Object? rating = null,
    Object? priceRange = null,
    Object? cuisineTypes = null,
    Object? openingHours = null,
    Object? hasDelivery = null,
    Object? hasReservation = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? website = freezed,
    Object? amenities = freezed,
    Object? reviewCount = freezed,
    Object? isFeatured = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$RestaurantEntityImpl(
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
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        priceRange: null == priceRange
            ? _value.priceRange
            : priceRange // ignore: cast_nullable_to_non_nullable
                  as PriceRange,
        cuisineTypes: null == cuisineTypes
            ? _value._cuisineTypes
            : cuisineTypes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        openingHours: null == openingHours
            ? _value.openingHours
            : openingHours // ignore: cast_nullable_to_non_nullable
                  as String,
        hasDelivery: null == hasDelivery
            ? _value.hasDelivery
            : hasDelivery // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasReservation: null == hasReservation
            ? _value.hasReservation
            : hasReservation // ignore: cast_nullable_to_non_nullable
                  as bool,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        amenities: freezed == amenities
            ? _value._amenities
            : amenities // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        reviewCount: freezed == reviewCount
            ? _value.reviewCount
            : reviewCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        isFeatured: freezed == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$RestaurantEntityImpl extends _RestaurantEntity {
  const _$RestaurantEntityImpl({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required final List<String> images,
    required this.rating,
    required this.priceRange,
    required final List<String> cuisineTypes,
    required this.openingHours,
    required this.hasDelivery,
    required this.hasReservation,
    this.phone,
    this.email,
    this.website,
    final List<String>? amenities,
    this.reviewCount,
    this.isFeatured,
    this.createdAt,
  }) : _images = images,
       _cuisineTypes = cuisineTypes,
       _amenities = amenities,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String location;
  @override
  final double latitude;
  @override
  final double longitude;
  final List<String> _images;
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final double rating;
  @override
  final PriceRange priceRange;
  final List<String> _cuisineTypes;
  @override
  List<String> get cuisineTypes {
    if (_cuisineTypes is EqualUnmodifiableListView) return _cuisineTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cuisineTypes);
  }

  @override
  final String openingHours;
  @override
  final bool hasDelivery;
  @override
  final bool hasReservation;
  @override
  final String? phone;
  @override
  final String? email;
  @override
  final String? website;
  final List<String>? _amenities;
  @override
  List<String>? get amenities {
    final value = _amenities;
    if (value == null) return null;
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? reviewCount;
  @override
  final bool? isFeatured;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RestaurantEntity(id: $id, name: $name, description: $description, location: $location, latitude: $latitude, longitude: $longitude, images: $images, rating: $rating, priceRange: $priceRange, cuisineTypes: $cuisineTypes, openingHours: $openingHours, hasDelivery: $hasDelivery, hasReservation: $hasReservation, phone: $phone, email: $email, website: $website, amenities: $amenities, reviewCount: $reviewCount, isFeatured: $isFeatured, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.priceRange, priceRange) ||
                other.priceRange == priceRange) &&
            const DeepCollectionEquality().equals(
              other._cuisineTypes,
              _cuisineTypes,
            ) &&
            (identical(other.openingHours, openingHours) ||
                other.openingHours == openingHours) &&
            (identical(other.hasDelivery, hasDelivery) ||
                other.hasDelivery == hasDelivery) &&
            (identical(other.hasReservation, hasReservation) ||
                other.hasReservation == hasReservation) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.website, website) || other.website == website) &&
            const DeepCollectionEquality().equals(
              other._amenities,
              _amenities,
            ) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    description,
    location,
    latitude,
    longitude,
    const DeepCollectionEquality().hash(_images),
    rating,
    priceRange,
    const DeepCollectionEquality().hash(_cuisineTypes),
    openingHours,
    hasDelivery,
    hasReservation,
    phone,
    email,
    website,
    const DeepCollectionEquality().hash(_amenities),
    reviewCount,
    isFeatured,
    createdAt,
  ]);

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantEntityImplCopyWith<_$RestaurantEntityImpl> get copyWith =>
      __$$RestaurantEntityImplCopyWithImpl<_$RestaurantEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _RestaurantEntity extends RestaurantEntity {
  const factory _RestaurantEntity({
    required final String id,
    required final String name,
    required final String description,
    required final String location,
    required final double latitude,
    required final double longitude,
    required final List<String> images,
    required final double rating,
    required final PriceRange priceRange,
    required final List<String> cuisineTypes,
    required final String openingHours,
    required final bool hasDelivery,
    required final bool hasReservation,
    final String? phone,
    final String? email,
    final String? website,
    final List<String>? amenities,
    final int? reviewCount,
    final bool? isFeatured,
    final DateTime? createdAt,
  }) = _$RestaurantEntityImpl;
  const _RestaurantEntity._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get location;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  List<String> get images;
  @override
  double get rating;
  @override
  PriceRange get priceRange;
  @override
  List<String> get cuisineTypes;
  @override
  String get openingHours;
  @override
  bool get hasDelivery;
  @override
  bool get hasReservation;
  @override
  String? get phone;
  @override
  String? get email;
  @override
  String? get website;
  @override
  List<String>? get amenities;
  @override
  int? get reviewCount;
  @override
  bool? get isFeatured;
  @override
  DateTime? get createdAt;

  /// Create a copy of RestaurantEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantEntityImplCopyWith<_$RestaurantEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
