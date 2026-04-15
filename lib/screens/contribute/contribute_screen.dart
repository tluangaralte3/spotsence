// lib/screens/contribute/contribute_screen.dart
//
// Multi-step form for users to contribute new listings (spots, restaurants,
// cafes, adventures, homestays, shopping areas, events).
//
// The user must capture their current GPS coordinates on-site.
// Submissions go to `contributed_listings` for admin review. On approval
// the listing is published to the appropriate collection and appears on the map.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../controllers/gamification_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contributed_listing_model.dart';
import '../../models/gamification_models.dart';
import '../../services/contribute_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  bool _submitting = false;

  // Step 0 – Category
  ContributionCategory _category = ContributionCategory.spot;

  // Step 1 – Basic details
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 2 – Location
  bool _gettingLocation = false;
  double? _lat;
  double? _lng;
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Step 3 – Category-specific (managed by _SpecificsStep child state)
  Map<String, dynamic> _specificDetails = {};

  // Step 4 – Photos
  final List<XFile> _photos = [];

  static const _stepCount = 6;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onTextChange);
    _descCtrl.addListener(_onTextChange);
    _districtCtrl.addListener(_onTextChange);
  }

  void _onTextChange() => setState(() {});

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.removeListener(_onTextChange);
    _descCtrl.removeListener(_onTextChange);
    _districtCtrl.removeListener(_onTextChange);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _nameCtrl.text.trim().isNotEmpty &&
            _descCtrl.text.trim().length >= 20;
      case 2:
        return _lat != null &&
            _lng != null &&
            _districtCtrl.text.trim().isNotEmpty;
      case 3:
        return true;
      case 4:
        return _photos.isNotEmpty;
      default:
        return true;
    }
  }

  // GPS capture ───────────────────────────────────────────────────────────────

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services disabled. Enable them in Settings.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permanently denied. Enable it in app settings.'),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  // Photo picker ──────────────────────────────────────────────────────────────

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _photos.addAll(picked.take(5 - _photos.length));
      });
    }
  }

  // Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final svc = ref.read(contributeServiceProvider);
    final error = await svc.submit(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
      category: _category,
      photos: _photos,
      details: _specificDetails,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      await ref
          .read(gamificationControllerProvider.notifier)
          .award(XpAction.submitContribution);
      await ref
          .read(gamificationControllerProvider.notifier)
          .incrementCounter('contributionsCount');

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: context.col.surfaceElevated,
          title: const Text('🎉 Submitted!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your ${_category.label} has been submitted for admin review. '
                'Once approved it will appear on the map and listings.',
                style: TextStyle(color: context.col.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('+20 XP Earned',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: _back,
              )
            : IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => context.pop(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contribute a Place',
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              'Step ${_step + 1} of $_stepCount',
              style: TextStyle(color: col.textMuted, fontSize: 12),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / _stepCount,
            backgroundColor: col.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _CategoryStep(
            selected: _category,
            onSelect: (c) => setState(() {
              _category = c;
              _specificDetails = {};
            }),
          ),
          _DetailsStep(nameCtrl: _nameCtrl, descCtrl: _descCtrl),
          _LocationStep(
            lat: _lat,
            lng: _lng,
            gettingLocation: _gettingLocation,
            onCapture: _captureLocation,
            districtCtrl: _districtCtrl,
            addressCtrl: _addressCtrl,
          ),
          _SpecificsStep(
            key: ValueKey(_category),
            category: _category,
            onChanged: (details) => _specificDetails = details,
          ),
          _PhotosStep(
            photos: _photos,
            onPick: _pickPhotos,
            onRemove: (i) => setState(() => _photos.removeAt(i)),
          ),
          _ReviewStep(
            category: _category,
            name: _nameCtrl.text,
            description: _descCtrl.text,
            address: _addressCtrl.text,
            district: _districtCtrl.text,
            lat: _lat,
            lng: _lng,
            photoCount: _photos.length,
            submitting: _submitting,
            onSubmit: _submit,
          ),
        ],
      ),
      bottomNavigationBar: _step < _stepCount - 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: _canProceed ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.3),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 – Category
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryStep extends StatelessWidget {
  final ContributionCategory selected;
  final ValueChanged<ContributionCategory> onSelect;
  const _CategoryStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('What type of place?',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text('Select the category that best describes the place.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: ContributionCategory.values.length,
          itemBuilder: (_, i) {
            final cat = ContributionCategory.values[i];
            final isSelected = selected == cat;
            return GestureDetector(
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : col.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(cat.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 – Details
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  final TextEditingController nameCtrl, descCtrl;
  const _DetailsStep({required this.nameCtrl, required this.descCtrl});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Basic Details',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text('Give the place a name and describe it.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        const _CLabel('Place Name *'),
        const SizedBox(height: 8),
        _CField(controller: nameCtrl, hint: 'e.g. Lunglei Viewpoint'),
        const SizedBox(height: 20),
        const _CLabel('Description * (min 20 characters)'),
        const SizedBox(height: 8),
        _CField(
          controller: descCtrl,
          hint:
              'Describe the place — what makes it special, what visitors can expect…',
          maxLines: 6,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 – Location
// ─────────────────────────────────────────────────────────────────────────────

class _LocationStep extends StatelessWidget {
  final double? lat, lng;
  final bool gettingLocation;
  final VoidCallback onCapture;
  final TextEditingController districtCtrl, addressCtrl;
  const _LocationStep({
    required this.lat,
    required this.lng,
    required this.gettingLocation,
    required this.onCapture,
    required this.districtCtrl,
    required this.addressCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final hasLocation = lat != null && lng != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your Location',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text(
            'You must be physically at the place to capture GPS coordinates.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasLocation
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasLocation
                  ? AppColors.success.withValues(alpha: 0.35)
                  : AppColors.warning.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                    hasLocation ? Icons.location_on : Icons.location_off,
                    color: hasLocation
                        ? AppColors.success
                        : AppColors.warning,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  hasLocation ? 'Location Captured ✓' : 'GPS Required',
                  style: TextStyle(
                    color: hasLocation
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              if (hasLocation)
                Text(
                  'Lat: ${lat!.toStringAsFixed(6)}  ·  Lng: ${lng!.toStringAsFixed(6)}',
                  style:
                      TextStyle(color: col.textSecondary, fontSize: 12),
                )
              else
                Text(
                  'Stand at the location and tap the button below.',
                  style:
                      TextStyle(color: col.textSecondary, fontSize: 12),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: gettingLocation ? null : onCapture,
                  icon: gettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(gettingLocation
                      ? 'Getting location…'
                      : hasLocation
                          ? 'Recapture Location'
                          : 'Capture My Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _CLabel('District / City *'),
        const SizedBox(height: 8),
        _CField(
            controller: districtCtrl,
            hint: 'e.g. Aizawl, Lunglei, Champhai'),
        const SizedBox(height: 16),
        const _CLabel('Full Address (optional)'),
        const SizedBox(height: 8),
        _CField(
            controller: addressCtrl,
            hint: 'Street / village name',
            maxLines: 2),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 – Category-specific details (stateful child)
// ─────────────────────────────────────────────────────────────────────────────

class _SpecificsStep extends StatefulWidget {
  final ContributionCategory category;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _SpecificsStep(
      {super.key, required this.category, required this.onChanged});

  @override
  State<_SpecificsStep> createState() => _SpecificsStepState();
}

class _SpecificsStepState extends State<_SpecificsStep> {
  String _spotCategory = 'mountains';
  final _bestSeasonCtrl = TextEditingController();
  final _openingHoursCtrl = TextEditingController();
  final _facilitiesCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();
  final _specialtiesCtrl = TextEditingController();
  String _priceRange = '₹₹';
  bool _hasDelivery = false, _hasReservation = false;
  bool _hasWifi = false, _hasOutdoorSeating = false;
  final _contactCtrl = TextEditingController();
  String _adventureCat = 'trekking', _difficulty = 'Moderate';
  final _durationCtrl = TextEditingController();
  final _activitiesCtrl = TextEditingController();
  final _maxGuestsCtrl = TextEditingController(text: '4');
  final _hostNameCtrl = TextEditingController();
  bool _hasBreakfast = false, _hasFreePickup = false;
  final _amenitiesCtrl = TextEditingController();
  String _shoppingType = 'market';
  final _productsCtrl = TextEditingController();
  bool _hasParking = false, _acceptsCards = false;
  DateTime? _eventDate;
  final _eventTimeCtrl = TextEditingController();
  String _eventType = 'cultural';

  @override
  void dispose() {
    for (final c in [
      _bestSeasonCtrl,
      _openingHoursCtrl,
      _facilitiesCtrl,
      _cuisineCtrl,
      _specialtiesCtrl,
      _contactCtrl,
      _durationCtrl,
      _activitiesCtrl,
      _maxGuestsCtrl,
      _hostNameCtrl,
      _amenitiesCtrl,
      _productsCtrl,
      _eventTimeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _split(String text) =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, dynamic> _build() {
    switch (widget.category) {
      case ContributionCategory.spot:
        return {
          'spotCategory': _spotCategory,
          if (_bestSeasonCtrl.text.trim().isNotEmpty)
            'bestSeason': _bestSeasonCtrl.text.trim(),
          if (_openingHoursCtrl.text.trim().isNotEmpty)
            'openingHours': _openingHoursCtrl.text.trim(),
          if (_facilitiesCtrl.text.trim().isNotEmpty)
            'facilities': _facilitiesCtrl.text.trim(),
        };
      case ContributionCategory.restaurant:
        return {
          'cuisineTypes': _split(_cuisineCtrl.text),
          'priceRange': _priceRange,
          if (_openingHoursCtrl.text.trim().isNotEmpty)
            'openingHours': _openingHoursCtrl.text.trim(),
          'hasDelivery': _hasDelivery,
          'hasReservation': _hasReservation,
          if (_contactCtrl.text.trim().isNotEmpty)
            'contactPhone': _contactCtrl.text.trim(),
        };
      case ContributionCategory.cafe:
        return {
          'specialties': _split(_specialtiesCtrl.text),
          'priceRange': _priceRange,
          if (_openingHoursCtrl.text.trim().isNotEmpty)
            'openingHours': _openingHoursCtrl.text.trim(),
          'hasWifi': _hasWifi,
          'hasOutdoorSeating': _hasOutdoorSeating,
          if (_contactCtrl.text.trim().isNotEmpty)
            'contactPhone': _contactCtrl.text.trim(),
        };
      case ContributionCategory.adventure:
        return {
          'adventureCategory': _adventureCat,
          'difficulty': _difficulty,
          if (_durationCtrl.text.trim().isNotEmpty)
            'duration': _durationCtrl.text.trim(),
          if (_bestSeasonCtrl.text.trim().isNotEmpty)
            'bestSeason': _bestSeasonCtrl.text.trim(),
          'activities': _split(_activitiesCtrl.text),
        };
      case ContributionCategory.homestay:
        return {
          'maxGuests': int.tryParse(_maxGuestsCtrl.text.trim()) ?? 2,
          if (_hostNameCtrl.text.trim().isNotEmpty)
            'hostName': _hostNameCtrl.text.trim(),
          'hasBreakfast': _hasBreakfast,
          'hasFreePickup': _hasFreePickup,
          'priceRange': _priceRange,
          'amenities': _split(_amenitiesCtrl.text),
          if (_contactCtrl.text.trim().isNotEmpty)
            'contactPhone': _contactCtrl.text.trim(),
        };
      case ContributionCategory.shopping:
        return {
          'shoppingType': _shoppingType,
          'products': _split(_productsCtrl.text),
          'priceRange': _priceRange,
          if (_openingHoursCtrl.text.trim().isNotEmpty)
            'openingHours': _openingHoursCtrl.text.trim(),
          'hasParking': _hasParking,
          'acceptsCards': _acceptsCards,
        };
      case ContributionCategory.event:
        return {
          'eventDate': _eventDate != null
              ? DateFormat('yyyy-MM-dd').format(_eventDate!)
              : '',
          if (_eventTimeCtrl.text.trim().isNotEmpty)
            'eventTime': _eventTimeCtrl.text.trim(),
          'eventType': _eventType,
          'eventCategory': _eventType,
        };
    }
  }

  void _notify() => widget.onChanged(_build());

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${widget.category.label} Details',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text('All fields optional — add what you know.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        ..._fields(context),
      ],
    );
  }

  List<Widget> _fields(BuildContext context) {
    switch (widget.category) {
      case ContributionCategory.spot:
        return [
          const _CLabel('Spot Type'),
          const SizedBox(height: 8),
          _ChipGroup(
            options: const [
              'mountains', 'waterfalls', 'cultural sites',
              'viewpoints', 'adventure', 'lakes', 'caves', 'other'
            ],
            selected: _spotCategory,
            onSelected: (v) {
              setState(() => _spotCategory = v);
              _notify();
            },
          ),
          const SizedBox(height: 16),
          const _CLabel('Best Season'),
          const SizedBox(height: 8),
          _CField(
              controller: _bestSeasonCtrl,
              hint: 'e.g. October–March',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Opening Hours'),
          const SizedBox(height: 8),
          _CField(
              controller: _openingHoursCtrl,
              hint: 'e.g. Open 24 hours',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Facilities'),
          const SizedBox(height: 8),
          _CField(
              controller: _facilitiesCtrl,
              hint: 'e.g. Parking, Toilets, Guides',
              onChanged: (_) => _notify()),
        ];
      case ContributionCategory.restaurant:
        return [
          const _CLabel('Cuisine Types'),
          const SizedBox(height: 8),
          _CField(
              controller: _cuisineCtrl,
              hint: 'e.g. Mizo, Indian, Chinese (comma-separated)',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Price Range'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['₹', '₹₹', '₹₹₹', '₹₹₹₹'],
              selected: _priceRange,
              onSelected: (v) {
                setState(() => _priceRange = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Opening Hours'),
          const SizedBox(height: 8),
          _CField(
              controller: _openingHoursCtrl,
              hint: 'e.g. 9 AM – 10 PM',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Contact Phone'),
          const SizedBox(height: 8),
          _CField(
              controller: _contactCtrl,
              hint: '+91 XXXXXXXXXX',
              keyboardType: TextInputType.phone,
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          _SwitchRow('Offers Delivery', _hasDelivery, (v) {
            setState(() => _hasDelivery = v);
            _notify();
          }),
          _SwitchRow('Accepts Reservations', _hasReservation, (v) {
            setState(() => _hasReservation = v);
            _notify();
          }),
        ];
      case ContributionCategory.cafe:
        return [
          const _CLabel('Specialties'),
          const SizedBox(height: 8),
          _CField(
              controller: _specialtiesCtrl,
              hint: 'e.g. Cold Brew, Mizo Tea (comma-separated)',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Price Range'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['₹', '₹₹', '₹₹₹', '₹₹₹₹'],
              selected: _priceRange,
              onSelected: (v) {
                setState(() => _priceRange = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Opening Hours'),
          const SizedBox(height: 8),
          _CField(
              controller: _openingHoursCtrl,
              hint: 'e.g. 8 AM – 9 PM',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Contact Phone'),
          const SizedBox(height: 8),
          _CField(
              controller: _contactCtrl,
              hint: '+91 XXXXXXXXXX',
              keyboardType: TextInputType.phone,
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          _SwitchRow('Has WiFi', _hasWifi, (v) {
            setState(() => _hasWifi = v);
            _notify();
          }),
          _SwitchRow('Outdoor Seating', _hasOutdoorSeating, (v) {
            setState(() => _hasOutdoorSeating = v);
            _notify();
          }),
        ];
      case ContributionCategory.adventure:
        return [
          const _CLabel('Adventure Type'),
          const SizedBox(height: 8),
          _ChipGroup(
            options: const [
              'trekking', 'camping', 'paragliding',
              'rock climbing', 'river rafting', 'cycling', 'other'
            ],
            selected: _adventureCat,
            onSelected: (v) {
              setState(() => _adventureCat = v);
              _notify();
            },
          ),
          const SizedBox(height: 16),
          const _CLabel('Difficulty'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['Easy', 'Moderate', 'Challenging', 'Extreme'],
              selected: _difficulty,
              onSelected: (v) {
                setState(() => _difficulty = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Duration'),
          const SizedBox(height: 8),
          _CField(
              controller: _durationCtrl,
              hint: 'e.g. 3 hours, 1 day',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Best Season'),
          const SizedBox(height: 8),
          _CField(
              controller: _bestSeasonCtrl,
              hint: 'e.g. October–April',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Activities (comma-separated)'),
          const SizedBox(height: 8),
          _CField(
              controller: _activitiesCtrl,
              hint: 'e.g. Trekking, Photography, Swimming',
              onChanged: (_) => _notify()),
        ];
      case ContributionCategory.homestay:
        return [
          const _CLabel('Host Name'),
          const SizedBox(height: 8),
          _CField(
              controller: _hostNameCtrl,
              hint: 'Your name or host name',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Max Guests'),
          const SizedBox(height: 8),
          _CField(
              controller: _maxGuestsCtrl,
              hint: 'e.g. 4',
              keyboardType: TextInputType.number,
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Price Range'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['₹', '₹₹', '₹₹₹', '₹₹₹₹'],
              selected: _priceRange,
              onSelected: (v) {
                setState(() => _priceRange = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Contact Phone'),
          const SizedBox(height: 8),
          _CField(
              controller: _contactCtrl,
              hint: '+91 XXXXXXXXXX',
              keyboardType: TextInputType.phone,
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Amenities (comma-separated)'),
          const SizedBox(height: 8),
          _CField(
              controller: _amenitiesCtrl,
              hint: 'e.g. WiFi, Hot water, Kitchen',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          _SwitchRow('Breakfast Included', _hasBreakfast, (v) {
            setState(() => _hasBreakfast = v);
            _notify();
          }),
          _SwitchRow('Free Pickup', _hasFreePickup, (v) {
            setState(() => _hasFreePickup = v);
            _notify();
          }),
        ];
      case ContributionCategory.shopping:
        return [
          const _CLabel('Shopping Area Type'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['market', 'mall', 'street', 'boutique'],
              selected: _shoppingType,
              onSelected: (v) {
                setState(() => _shoppingType = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Products Available (comma-separated)'),
          const SizedBox(height: 8),
          _CField(
              controller: _productsCtrl,
              hint: 'e.g. Handicrafts, Bamboo goods, Textiles',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Price Range'),
          const SizedBox(height: 8),
          _ChipGroup(
              options: const ['₹', '₹₹', '₹₹₹', '₹₹₹₹'],
              selected: _priceRange,
              onSelected: (v) {
                setState(() => _priceRange = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Opening Hours'),
          const SizedBox(height: 8),
          _CField(
              controller: _openingHoursCtrl,
              hint: 'e.g. Mon–Sat 9 AM – 7 PM',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          _SwitchRow('Has Parking', _hasParking, (v) {
            setState(() => _hasParking = v);
            _notify();
          }),
          _SwitchRow('Accepts Cards', _acceptsCards, (v) {
            setState(() => _acceptsCards = v);
            _notify();
          }),
        ];
      case ContributionCategory.event:
        return [
          const _CLabel('Event Date'),
          const SizedBox(height: 8),
          _DatePickerRow(
              selected: _eventDate,
              onSelected: (v) {
                setState(() => _eventDate = v);
                _notify();
              }),
          const SizedBox(height: 16),
          const _CLabel('Event Time'),
          const SizedBox(height: 8),
          _CField(
              controller: _eventTimeCtrl,
              hint: 'e.g. 6:00 PM',
              onChanged: (_) => _notify()),
          const SizedBox(height: 16),
          const _CLabel('Event Type'),
          const SizedBox(height: 8),
          _ChipGroup(
            options: const [
              'festival', 'cultural', 'adventure',
              'music', 'food', 'other'
            ],
            selected: _eventType,
            onSelected: (v) {
              setState(() => _eventType = v);
              _notify();
            },
          ),
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 – Photos
// ─────────────────────────────────────────────────────────────────────────────

class _PhotosStep extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  const _PhotosStep(
      {required this.photos, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Add Photos',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text('At least 1 photo required. Up to 5 photos.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        if (photos.isEmpty)
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 10),
                  Text('Tap to add photos',
                      style:
                          TextStyle(color: col.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ),
        if (photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: photos.length + (photos.length < 5 ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == photos.length) {
                return GestureDetector(
                  onTap: onPick,
                  child: Container(
                    decoration: BoxDecoration(
                      color: col.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: col.border),
                    ),
                    child: Icon(Icons.add, color: col.textMuted, size: 28),
                  ),
                );
              }
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(photos[i].path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 – Review & Submit
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final ContributionCategory category;
  final String name, description, address, district;
  final double? lat, lng;
  final int photoCount;
  final bool submitting;
  final VoidCallback onSubmit;
  const _ReviewStep({
    required this.category,
    required this.name,
    required this.description,
    required this.address,
    required this.district,
    required this.lat,
    required this.lng,
    required this.photoCount,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Review & Submit',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22)),
        const SizedBox(height: 6),
        Text(
            'Your contribution will be reviewed by admin before going live.',
            style: TextStyle(color: col.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        _reviewRow('Category', '${category.emoji} ${category.label}', col),
        _reviewRow('Name', name, col),
        _reviewRow('District', district, col),
        if (address.isNotEmpty) _reviewRow('Address', address, col),
        _reviewRow(
          'GPS',
          lat != null
              ? '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}'
              : 'Not captured',
          col,
        ),
        _reviewRow('Photos', '$photoCount photo(s)', col),
        _reviewRow('Description', description, col),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.info, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "After admin approval your listing appears on the map and in listings. You'll earn +20 XP.",
                  style: TextStyle(
                      color: col.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: submitting ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : const Text('Submit for Review',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CLabel extends StatelessWidget {
  final String text;
  const _CLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: context.col.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _CField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const _CField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: col.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: col.textMuted, fontSize: 13),
        filled: true,
        fillColor: col.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: col.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: col.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const _ChipGroup(
      {required this.options,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSel = selected == opt;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : col.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSel ? AppColors.primary : col.border,
                  width: isSel ? 1.5 : 1),
            ),
            child: Text(opt,
                style: TextStyle(
                  color: isSel ? AppColors.primary : col.textPrimary,
                  fontSize: 12,
                  fontWeight:
                      isSel ? FontWeight.w700 : FontWeight.w500,
                )),
          ),
        );
      }).toList(),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: context.col.textPrimary, fontSize: 14)),
            Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary),
          ],
        ),
      );
}

class _DatePickerRow extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  const _DatePickerRow(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              selected ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate:
              DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: col.textSecondary),
            const SizedBox(width: 10),
            Text(
              selected != null
                  ? DateFormat('dd MMM yyyy').format(selected!)
                  : 'Select date',
              style: TextStyle(
                  color: selected != null
                      ? col.textPrimary
                      : col.textMuted,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _reviewRow(String label, String value, AppColorScheme col) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: col.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
