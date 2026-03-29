// lib/screens/admin/listings/admin_add_listing_screen.dart
//
// Universal "Add / Edit" form for any listing collection.
// Route params: collection (required), docId (optional — for edit mode).

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/listing_models.dart';

class AdminAddListingScreen extends ConsumerStatefulWidget {
  final String collection;
  final String? docId; // null = create, non-null = edit

  const AdminAddListingScreen({
    super.key,
    required this.collection,
    this.docId,
  });

  @override
  ConsumerState<AdminAddListingScreen> createState() =>
      _AdminAddListingScreenState();
}

class _AdminAddListingScreenState extends ConsumerState<AdminAddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  // Image state
  final List<XFile> _newImages = []; // picked from device, not yet uploaded
  final List<String> _existingImageUrls =
      []; // already-uploaded URLs (edit mode)
  bool _uploadingImages = false;

  // Extra fields
  final _extraControllers = <String, TextEditingController>{};

  // Date/time picker state for events
  DateTime? _startDate;
  DateTime? _endDate;

  // Events-specific extra state
  final _timeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();
  final _maxAttendeesCtrl = TextEditingController();
  final _ticketPriceCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _categoryTextCtrl = TextEditingController();
  final _districtTextCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _registrationUrlCtrl = TextEditingController();
  String _eventType = 'cultural';
  String _eventStatus = 'Published';
  bool _eventFeatured = false;

  static const _eventTypes = [
    'festival',
    'cultural',
    'adventure',
    'personal',
    'sports',
    'music',
    'food',
  ];
  static const _eventStatuses = ['Published', 'Draft'];

  bool _isLoading = false;
  bool _isEditMode = false;

  bool get _isEvents => widget.collection == 'events';
  bool get _isSpots => widget.collection == 'spots';
  bool get _isRestaurants => widget.collection == 'restaurants';
  bool get _isAccommodations =>
      widget.collection == 'accommodations' || widget.collection == 'homestays';
  bool get _isShopping => widget.collection == 'shoppingAreas';
  bool get _isCafe => widget.collection == 'cafes';

  // ── Cafe-specific fields ─────────────────────────────────────────────────
  final _phoneCafeCtrl = TextEditingController();
  final _openingHoursCafeCtrl = TextEditingController();
  final _specialtiesCafeCtrl = TextEditingController(); // comma-separated
  final _latCafeCtrl = TextEditingController();
  final _lngCafeCtrl = TextEditingController();
  bool _cafeHasParking = false;
  bool _cafeHasWifi = false;
  bool _cafeIsSundayOpen = false;
  bool _cafeIsVerified = false;
  String _cafePriceRange = 'Low';
  // Cafe logo (imageUrl) — separate from menu images (images array)
  String? _cafeExistingLogoUrl;
  XFile? _newCafeLogoImage;
  bool _uploadingCafeLogo = false;

  // ── Shopping-specific fields ─────────────────────────────────────────────
  final _phoneShopCtrl = TextEditingController();
  final _openingHoursShopCtrl = TextEditingController();
  final _productsShopCtrl = TextEditingController(); // comma-separated
  final _specialtiesShopCtrl = TextEditingController(); // comma-separated
  final _latShopCtrl = TextEditingController();
  final _lngShopCtrl = TextEditingController();
  final _districtShopCtrl = TextEditingController();
  bool _shopHasDelivery = false;
  bool _shopHasParking = false;
  bool _shopAcceptsCards = false;
  bool _shopIsVerified = false;
  bool _shopIsPopular = false;
  String _shopType = 'Mall';
  String _shopPriceRange = 'Medium';
  static const _shopTypes = [
    'Mall',
    'Market',
    'Store',
    'Boutique',
    'Supermarket',
    'Other',
  ];

  // ── Accommodations-specific fields ──────────────────────────────────────
  final _phoneAccCtrl = TextEditingController();
  final _pricePerNightCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _capacityAccCtrl = TextEditingController();
  final _amenitiesAccCtrl = TextEditingController(); // comma-separated
  final _latAccCtrl = TextEditingController();
  final _lngAccCtrl = TextEditingController();
  final _districtAccCtrl = TextEditingController();
  bool _accHasBreakfast = false;
  bool _accHasParking = false;
  bool _accHasWifi = false;
  bool _accIsVerified = false;
  String _accType = 'Homestay';
  static const _accTypes = [
    'Homestay',
    'Hotel',
    'Guesthouse',
    'Resort',
    'Lodge',
    'Other',
  ];

  // ── Restaurants-specific fields ─────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _openingHoursRestCtrl = TextEditingController();
  final _priceRangeCtrl = TextEditingController();
  final _cuisineTypesCtrl = TextEditingController(); // comma-separated
  final _specialtiesCtrl = TextEditingController(); // comma-separated
  final _capacityCtrl = TextEditingController();
  final _latRestCtrl = TextEditingController();
  final _lngRestCtrl = TextEditingController();
  final _districtRestCtrl = TextEditingController();
  bool _hasDelivery = false;
  bool _hasParking = false;
  bool _hasReservation = false;
  bool _isVerified = false;
  String _priceRange = 'Low';
  static const _priceRanges = ['Low', 'Medium', 'High'];

  // ── Spots-specific fields ───────────────────────────────────────────────
  final _locationAddressCtrl = TextEditingController();
  final _districtSpotCtrl = TextEditingController();
  final _categorySpotCtrl = TextEditingController();
  final _placeStoryCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _bestSeasonCtrl = TextEditingController();
  final _openingHoursSpotCtrl = TextEditingController();
  final _facilitiesCtrl = TextEditingController();
  final _accessibilityCtrl = TextEditingController();
  final _safetyNotesCtrl = TextEditingController();
  final _officialSourceUrlCtrl = TextEditingController();
  final _alternateNamesCtrl = TextEditingController();
  final _thingsToDoCtrl = TextEditingController();
  final _addOnsCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _popularityCtrl = TextEditingController();
  // entryFees: list of {type, amount} pairs
  final List<Map<String, TextEditingController>> _entryFees = [];
  String _spotStatus = 'Approved';
  bool _spotFeatured = false;
  bool _spotIsRateable = true;

  static const _spotStatuses = ['Approved', 'Pending', 'Rejected'];
  static const _spotCategories = [
    'cultural-site',
    'nature',
    'viewpoint',
    'waterfall',
    'cave',
    'historical',
    'religious',
    'adventure',
    'wildlife',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.docId != null;
    if (_isEditMode) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.docId)
          .get();
      if (snap.exists) {
        final d = snap.data()!;

        if (_isEvents) {
          // Events use 'title' instead of 'name'
          _nameCtrl.text =
              d['title']?.toString() ?? d['name']?.toString() ?? '';
        } else {
          _nameCtrl.text = d['name']?.toString() ?? '';
        }
        _descCtrl.text = d['description']?.toString() ?? '';
        _locationCtrl.text =
            d['location']?.toString() ??
            d['address']?.toString() ??
            d['venue']?.toString() ??
            '';
        _tagsCtrl.text = (d['tags'] as List?)?.join(', ') ?? '';

        // Load existing images
        if (_isEvents) {
          // Events may store a single imageUrl OR a list in 'images'
          final imgList = d['images'];
          if (imgList is List) {
            _existingImageUrls.addAll(
              imgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          } else {
            final single =
                d['imageUrl']?.toString() ?? d['image']?.toString() ?? '';
            if (single.isNotEmpty) _existingImageUrls.add(single);
          }
          // Events-specific fields
          _timeCtrl.text =
              d['time']?.toString() ?? d['startTime']?.toString() ?? '';
          _endTimeCtrl.text = d['endTime']?.toString() ?? '';
          _attendeesCtrl.text =
              (d['attendees'] ?? d['attendeeCount'])?.toString() ?? '';
          _maxAttendeesCtrl.text = d['maxAttendees']?.toString() ?? '';
          _ticketPriceCtrl.text = d['ticketPrice']?.toString() ?? '';
          _organizerCtrl.text = d['organizer']?.toString() ?? '';
          _categoryTextCtrl.text = d['category']?.toString() ?? '';
          _districtTextCtrl.text = d['district']?.toString() ?? '';
          _contactEmailCtrl.text = d['contactEmail']?.toString() ?? '';
          _contactPhoneCtrl.text = d['contactPhone']?.toString() ?? '';
          _registrationUrlCtrl.text = d['registrationUrl']?.toString() ?? '';
          _eventFeatured = d['featured'] == true;
          if (_eventTypes.contains(d['type'])) _eventType = d['type']!;
          if (_eventStatuses.contains(d['status'])) _eventStatus = d['status']!;
          // Parse start/end dates
          for (final key in ['startDate', 'endDate', 'date', 'eventDate']) {
            final raw = d[key];
            DateTime? parsed;
            if (raw is Timestamp) {
              parsed = raw.toDate();
            } else if (raw is String && raw.isNotEmpty) {
              parsed = DateTime.tryParse(raw);
            }
            if (parsed != null && _startDate == null) _startDate = parsed;
          }
          final rawEnd = d['endDate'];
          if (rawEnd is Timestamp)
            _endDate = rawEnd.toDate();
          else if (rawEnd is String && rawEnd.isNotEmpty)
            _endDate = DateTime.tryParse(rawEnd);
        } else if (_isAccommodations) {
          // accommodations fields
          _phoneAccCtrl.text =
              d['phone']?.toString() ?? d['contactPhone']?.toString() ?? '';
          _pricePerNightCtrl.text = d['pricePerNight']?.toString() ?? '';
          _roomsCtrl.text = d['rooms']?.toString() ?? '';
          _capacityAccCtrl.text = d['capacity']?.toString() ?? '';
          _districtAccCtrl.text = d['district']?.toString() ?? '';
          _latAccCtrl.text = d['latitude']?.toString() ?? '';
          _lngAccCtrl.text = d['longitude']?.toString() ?? '';
          _accHasBreakfast = d['hasBreakfast'] == true;
          _accHasParking = d['hasParking'] == true;
          _accHasWifi = d['hasWifi'] == true;
          _accIsVerified = d['isVerified'] == true;
          final at = d['type']?.toString() ?? 'Homestay';
          _accType = _accTypes.contains(at) ? at : 'Homestay';
          // amenities: List or comma-separated string
          final rawAmen = d['amenities'];
          if (rawAmen is List) {
            _amenitiesAccCtrl.text = rawAmen.join(', ');
          } else if (rawAmen is String) {
            _amenitiesAccCtrl.text = rawAmen;
          }
          // images
          final imgList = d['images'];
          if (imgList is List) {
            _existingImageUrls.addAll(
              imgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
        } else if (_isRestaurants) {
          // Restaurants fields
          _phoneCtrl.text =
              d['phone']?.toString() ?? d['contactPhone']?.toString() ?? '';
          _openingHoursRestCtrl.text = d['openingHours']?.toString() ?? '';
          _districtRestCtrl.text = d['district']?.toString() ?? '';
          _capacityCtrl.text = d['capacity']?.toString() ?? '';
          _latRestCtrl.text = d['latitude']?.toString() ?? '';
          _lngRestCtrl.text = d['longitude']?.toString() ?? '';
          _hasDelivery = d['hasDelivery'] == true;
          _hasParking = d['hasParking'] == true;
          _hasReservation = d['hasReservation'] == true;
          _isVerified = d['isVerified'] == true;
          // priceRange
          final pr = d['priceRange']?.toString() ?? 'Low';
          _priceRange = _priceRanges.contains(pr) ? pr : 'Low';
          _priceRangeCtrl.text = pr;
          // cuisineTypes: List or comma-separated string
          final rawCuisine = d['cuisineTypes'] ?? d['cuisine'];
          if (rawCuisine is List) {
            _cuisineTypesCtrl.text = rawCuisine.join(', ');
          } else if (rawCuisine is String) {
            _cuisineTypesCtrl.text = rawCuisine;
          }
          // specialties: List or string
          final rawSpec = d['specialties'];
          if (rawSpec is List) {
            _specialtiesCtrl.text = rawSpec.join(', ');
          } else if (rawSpec is String) {
            _specialtiesCtrl.text = rawSpec;
          }
          // images
          final imgList = d['images'];
          if (imgList is List) {
            _existingImageUrls.addAll(
              imgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
        } else if (_isSpots) {
          // Spots use 'locationAddress', 'imagesUrl'
          _locationAddressCtrl.text = d['locationAddress']?.toString() ?? '';
          _districtSpotCtrl.text = d['district']?.toString() ?? '';
          _categorySpotCtrl.text = d['category']?.toString() ?? '';
          _placeStoryCtrl.text = d['placeStory']?.toString() ?? '';
          _distanceCtrl.text = d['distance']?.toString() ?? '';
          _bestSeasonCtrl.text = d['bestSeason']?.toString() ?? '';
          _openingHoursSpotCtrl.text = d['openingHours']?.toString() ?? '';
          _facilitiesCtrl.text = d['facilities']?.toString() ?? '';
          _accessibilityCtrl.text = d['accessibility']?.toString() ?? '';
          _safetyNotesCtrl.text = d['safetyNotes']?.toString() ?? '';
          _officialSourceUrlCtrl.text =
              d['officialSourceUrl']?.toString() ?? '';
          _latCtrl.text = d['latitude']?.toString() ?? '';
          _lngCtrl.text = d['longitude']?.toString() ?? '';
          _popularityCtrl.text = d['popularity']?.toString() ?? '';
          _spotFeatured = d['featured'] == true;
          _spotIsRateable = d['isRateable'] != false;
          if (_spotStatuses.contains(d['status'])) _spotStatus = d['status']!;
          // alternateNames: List or comma-separated string
          final rawAlt = d['alternateNames'];
          if (rawAlt is List) {
            _alternateNamesCtrl.text = rawAlt.join(', ');
          } else if (rawAlt is String) {
            _alternateNamesCtrl.text = rawAlt;
          }
          // thingsToDo
          final rawTodo = d['thingsToDo'];
          if (rawTodo is List) _thingsToDoCtrl.text = rawTodo.join('\n');
          // addOns
          final rawAddOns = d['addOns'];
          if (rawAddOns is List) _addOnsCtrl.text = rawAddOns.join('\n');
          // entryFees
          final rawFees = d['entryFees'];
          if (rawFees is List) {
            for (final fee in rawFees) {
              if (fee is Map) {
                _entryFees.add({
                  'type': TextEditingController(
                    text: fee['type']?.toString() ?? '',
                  ),
                  'amount': TextEditingController(
                    text: fee['amount']?.toString() ?? '',
                  ),
                });
              }
            }
          }
          // images
          final imgList = d['imagesUrl'];
          if (imgList is List) {
            _existingImageUrls.addAll(
              imgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
        } else if (_isCafe) {
          // Cafe fields
          _phoneCafeCtrl.text = d['phone']?.toString() ?? '';
          _openingHoursCafeCtrl.text = d['openingHours']?.toString() ?? '';
          _latCafeCtrl.text = d['latitude']?.toString() ?? '';
          _lngCafeCtrl.text = d['longitude']?.toString() ?? '';
          _cafeHasParking = d['hasParking'] == true;
          _cafeHasWifi = d['hasWifi'] == true;
          _cafeIsSundayOpen = d['isSundayOpen'] == true;
          _cafeIsVerified = d['isVerified'] == true;
          final pr = d['priceRange']?.toString() ?? 'Low';
          _cafePriceRange =
              const ['Low', 'Medium', 'High'].contains(pr) ? pr : 'Low';
          final rawSpec = d['specialties'];
          if (rawSpec is List) {
            _specialtiesCafeCtrl.text = rawSpec.join(', ');
          } else if (rawSpec is String) {
            _specialtiesCafeCtrl.text = rawSpec;
          }
          // Logo (imageUrl) — single string
          final logoUrl = d['imageUrl']?.toString() ?? '';
          if (logoUrl.isNotEmpty) _cafeExistingLogoUrl = logoUrl;
          // Menu images (images) — array
          final cafeImgList = d['images'];
          if (cafeImgList is List) {
            _existingImageUrls.addAll(
              cafeImgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
        } else if (_isShopping) {
          // Shopping fields
          _phoneShopCtrl.text = d['phone']?.toString() ?? '';
          _openingHoursShopCtrl.text = d['openingHours']?.toString() ?? '';
          _districtShopCtrl.text = d['district']?.toString() ?? '';
          _latShopCtrl.text = d['latitude']?.toString() ?? '';
          _lngShopCtrl.text = d['longitude']?.toString() ?? '';
          _shopHasDelivery = d['hasDelivery'] == true;
          _shopHasParking = d['hasParking'] == true;
          _shopAcceptsCards = d['acceptsCards'] == true;
          _shopIsVerified = d['isVerified'] == true;
          _shopIsPopular = d['isPopular'] == true;
          final st = d['type']?.toString() ?? 'Mall';
          _shopType = _shopTypes.contains(st) ? st : 'Mall';
          final pr = d['priceRange']?.toString() ?? 'Medium';
          _shopPriceRange = const ['Low', 'Medium', 'High'].contains(pr) ? pr : 'Medium';
          final rawProd = d['products'];
          if (rawProd is List) {
            _productsShopCtrl.text = rawProd.join(', ');
          } else if (rawProd is String) {
            _productsShopCtrl.text = rawProd;
          }
          final rawSpec = d['specialties'];
          if (rawSpec is List) {
            _specialtiesShopCtrl.text = rawSpec.join(', ');
          } else if (rawSpec is String) {
            _specialtiesShopCtrl.text = rawSpec;
          }
          final imgList = d['images'];
          if (imgList is List) {
            _existingImageUrls.addAll(
              imgList.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
        } else {
          // Other collections use 'images'
          final raw = d['images'];
          if (raw is List) {
            _existingImageUrls.addAll(
              raw.whereType<String>().where((u) => u.isNotEmpty),
            );
          }
          for (final key in _extraKeys) {
            if (key == 'startDate' || key == 'endDate') {
              final rawDate = d[key];
              DateTime? parsed;
              if (rawDate is Timestamp)
                parsed = rawDate.toDate();
              else if (rawDate is String && rawDate.isNotEmpty)
                parsed = DateTime.tryParse(rawDate);
              if (parsed != null) {
                if (key == 'startDate') _startDate = parsed;
                if (key == 'endDate') _endDate = parsed;
              }
              continue;
            }
            _extraControllers[key] ??= TextEditingController();
            _extraControllers[key]!.text = d[key]?.toString() ?? '';
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _extraKeys => switch (widget.collection) {
    'restaurants' => [], // dedicated form
    'accommodations' ||
    'homestays' => [], // dedicated form (Accommodations tab)
    'cafes' => [], // dedicated form
    'adventureSpots' => ['difficulty', 'duration', 'equipment'],
    'shoppingAreas' => [], // dedicated form
    'events' || 'spots' => [], // dedicated widgets
    'tour_packages' => ['duration', 'basePrice', 'difficulty', 'category'],
    _ => ['district', 'category'],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _tagsCtrl.dispose();
    _timeCtrl.dispose();
    _endTimeCtrl.dispose();
    _attendeesCtrl.dispose();
    _maxAttendeesCtrl.dispose();
    _ticketPriceCtrl.dispose();
    _organizerCtrl.dispose();
    _categoryTextCtrl.dispose();
    _districtTextCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _registrationUrlCtrl.dispose();
    // spots
    _locationAddressCtrl.dispose();
    _districtSpotCtrl.dispose();
    _categorySpotCtrl.dispose();
    _placeStoryCtrl.dispose();
    _distanceCtrl.dispose();
    _bestSeasonCtrl.dispose();
    _openingHoursSpotCtrl.dispose();
    _facilitiesCtrl.dispose();
    _accessibilityCtrl.dispose();
    _safetyNotesCtrl.dispose();
    _officialSourceUrlCtrl.dispose();
    _alternateNamesCtrl.dispose();
    _thingsToDoCtrl.dispose();
    _addOnsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _popularityCtrl.dispose();
    for (final fee in _entryFees) {
      fee['type']?.dispose();
      fee['amount']?.dispose();
    }
    // restaurants
    _phoneCtrl.dispose();
    _openingHoursRestCtrl.dispose();
    _priceRangeCtrl.dispose();
    _cuisineTypesCtrl.dispose();
    _specialtiesCtrl.dispose();
    _capacityCtrl.dispose();
    _latRestCtrl.dispose();
    _lngRestCtrl.dispose();
    _districtRestCtrl.dispose();
    // accommodations
    _phoneAccCtrl.dispose();
    _pricePerNightCtrl.dispose();
    _roomsCtrl.dispose();
    _capacityAccCtrl.dispose();
    _amenitiesAccCtrl.dispose();
    _latAccCtrl.dispose();
    _lngAccCtrl.dispose();
    _districtAccCtrl.dispose();
    // shopping
    _phoneShopCtrl.dispose();
    _openingHoursShopCtrl.dispose();
    _productsShopCtrl.dispose();
    _specialtiesShopCtrl.dispose();
    _latShopCtrl.dispose();
    _lngShopCtrl.dispose();
    _districtShopCtrl.dispose();
    // cafe
    _phoneCafeCtrl.dispose();
    _openingHoursCafeCtrl.dispose();
    _specialtiesCafeCtrl.dispose();
    _latCafeCtrl.dispose();
    _lngCafeCtrl.dispose();
    for (final c in _extraControllers.values) c.dispose();
    super.dispose();
  }

  /// Picks a single logo image for cafes.
  Future<void> _pickCafeLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() => _newCafeLogoImage = picked);
  }

  /// Picks one or more images from the gallery.
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked));
  }

  /// Uploads all pending [_newImages] to Firebase Storage and returns their URLs.
  /// Uses [XFile.readAsBytes] instead of [File] to avoid iOS sandbox
  /// restrictions on image_picker temporary paths (error -1017).
  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];
    setState(() => _uploadingImages = true);
    final urls = <String>[];
    try {
      final bucket = widget.collection;
      for (final xFile in _newImages) {
        // Normalise extension — HEIC/HEIF from iOS camera → jpeg
        final rawExt = xFile.path.split('.').last.toLowerCase();
        final ext = (rawExt == 'heic' || rawExt == 'heif') ? 'jpg' : rawExt;
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final name =
            '${bucket}_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$ext';
        final storageRef = FirebaseStorage.instance.ref().child(
          'admin_listings/$bucket/$name',
        );

        // Read bytes — avoids iOS -1017 sandbox path issue with putFile
        final bytes = await xFile.readAsBytes();
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: mimeType),
        );
        urls.add(await storageRef.getDownloadURL());
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return [];
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
    return urls;
  }

  /// Uploads the cafe logo image and returns its download URL, or returns
  /// the existing logo URL if no new image was picked.
  Future<String> _uploadCafeLogo() async {
    if (_newCafeLogoImage == null) return _cafeExistingLogoUrl ?? '';
    setState(() => _uploadingCafeLogo = true);
    try {
      final xFile = _newCafeLogoImage!;
      final rawExt = xFile.path.split('.').last.toLowerCase();
      final ext = (rawExt == 'heic' || rawExt == 'heif') ? 'jpg' : rawExt;
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final name = 'cafes_logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storageRef = FirebaseStorage.instance.ref().child(
        'admin_listings/cafes/$name',
      );
      final bytes = await xFile.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      );
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Logo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return _cafeExistingLogoUrl ?? '';
    } finally {
      if (mounted) setState(() => _uploadingCafeLogo = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload newly picked images
    final newUrls = await _uploadNewImages();
    final allImages = [..._existingImageUrls, ...newUrls];

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    Map<String, dynamic> data;

    if (_isEvents) {
      // Events schema: title, description, location, date, time, endDate,
      // endTime, attendees, maxAttendees, category, type, status,
      // imageUrl (required), featured, organizer, contactEmail,
      // contactPhone, ticketPrice, registrationUrl, tags, createdAt, updatedAt
      data = <String, dynamic>{
        'title': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(), // keep for listings screen queries
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'imageUrl': allImages.isNotEmpty ? allImages.first : '',
        'images': allImages,
        'tags': tags,
        'type': _eventType,
        'status': _eventStatus,
        'featured': _eventFeatured,
        'attendees': int.tryParse(_attendeesCtrl.text.trim()) ?? 0,
        'category': _categoryTextCtrl.text.trim(),
        if (_districtTextCtrl.text.trim().isNotEmpty)
          'district': _districtTextCtrl.text.trim(),
        if (_timeCtrl.text.trim().isNotEmpty) 'time': _timeCtrl.text.trim(),
        if (_endTimeCtrl.text.trim().isNotEmpty)
          'endTime': _endTimeCtrl.text.trim(),
        if (_maxAttendeesCtrl.text.trim().isNotEmpty)
          'maxAttendees': int.tryParse(_maxAttendeesCtrl.text.trim()) ?? 0,
        if (_ticketPriceCtrl.text.trim().isNotEmpty)
          'ticketPrice': _ticketPriceCtrl.text.trim(),
        if (_organizerCtrl.text.trim().isNotEmpty)
          'organizer': _organizerCtrl.text.trim(),
        if (_contactEmailCtrl.text.trim().isNotEmpty)
          'contactEmail': _contactEmailCtrl.text.trim(),
        if (_contactPhoneCtrl.text.trim().isNotEmpty)
          'contactPhone': _contactPhoneCtrl.text.trim(),
        if (_registrationUrlCtrl.text.trim().isNotEmpty)
          'registrationUrl': _registrationUrlCtrl.text.trim(),
        if (_startDate != null) 'date': Timestamp.fromDate(_startDate!),
        if (_startDate != null) 'startDate': Timestamp.fromDate(_startDate!),
        if (_endDate != null) 'endDate': Timestamp.fromDate(_endDate!),
        if (!_isEditMode) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
    } else if (_isAccommodations) {
      // accommodations collection
      final amenitiesList = _amenitiesAccCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'address': _locationCtrl.text.trim(),
        'images': allImages,
        'tags': tags,
        'type': _accType,
        'amenities': amenitiesList,
        'hasBreakfast': _accHasBreakfast,
        'hasParking': _accHasParking,
        'hasWifi': _accHasWifi,
        'isVerified': _accIsVerified,
        if (_pricePerNightCtrl.text.trim().isNotEmpty)
          'pricePerNight':
              double.tryParse(_pricePerNightCtrl.text.trim()) ??
              _pricePerNightCtrl.text.trim(),
        if (_roomsCtrl.text.trim().isNotEmpty)
          'rooms': int.tryParse(_roomsCtrl.text.trim()) ?? 0,
        if (_capacityAccCtrl.text.trim().isNotEmpty)
          'capacity': int.tryParse(_capacityAccCtrl.text.trim()) ?? 0,
        if (_phoneAccCtrl.text.trim().isNotEmpty)
          'phone': _phoneAccCtrl.text.trim(),
        if (_districtAccCtrl.text.trim().isNotEmpty)
          'district': _districtAccCtrl.text.trim(),
        if (_latAccCtrl.text.trim().isNotEmpty)
          'latitude': double.tryParse(_latAccCtrl.text.trim()),
        if (_lngAccCtrl.text.trim().isNotEmpty)
          'longitude': double.tryParse(_lngAccCtrl.text.trim()),
        'rating': 0.0,
        'views': 0,
        'loves': 0,
        'bookmarks': 0,
        'shares': 0,
      };
    } else if (_isRestaurants) {
      // Restaurants
      final cuisineList = _cuisineTypesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final specialtiesList = _specialtiesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'address': _locationCtrl.text.trim(),
        'images': allImages,
        'tags': tags,
        'priceRange': _priceRange,
        'cuisineTypes': cuisineList,
        'hasDelivery': _hasDelivery,
        'hasParking': _hasParking,
        'hasReservation': _hasReservation,
        'isVerified': _isVerified,
        if (_openingHoursRestCtrl.text.trim().isNotEmpty)
          'openingHours': _openingHoursRestCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_districtRestCtrl.text.trim().isNotEmpty)
          'district': _districtRestCtrl.text.trim(),
        if (_capacityCtrl.text.trim().isNotEmpty)
          'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        if (specialtiesList.isNotEmpty) 'specialties': specialtiesList,
        if (_latRestCtrl.text.trim().isNotEmpty)
          'latitude': double.tryParse(_latRestCtrl.text.trim()),
        if (_lngRestCtrl.text.trim().isNotEmpty)
          'longitude': double.tryParse(_lngRestCtrl.text.trim()),
        'averageRating': 0.0,
        'ratingsCount': 0,
        'views': 0,
        'loves': 0,
        'bookmarks': 0,
        'shares': 0,
      };
    } else if (_isSpots) {
      // Spots use 'imagesUrl', 'locationAddress', district, etc.
      final altNames = _alternateNamesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final thingsToDo = _thingsToDoCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final addOns = _addOnsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final fees = _entryFees
          .map(
            (f) => {
              'type': f['type']!.text.trim(),
              'amount': f['amount']!.text.trim(),
            },
          )
          .where((f) => f['type']!.isNotEmpty || f['amount']!.isNotEmpty)
          .toList();
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'locationAddress': _locationAddressCtrl.text.trim().isNotEmpty
            ? _locationAddressCtrl.text.trim()
            : _locationCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'imagesUrl': allImages,
        'tags': tags,
        'district': _districtSpotCtrl.text.trim(),
        'category': _categorySpotCtrl.text.trim(),
        'status': _spotStatus,
        'featured': _spotFeatured,
        'isRateable': _spotIsRateable,
        if (_placeStoryCtrl.text.trim().isNotEmpty)
          'placeStory': _placeStoryCtrl.text.trim(),
        if (_distanceCtrl.text.trim().isNotEmpty)
          'distance': _distanceCtrl.text.trim(),
        if (_bestSeasonCtrl.text.trim().isNotEmpty)
          'bestSeason': _bestSeasonCtrl.text.trim(),
        if (_openingHoursSpotCtrl.text.trim().isNotEmpty)
          'openingHours': _openingHoursSpotCtrl.text.trim(),
        if (_facilitiesCtrl.text.trim().isNotEmpty)
          'facilities': _facilitiesCtrl.text.trim(),
        if (_accessibilityCtrl.text.trim().isNotEmpty)
          'accessibility': _accessibilityCtrl.text.trim(),
        if (_safetyNotesCtrl.text.trim().isNotEmpty)
          'safetyNotes': _safetyNotesCtrl.text.trim(),
        if (_officialSourceUrlCtrl.text.trim().isNotEmpty)
          'officialSourceUrl': _officialSourceUrlCtrl.text.trim(),
        if (altNames.isNotEmpty) 'alternateNames': altNames,
        if (thingsToDo.isNotEmpty) 'thingsToDo': thingsToDo,
        if (addOns.isNotEmpty) 'addOns': addOns,
        if (fees.isNotEmpty) 'entryFees': fees,
        if (_latCtrl.text.trim().isNotEmpty)
          'latitude': double.tryParse(_latCtrl.text.trim()),
        if (_lngCtrl.text.trim().isNotEmpty)
          'longitude': double.tryParse(_lngCtrl.text.trim()),
        if (_popularityCtrl.text.trim().isNotEmpty)
          'popularity': double.tryParse(_popularityCtrl.text.trim()) ?? 0.0,
        'views': 0,
        'averageRating': 0.0,
        'ratingsCount': 0,
      };
    } else if (_isCafe) {
      // Upload logo and menu images independently
      final cafeLogoUrl = await _uploadCafeLogo();
      final specialtiesList = _specialtiesCafeCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'address': _locationCtrl.text.trim(),
        'imageUrl': cafeLogoUrl, // cafe logo — single string
        'images': allImages,     // menu item photos — array
        'tags': tags,
        'priceRange': _cafePriceRange,
        'hasParking': _cafeHasParking,
        'hasWifi': _cafeHasWifi,
        'isSundayOpen': _cafeIsSundayOpen,
        'isVerified': _cafeIsVerified,
        if (specialtiesList.isNotEmpty) 'specialties': specialtiesList,
        if (_openingHoursCafeCtrl.text.trim().isNotEmpty)
          'openingHours': _openingHoursCafeCtrl.text.trim(),
        if (_phoneCafeCtrl.text.trim().isNotEmpty)
          'phone': _phoneCafeCtrl.text.trim(),
        if (_latCafeCtrl.text.trim().isNotEmpty)
          'latitude': double.tryParse(_latCafeCtrl.text.trim()),
        if (_lngCafeCtrl.text.trim().isNotEmpty)
          'longitude': double.tryParse(_lngCafeCtrl.text.trim()),
        'rating': 0,
        'views': 0,
        'loves': 0,
        'bookmarks': 0,
        'shares': 0,
        if (!_isEditMode) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
    } else if (_isShopping) {
      final productsList = _productsShopCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final specialtiesList = _specialtiesShopCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'address': _locationCtrl.text.trim(),
        'images': allImages,
        'tags': tags,
        'type': _shopType,
        'priceRange': _shopPriceRange,
        'hasDelivery': _shopHasDelivery,
        'hasParking': _shopHasParking,
        'acceptsCards': _shopAcceptsCards,
        'isVerified': _shopIsVerified,
        'isPopular': _shopIsPopular,
        if (productsList.isNotEmpty) 'products': productsList,
        if (specialtiesList.isNotEmpty) 'specialties': specialtiesList,
        if (_openingHoursShopCtrl.text.trim().isNotEmpty)
          'openingHours': _openingHoursShopCtrl.text.trim(),
        if (_phoneShopCtrl.text.trim().isNotEmpty)
          'phone': _phoneShopCtrl.text.trim(),
        if (_districtShopCtrl.text.trim().isNotEmpty)
          'district': _districtShopCtrl.text.trim(),
        if (_latShopCtrl.text.trim().isNotEmpty)
          'latitude': double.tryParse(_latShopCtrl.text.trim()),
        if (_lngShopCtrl.text.trim().isNotEmpty)
          'longitude': double.tryParse(_lngShopCtrl.text.trim()),
        'rating': 0,
        'views': 0,
        'loves': 0,
        'bookmarks': 0,
        'shares': 0,
        if (!_isEditMode) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
    } else {
      // Other collections use 'images'
      data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'images': allImages,
        'tags': tags,
        for (final k in _extraKeys) ...{
          if (k == 'startDate' && _startDate != null)
            'startDate': Timestamp.fromDate(_startDate!),
          if (k == 'endDate' && _endDate != null)
            'endDate': Timestamp.fromDate(_endDate!),
          if (k != 'startDate' &&
              k != 'endDate' &&
              (_extraControllers[k]?.text.trim() ?? '').isNotEmpty)
            k: _extraControllers[k]!.text.trim(),
        },
      };
    }

    bool ok;
    if (_isEditMode) {
      ok = await ref
          .read(adminListingNotifierProvider.notifier)
          .updateListing(widget.collection, widget.docId!, data);
    } else {
      ok = await ref
          .read(adminListingNotifierProvider.notifier)
          .createListing(widget.collection, data);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final title = _isEditMode
        ? 'Edit ${_collectionLabel()}'
        : 'Add ${_collectionLabel()}';

    // Initialise extra controllers on first build
    for (final key in _extraKeys) {
      _extraControllers.putIfAbsent(key, TextEditingController.new);
    }

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        leading: BackButton(color: col.textPrimary),
        title: Text(
          title,
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                _isEditMode ? 'Update' : 'Create',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && _isEditMode
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Basic info card ──────────────────────────────────────
                  _FieldCard(
                    children: [
                      _FieldLabel(_isEvents ? 'Event Title *' : 'Name *'),
                      _TextField(
                        controller: _nameCtrl,
                        hint: _isEvents
                            ? 'e.g. Chapchar Kut Festival'
                            : 'e.g. Blue Mountain Homestay',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Description'),
                      _TextField(
                        controller: _descCtrl,
                        hint: 'Describe this listing…',
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Location & images card ───────────────────────────────
                  _FieldCard(
                    children: [
                      _FieldLabel(
                        _isEvents
                            ? 'Venue / Location'
                            : _isSpots
                            ? 'Location (short)'
                            : 'Location / Address',
                      ),
                      _TextField(
                        controller: _locationCtrl,
                        hint: 'e.g. Aizawl, Mizoram',
                      ),
                      if (_isSpots) ...[
                        const SizedBox(height: 12),
                        _FieldLabel('Full Address'),
                        _TextField(
                          controller: _locationAddressCtrl,
                          hint: 'e.g. Tlabung, Lunglei, Mizoram',
                        ),
                      ],
                      const SizedBox(height: 16),
                      _FieldLabel(_isCafe ? 'Menu Item Photos' : 'Photos / Images'),
                      _ImagePickerField(
                        existingUrls: _existingImageUrls,
                        newImages: _newImages,
                        uploading: _uploadingImages,
                        onPick: _pickImages,
                        onRemoveExisting: (i) =>
                            setState(() => _existingImageUrls.removeAt(i)),
                        onRemoveNew: (i) =>
                            setState(() => _newImages.removeAt(i)),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Tags (comma-separated)'),
                      _TextField(
                        controller: _tagsCtrl,
                        hint: 'e.g. festival, cultural, family',
                      ),
                    ],
                  ),

                  // ── Events-specific card ────────────────────────────────
                  if (_isEvents) ...[
                    const SizedBox(height: 16),
                    _FieldCard(
                      children: [
                        _FieldLabel('Event Details'),
                        const SizedBox(height: 8),

                        // Type dropdown
                        _FieldLabel('Event Type *'),
                        _DropdownField<String>(
                          value: _eventType,
                          items: _eventTypes,
                          label: (v) =>
                              '${EventModel.typeEmoji(v)}  ${v[0].toUpperCase()}${v.substring(1)}',
                          onChanged: (v) =>
                              setState(() => _eventType = v ?? _eventType),
                        ),
                        const SizedBox(height: 12),

                        // Status dropdown
                        _FieldLabel('Status *'),
                        _DropdownField<String>(
                          value: _eventStatus,
                          items: _eventStatuses,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _eventStatus = v ?? _eventStatus),
                        ),
                        const SizedBox(height: 12),

                        // Featured toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Featured',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Show on featured events section',
                            style: TextStyle(
                              color: context.col.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          value: _eventFeatured,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _eventFeatured = v),
                        ),
                        const SizedBox(height: 4),

                        // Start date & time
                        _FieldLabel('Start Date & Time'),
                        _DateTimePickerTile(
                          value: _startDate,
                          hint: 'Tap to pick start date & time',
                          onPick: (dt) => setState(() => _startDate = dt),
                          onClear: () => setState(() => _startDate = null),
                        ),
                        const SizedBox(height: 12),

                        // End date & time
                        _FieldLabel('End Date & Time'),
                        _DateTimePickerTile(
                          value: _endDate,
                          hint: 'Tap to pick end date & time',
                          onPick: (dt) => setState(() => _endDate = dt),
                          onClear: () => setState(() => _endDate = null),
                        ),
                        const SizedBox(height: 12),

                        // Start time display string
                        _FieldLabel('Start Time Display (e.g. 10:00 AM)'),
                        _TextField(controller: _timeCtrl, hint: '10:00 AM'),
                        const SizedBox(height: 12),

                        // End time display string
                        _FieldLabel('End Time Display (e.g. 5:00 PM)'),
                        _TextField(controller: _endTimeCtrl, hint: '5:00 PM'),
                        const SizedBox(height: 12),

                        // Category
                        _FieldLabel('Category *'),
                        _TextField(
                          controller: _categoryTextCtrl,
                          hint: 'e.g. Festival, Cultural, Sports',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Category is required'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // District
                        _FieldLabel('District'),
                        _TextField(
                          controller: _districtTextCtrl,
                          hint: 'e.g. Aizawl, Lunglei',
                        ),
                        const SizedBox(height: 12),

                        // Attendees
                        _FieldLabel('Expected Attendees'),
                        _TextField(controller: _attendeesCtrl, hint: '0'),
                        const SizedBox(height: 12),

                        // Max attendees
                        _FieldLabel('Max Attendees (blank = unlimited)'),
                        _TextField(
                          controller: _maxAttendeesCtrl,
                          hint: 'Leave blank for unlimited',
                        ),
                        const SizedBox(height: 12),

                        // Ticket price
                        _FieldLabel('Ticket Price'),
                        _TextField(
                          controller: _ticketPriceCtrl,
                          hint: 'e.g. Free, ₹200, ₹500–₹1000',
                        ),
                        const SizedBox(height: 12),

                        // Registration URL
                        _FieldLabel('Registration URL'),
                        _TextField(
                          controller: _registrationUrlCtrl,
                          hint: 'https://...',
                        ),
                        const SizedBox(height: 12),

                        // Organizer
                        _FieldLabel('Organizer'),
                        _TextField(
                          controller: _organizerCtrl,
                          hint: 'e.g. Mizoram Tourism Dept.',
                        ),
                        const SizedBox(height: 12),

                        // Contact email
                        _FieldLabel('Contact Email'),
                        _TextField(
                          controller: _contactEmailCtrl,
                          hint: 'organizer@example.com',
                        ),
                        const SizedBox(height: 12),

                        // Contact phone
                        _FieldLabel('Contact Phone'),
                        _TextField(
                          controller: _contactPhoneCtrl,
                          hint: '+91 XXXXXXXXXX',
                        ),
                      ],
                    ),
                  ],

                  // ── Spots-specific cards ─────────────────────────────────
                  if (_isSpots) ...[
                    const SizedBox(height: 16),
                    // Card 1: core spot details
                    _FieldCard(
                      children: [
                        _FieldLabel('Spot Details'),
                        const SizedBox(height: 8),

                        _FieldLabel('Category'),
                        _DropdownField<String>(
                          value:
                              _spotCategories.contains(_categorySpotCtrl.text)
                              ? _categorySpotCtrl.text
                              : _spotCategories.first,
                          items: _spotCategories,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _categorySpotCtrl.text = v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('District'),
                        _TextField(
                          controller: _districtSpotCtrl,
                          hint: 'e.g. Aizawl, Lunglei',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Status'),
                        _DropdownField<String>(
                          value: _spotStatus,
                          items: _spotStatuses,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _spotStatus = v ?? _spotStatus),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Best Season'),
                        _TextField(
                          controller: _bestSeasonCtrl,
                          hint: 'e.g. Oct–Mar',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Opening Hours'),
                        _TextField(
                          controller: _openingHoursSpotCtrl,
                          hint: 'e.g. Daylight hours (07:00–17:00)',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Distance / How to Reach'),
                        _TextField(
                          controller: _distanceCtrl,
                          hint: 'e.g. In Lunglei District',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Alternate Names (comma-separated)'),
                        _TextField(
                          controller: _alternateNamesCtrl,
                          hint: 'e.g. Thangliana\'s Memorial Stone',
                        ),
                        const SizedBox(height: 12),

                        // Featured + isRateable toggles
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Featured',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _spotFeatured,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _spotFeatured = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Rateable',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _spotIsRateable,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _spotIsRateable = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 2: detailed descriptions
                    _FieldCard(
                      children: [
                        _FieldLabel('Place Story'),
                        _TextField(
                          controller: _placeStoryCtrl,
                          hint: 'A memorial stone erected in honour of…',
                          maxLines: 5,
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Facilities'),
                        _TextField(
                          controller: _facilitiesCtrl,
                          hint: 'e.g. None (natural memorial stone)',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Accessibility'),
                        _TextField(
                          controller: _accessibilityCtrl,
                          hint: 'e.g. Accessible by road + short walk',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Safety Notes'),
                        _TextField(
                          controller: _safetyNotesCtrl,
                          hint: 'e.g. Outdoor terrain; minimal facilities',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Official Source URL'),
                        _TextField(
                          controller: _officialSourceUrlCtrl,
                          hint: 'https://…',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 3: lists
                    _FieldCard(
                      children: [
                        _FieldLabel('Things To Do (one per line)'),
                        _TextField(
                          controller: _thingsToDoCtrl,
                          hint: 'Family Visit\nPhotography\nTrekking',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Add-Ons (one per line)'),
                        _TextField(
                          controller: _addOnsCtrl,
                          hint: 'Guided Tour\nPicknic Spot',
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 4: entry fees
                    _FieldCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ENTRY FEES',
                                style: TextStyle(
                                  color: context.col.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(
                                () => _entryFees.add({
                                  'type': TextEditingController(text: 'Adult'),
                                  'amount': TextEditingController(
                                    text: '₹Free / Nominal',
                                  ),
                                }),
                              ),
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'Add Fee',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_entryFees.isEmpty)
                          Text(
                            'No entry fees added. Tap "Add Fee" to add one.',
                            style: TextStyle(
                              color: context.col.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        for (int i = 0; i < _entryFees.length; i++) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _TextField(
                                  controller: _entryFees[i]['type']!,
                                  hint: 'Type (e.g. Adult)',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: _TextField(
                                  controller: _entryFees[i]['amount']!,
                                  hint: 'Amount (e.g. ₹50)',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _entryFees.removeAt(i)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 5: coordinates + popularity
                    _FieldCard(
                      children: [
                        _FieldLabel('Coordinates & Metrics'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Latitude'),
                                  _TextField(
                                    controller: _latCtrl,
                                    hint: 'e.g. 22.53',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Longitude'),
                                  _TextField(
                                    controller: _lngCtrl,
                                    hint: 'e.g. 92.63',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel('Popularity Score (0–10)'),
                        _TextField(
                          controller: _popularityCtrl,
                          hint: 'e.g. 7.5',
                        ),
                      ],
                    ),
                  ],

                  // ── Accommodations-specific cards ─────────────────────────
                  if (_isAccommodations) ...[
                    const SizedBox(height: 16),
                    _FieldCard(
                      children: [
                        _FieldLabel('Accommodation Details'),
                        const SizedBox(height: 8),

                        _FieldLabel('Type'),
                        _DropdownField<String>(
                          value: _accType,
                          items: _accTypes,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _accType = v ?? _accType),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Price Per Night (₹)'),
                        _TextField(
                          controller: _pricePerNightCtrl,
                          hint: 'e.g. 1500',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Number of Rooms'),
                        _TextField(controller: _roomsCtrl, hint: 'e.g. 20'),
                        const SizedBox(height: 12),

                        _FieldLabel('Capacity (guests)'),
                        _TextField(
                          controller: _capacityAccCtrl,
                          hint: 'e.g. 4',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Phone Number'),
                        _TextField(
                          controller: _phoneAccCtrl,
                          hint: 'e.g. 1234567890',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('District'),
                        _TextField(
                          controller: _districtAccCtrl,
                          hint: 'e.g. Aizawl, Lunglei',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Amenities (comma-separated)'),
                        _TextField(
                          controller: _amenitiesAccCtrl,
                          hint: 'e.g. Test 123, Free Wi-Fi, Parking',
                        ),
                        const SizedBox(height: 12),

                        // Toggles
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Breakfast',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _accHasBreakfast,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _accHasBreakfast = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Wi-Fi',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _accHasWifi,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _accHasWifi = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Parking',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _accHasParking,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _accHasParking = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Verified',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _accIsVerified,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _accIsVerified = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 2: Coordinates
                    _FieldCard(
                      children: [
                        _FieldLabel('Coordinates'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Latitude'),
                                  _TextField(
                                    controller: _latAccCtrl,
                                    hint: 'e.g. 23.33444',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Longitude'),
                                  _TextField(
                                    controller: _lngAccCtrl,
                                    hint: 'e.g. 92.33434',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // ── Restaurants-specific cards ────────────────────────────
                  if (_isRestaurants) ...[
                    const SizedBox(height: 16),
                    // Card 1: Core details
                    _FieldCard(
                      children: [
                        _FieldLabel('Restaurant Details'),
                        const SizedBox(height: 8),

                        _FieldLabel('Price Range'),
                        _DropdownField<String>(
                          value: _priceRange,
                          items: _priceRanges,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _priceRange = v ?? _priceRange),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Opening Hours'),
                        _TextField(
                          controller: _openingHoursRestCtrl,
                          hint: 'e.g. Mon–Sat: 9:00AM – 10:00PM',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Phone Number'),
                        _TextField(
                          controller: _phoneCtrl,
                          hint: 'e.g. 1234567890',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('District'),
                        _TextField(
                          controller: _districtRestCtrl,
                          hint: 'e.g. Aizawl, Lunglei',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Seating Capacity'),
                        _TextField(controller: _capacityCtrl, hint: 'e.g. 36'),
                        const SizedBox(height: 12),

                        _FieldLabel('Cuisine Types (comma-separated)'),
                        _TextField(
                          controller: _cuisineTypesCtrl,
                          hint: 'e.g. Mizo, Indian, Chinese',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Specialties (comma-separated)'),
                        _TextField(
                          controller: _specialtiesCtrl,
                          hint: 'e.g. Bai, Vawksa Rep, Zu',
                        ),
                        const SizedBox(height: 12),

                        // Feature toggles
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Delivery',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _hasDelivery,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasDelivery = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Parking',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _hasParking,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasParking = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Reservation',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _hasReservation,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _hasReservation = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Verified',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _isVerified,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isVerified = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 2: Coordinates
                    _FieldCard(
                      children: [
                        _FieldLabel('Coordinates'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Latitude'),
                                  _TextField(
                                    controller: _latRestCtrl,
                                    hint: 'e.g. 23.32323',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Longitude'),
                                  _TextField(
                                    controller: _lngRestCtrl,
                                    hint: 'e.g. 92.142341',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // ── Cafe-specific cards ───────────────────────────────────
                  if (_isCafe) ...[
                    const SizedBox(height: 16),
                    _FieldCard(
                      children: [
                        _FieldLabel('Cafe Details'),
                        const SizedBox(height: 8),

                        // Cafe logo — single image (imageUrl)
                        _FieldLabel('Cafe Logo'),
                        const SizedBox(height: 6),
                        _CafeLogoPicker(
                          existingUrl: _cafeExistingLogoUrl,
                          newImage: _newCafeLogoImage,
                          uploading: _uploadingCafeLogo,
                          onPick: _pickCafeLogo,
                          onRemove: () => setState(() {
                            _cafeExistingLogoUrl = null;
                            _newCafeLogoImage = null;
                          }),
                        ),
                        const SizedBox(height: 16),

                        _FieldLabel('Price Range'),
                        _DropdownField<String>(
                          value: _cafePriceRange,
                          items: const ['Low', 'Medium', 'High'],
                          label: (v) => v,
                          onChanged: (v) => setState(
                              () => _cafePriceRange = v ?? _cafePriceRange),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Opening Hours'),
                        _TextField(
                          controller: _openingHoursCafeCtrl,
                          hint: 'e.g. Mon – Sat 10:00AM – 11:00PM',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Phone Number'),
                        _TextField(
                          controller: _phoneCafeCtrl,
                          hint: 'e.g. +91 9876543210',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Specialties (comma-separated)'),
                        _TextField(
                          controller: _specialtiesCafeCtrl,
                          hint: 'e.g. Coffee, Espresso, Cold Brew',
                        ),
                        const SizedBox(height: 12),

                        // Feature toggles
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Wi-Fi',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _cafeHasWifi,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _cafeHasWifi = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Parking',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _cafeHasParking,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _cafeHasParking = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Open on Sunday',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _cafeIsSundayOpen,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _cafeIsSundayOpen = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Verified',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _cafeIsVerified,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _cafeIsVerified = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 2: Coordinates
                    _FieldCard(
                      children: [
                        _FieldLabel('Coordinates'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Latitude'),
                                  _TextField(
                                    controller: _latCafeCtrl,
                                    hint: 'e.g. 23.72344',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Longitude'),
                                  _TextField(
                                    controller: _lngCafeCtrl,
                                    hint: 'e.g. 92.7344',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // ── Shopping-specific cards ───────────────────────────────
                  if (_isShopping) ...[
                    const SizedBox(height: 16),
                    // Card 1: Core details
                    _FieldCard(
                      children: [
                        _FieldLabel('Shopping Details'),
                        const SizedBox(height: 8),

                        _FieldLabel('Type'),
                        _DropdownField<String>(
                          value: _shopType,
                          items: _shopTypes,
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _shopType = v ?? _shopType),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Price Range'),
                        _DropdownField<String>(
                          value: _shopPriceRange,
                          items: const ['Low', 'Medium', 'High'],
                          label: (v) => v,
                          onChanged: (v) =>
                              setState(() => _shopPriceRange = v ?? _shopPriceRange),
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Opening Hours'),
                        _TextField(
                          controller: _openingHoursShopCtrl,
                          hint: 'e.g. 10:00AM – 5:00PM',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Phone Number'),
                        _TextField(
                          controller: _phoneShopCtrl,
                          hint: 'e.g. +91 9876543210',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('District'),
                        _TextField(
                          controller: _districtShopCtrl,
                          hint: 'e.g. Aizawl',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Products (comma-separated)'),
                        _TextField(
                          controller: _productsShopCtrl,
                          hint: 'e.g. Clothing, Accessories, Electronics',
                        ),
                        const SizedBox(height: 12),

                        _FieldLabel('Specialties (comma-separated)'),
                        _TextField(
                          controller: _specialtiesShopCtrl,
                          hint: 'e.g. Traditional wear, Handloom',
                        ),
                        const SizedBox(height: 12),

                        // Feature toggles
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Delivery',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _shopHasDelivery,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _shopHasDelivery = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Has Parking',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _shopHasParking,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _shopHasParking = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Accepts Cards',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _shopAcceptsCards,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _shopAcceptsCards = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Popular',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _shopIsPopular,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _shopIsPopular = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Is Verified',
                            style: TextStyle(
                              color: context.col.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          value: _shopIsVerified,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _shopIsVerified = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Card 2: Coordinates
                    _FieldCard(
                      children: [
                        _FieldLabel('Coordinates'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Latitude'),
                                  _TextField(
                                    controller: _latShopCtrl,
                                    hint: 'e.g. 23.42344',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('Longitude'),
                                  _TextField(
                                    controller: _lngShopCtrl,
                                    hint: 'e.g. 93.3344',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // ── Generic extra-fields card ────────────────────────────
                  if (!_isEvents &&
                      !_isSpots &&
                      !_isRestaurants &&
                      !_isAccommodations &&
                      !_isCafe &&
                      !_isShopping &&
                      _extraKeys.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _FieldCard(
                      children: [
                        _FieldLabel('Additional Details'),
                        const SizedBox(height: 8),
                        for (final key in _extraKeys) ...[
                          _FieldLabel(_capitalise(key)),
                          if (key == 'startDate')
                            _DateTimePickerTile(
                              value: _startDate,
                              hint: 'Pick start date & time',
                              onPick: (dt) => setState(() => _startDate = dt),
                              onClear: () => setState(() => _startDate = null),
                            )
                          else if (key == 'endDate')
                            _DateTimePickerTile(
                              value: _endDate,
                              hint: 'Pick end date & time',
                              onPick: (dt) => setState(() => _endDate = dt),
                              onClear: () => setState(() => _endDate = null),
                            )
                          else
                            _TextField(
                              controller: _extraControllers[key]!,
                              hint: key,
                            ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isEditMode ? 'Update Listing' : 'Create Listing',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  String _collectionLabel() {
    final tab = ListingTab.values
        .where((t) => t.collection == widget.collection)
        .firstOrNull;
    return tab?.label ?? widget.collection;
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: context.col.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: col.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: col.textMuted),
        filled: true,
        fillColor: col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date + Time picker tile
// ─────────────────────────────────────────────────────────────────────────────

class _DateTimePickerTile extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _DateTimePickerTile({
    required this.value,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  Future<void> _pick(BuildContext context) async {
    final col = context.col;

    // Step 1: pick date
    final now = DateTime.now();
    final initialDate = value ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: col.surface,
            onSurface: col.textPrimary,
          ),
          dialogBackgroundColor: col.surface,
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;

    // Step 2: pick time
    final initialTime = value != null
        ? TimeOfDay.fromDateTime(value!)
        : TimeOfDay.now();
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: col.surface,
            onSurface: col.textPrimary,
          ),
          dialogBackgroundColor: col.surface,
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final formatted = value != null
        ? DateFormat('EEE, MMM d yyyy  •  hh:mm a').format(value!)
        : null;

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: col.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value != null ? AppColors.primary : col.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: value != null ? AppColors.primary : col.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatted ?? hint,
                style: TextStyle(
                  color: value != null ? col.textPrimary : col.textMuted,
                  fontSize: 13,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 16, color: col.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image picker field
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePickerField extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newImages;
  final bool uploading;
  final VoidCallback onPick;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  const _ImagePickerField({
    required this.existingUrls,
    required this.newImages,
    required this.uploading,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final totalCount = existingUrls.length + newImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnails grid
        if (totalCount > 0) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Already-uploaded images (edit mode)
              for (int i = 0; i < existingUrls.length; i++)
                _ImageThumb(
                  child: Image.network(
                    existingUrls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: col.textMuted,
                      size: 28,
                    ),
                  ),
                  onRemove: () => onRemoveExisting(i),
                ),
              // Newly picked (not yet uploaded)
              for (int i = 0; i < newImages.length; i++)
                _ImageThumb(
                  child: Image.file(File(newImages[i].path), fit: BoxFit.cover),
                  onRemove: () => onRemoveNew(i),
                  badge: uploading ? null : const _UploadBadge(),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // Pick button
        GestureDetector(
          onTap: uploading ? null : onPick,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: col.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.border, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (uploading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading…',
                    style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalCount == 0
                        ? 'Pick images from device'
                        : 'Add more images',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (totalCount == 0) ...[
          const SizedBox(height: 6),
          Text(
            'No images added yet.',
            style: TextStyle(color: col.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  final Widget? badge;

  const _ImageThumb({required this.child, required this.onRemove, this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
          if (badge != null) Positioned(bottom: 4, left: 4, child: badge!),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadBadge extends StatelessWidget {
  const _UploadBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'New',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic dropdown field
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      dropdownColor: col.surface,
      style: TextStyle(color: col.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                label(item),
                style: TextStyle(color: col.textPrimary, fontSize: 14),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cafe logo picker — single image (imageUrl)
// ─────────────────────────────────────────────────────────────────────────────

class _CafeLogoPicker extends StatelessWidget {
  final String? existingUrl;
  final XFile? newImage;
  final bool uploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _CafeLogoPicker({
    required this.existingUrl,
    required this.newImage,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final hasImage = newImage != null || (existingUrl?.isNotEmpty ?? false);

    return Row(
      children: [
        // Thumbnail / placeholder
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: col.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: hasImage
                  ? (newImage != null
                      ? Image.network(
                          newImage!.path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: col.textMuted,
                          ),
                        )
                      : Image.network(
                          existingUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: col.textMuted,
                          ),
                        ))
                  : Icon(
                      Icons.add_photo_alternate_outlined,
                      color: col.textMuted,
                      size: 32,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: uploading ? null : onPick,
              icon: const Icon(Icons.photo_library_outlined,
                  size: 16, color: AppColors.primary),
              label: Text(
                hasImage ? 'Change Logo' : 'Pick Logo',
                style:
                    const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.error),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            if (uploading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
