// lib/screens/admin/listings/admin_venture_form_screen.dart
//
// Dedicated admin form for creating / editing Adventure Ventures.
// Firestore collection: adventureSpots
//
// Improvements over v1:
//  • Pricing tiers – rich cards with per-tier name, price, group size,
//    includes/excludes chip-tag editors, popular/available toggles.
//  • Gear Add-ons – preset quick-add grid (binoculars, tent, fishing rod …)
//    plus custom entry.  Each shows emoji, price, unit-picker, availability.
//  • Schedule Slots – date picked with showDatePicker calendar, start/end
//    time picked with showTimePicker (no manual text entry).
//  • Rental Partners – logo URL + items chip editor.
//  • Challenges / Dares – collapsible cards, proof-type chips, medal link.
//  • Achievement Medals – tier colour badge, secret toggle, points badge.
//  • Section headers show live item-count badge.
//  • Full edit-mode population from Firestore.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/tour_venture_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Preset quick-add gear items
// ─────────────────────────────────────────────────────────────────────────────

const _kPresetGear = [
  (emoji: '🔭', name: 'Binoculars'),
  (emoji: '🔭', name: 'Telescope'),
  (emoji: '⛺', name: 'Tent'),
  (emoji: '🪢', name: 'Rope'),
  (emoji: '🎣', name: 'Fishing Rod'),
  (emoji: '🎣', name: 'Fishing Bait & Hooks'),
  (emoji: '🧭', name: 'Compass'),
  (emoji: '🔦', name: 'Headlamp / Torch'),
  (emoji: '🥾', name: 'Hiking Boots'),
  (emoji: '🎒', name: 'Backpack'),
  (emoji: '🧥', name: 'Rain Jacket'),
  (emoji: '📷', name: 'Camera'),
  (emoji: '🛶', name: 'Life Jacket'),
  (emoji: '🧴', name: 'Insect Repellent'),
  (emoji: '🩹', name: 'First Aid Kit'),
];

IconData _seasonIconFor(PackageSeason season) {
  switch (season) {
    case PackageSeason.allYear:
      return Iconsax.calendar;
    case PackageSeason.spring:
      return Iconsax.tree;
    case PackageSeason.summer:
      return Iconsax.sun_fog;
    case PackageSeason.autumn:
      return Iconsax.cloud;
    case PackageSeason.winter:
      return Iconsax.cloud;
    case PackageSeason.monsoon:
      return Iconsax.cloud;
    case PackageSeason.preMonsoon:
      return Iconsax.sun_fog;
    case PackageSeason.postMonsoon:
      return Iconsax.calendar;
  }
}

IconData _medalIconFor(MedalTier tier) {
  switch (tier) {
    case MedalTier.bronze:
      return Iconsax.medal;
    case MedalTier.silver:
      return Iconsax.award;
    case MedalTier.gold:
      return Iconsax.cup;
    case MedalTier.platinum:
      return Iconsax.medal;
    case MedalTier.legendary:
      return Iconsax.cup;
  }
}

IconData _addonIconForName(String name) {
  final key = name.toLowerCase();
  if (key.contains('camera') || key.contains('lens')) return Iconsax.camera;
  if (key.contains('tent') || key.contains('jacket')) return Iconsax.home_2;
  if (key.contains('rope') || key.contains('compass')) return Iconsax.routing;
  if (key.contains('boot') || key.contains('backpack')) return Iconsax.bag_2;
  if (key.contains('lamp') || key.contains('torch')) return Iconsax.flash_1;
  if (key.contains('binocular') || key.contains('telescope')) {
    return Iconsax.eye;
  }
  return Iconsax.bag_2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen widget
// ─────────────────────────────────────────────────────────────────────────────

class AdminVentureFormScreen extends ConsumerStatefulWidget {
  final String? docId;
  const AdminVentureFormScreen({super.key, this.docId});

  @override
  ConsumerState<AdminVentureFormScreen> createState() =>
      _AdminVentureFormScreenState();
}

class _AdminVentureFormScreenState
    extends ConsumerState<AdminVentureFormScreen> {
  static const _collection = 'ventures';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;

  // ── 1. Basic ─────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<XFile> _newImages = [];
  final List<String> _existingUrls = [];
  bool _uploadingImages = false;

  // ── 2. Location ──────────────────────────────────────────────────────────
  final _locationCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _meetingPointCtrl = TextEditingController();
  PackageCategory _category = PackageCategory.hiking;
  DifficultyLevel _difficulty = DifficultyLevel.moderate;
  final Set<PackageSeason> _seasons = {PackageSeason.allYear};

  // ── 3. Timing & booking ──────────────────────────────────────────────────
  final _durationDaysCtrl = TextEditingController(text: '1');
  final _durationNightsCtrl = TextEditingController(text: '0');
  final _departureCtrl = TextEditingController(text: 'Daily');
  final _maxGroupCtrl = TextEditingController(text: '20');
  final _minAgeCtrl = TextEditingController(text: '0');
  final _advanceBookingCtrl = TextEditingController(text: '1');
  bool _instantBooking = true;
  bool _requiresApproval = false;

  // ── 4. Pricing tiers ─────────────────────────────────────────────────────
  final List<_TierEntry> _tiers = [];

  // ── 5. Add-ons ───────────────────────────────────────────────────────────
  final List<_AddonEntry> _addons = [];

  // ── 6. Rental partners ───────────────────────────────────────────────────
  final List<_RentalEntry> _rentals = [];

  // ── 7. Schedule slots ────────────────────────────────────────────────────
  final List<_SlotEntry> _slots = [];

  // ── 8. Challenges ────────────────────────────────────────────────────────
  final List<_ChallengeEntry> _challenges = [];

  // ── 9. Medals ────────────────────────────────────────────────────────────
  final List<_MedalEntry> _medals = [];

  // ── 10. Content ──────────────────────────────────────────────────────────
  final _highlightsCtrl = TextEditingController();
  final _expectCtrl = TextEditingController();
  final _bringCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();
  final _cancelCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _langCtrl = TextEditingController();

  // ── 11. Operator ─────────────────────────────────────────────────────────
  final _opNameCtrl = TextEditingController();
  final _opPhoneCtrl = TextEditingController();
  final _opEmailCtrl = TextEditingController();
  final _opWhatsappCtrl = TextEditingController();
  final _opWebsiteCtrl = TextEditingController();
  bool _opVerified = false;

  // ── 12. Flags ────────────────────────────────────────────────────────────
  bool _isFeatured = false;
  bool _isAvailable = true;
  String _status = 'active';
  static const _statuses = ['active', 'draft', 'suspended'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.docId != null;
    if (_isEditMode) _loadExisting();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _taglineCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _districtCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _meetingPointCtrl.dispose();
    _durationDaysCtrl.dispose();
    _durationNightsCtrl.dispose();
    _departureCtrl.dispose();
    _maxGroupCtrl.dispose();
    _minAgeCtrl.dispose();
    _advanceBookingCtrl.dispose();
    _highlightsCtrl.dispose();
    _expectCtrl.dispose();
    _bringCtrl.dispose();
    _safetyCtrl.dispose();
    _cancelCtrl.dispose();
    _tagsCtrl.dispose();
    _langCtrl.dispose();
    _opNameCtrl.dispose();
    _opPhoneCtrl.dispose();
    _opEmailCtrl.dispose();
    _opWhatsappCtrl.dispose();
    _opWebsiteCtrl.dispose();
    for (final t in _tiers) {
      t.dispose();
    }
    for (final a in _addons) {
      a.dispose();
    }
    for (final r in _rentals) {
      r.dispose();
    }
    for (final s in _slots) {
      s.dispose();
    }
    for (final c in _challenges) {
      c.dispose();
    }
    for (final m in _medals) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(widget.docId)
          .get();
      if (!snap.exists) return;
      final model = TourVentureModel.fromJson({...snap.data()!, 'id': snap.id});

      _titleCtrl.text = model.title;
      _taglineCtrl.text = model.tagline;
      _descCtrl.text = model.description;
      _locationCtrl.text = model.location;
      _districtCtrl.text = model.district;
      _latCtrl.text = model.latitude?.toString() ?? '';
      _lngCtrl.text = model.longitude?.toString() ?? '';
      _meetingPointCtrl.text = model.meetingPoint;
      _durationDaysCtrl.text =
          model.durationDays == 0 ? '' : model.durationDays.toString();
      _durationNightsCtrl.text =
          model.durationNights == 0 ? '' : model.durationNights.toString();
      _departureCtrl.text = model.departurePeriod;
      _maxGroupCtrl.text =
          model.maxGroupSize == 0 ? '' : model.maxGroupSize.toString();
      _minAgeCtrl.text =
          model.minAge == 0 ? '' : model.minAge.toString();
      _advanceBookingCtrl.text =
          model.advanceBookingDays == 0 ? '' : model.advanceBookingDays.toString();
      _category = model.category;
      _difficulty = model.difficulty;
      _seasons
        ..clear()
        ..addAll(
          model.seasons.isEmpty ? [PackageSeason.allYear] : model.seasons,
        );
      _instantBooking = model.instantBooking;
      _requiresApproval = model.requiresApproval;
      _isFeatured = model.isFeatured;
      _isAvailable = model.isAvailable;
      _status = _statuses.contains(model.status) ? model.status : 'active';
      _highlightsCtrl.text = model.highlights.join('\n');
      _expectCtrl.text = model.whatToExpect.join('\n');
      _bringCtrl.text = model.whatToBring.join('\n');
      _safetyCtrl.text = model.safetyNotes;
      _cancelCtrl.text = model.cancellationPolicy;
      _tagsCtrl.text = model.tags.join(', ');
      _langCtrl.text = model.languages.join(', ');
      _existingUrls.addAll(model.images);
      if (model.operator != null) {
        _opNameCtrl.text = model.operator!.name;
        _opPhoneCtrl.text = model.operator!.phone;
        _opEmailCtrl.text = model.operator!.email;
        _opWhatsappCtrl.text = model.operator!.whatsapp;
        _opWebsiteCtrl.text = model.operator!.website;
        _opVerified = model.operator!.isVerified;
      }
      for (final t in model.pricingTiers) {
        _tiers.add(_TierEntry.fromModel(t));
      }
      for (final a in model.addons) {
        _addons.add(_AddonEntry.fromModel(a));
      }
      for (final r in model.rentalPartners) {
        _rentals.add(_RentalEntry.fromModel(r));
      }
      for (final s in model.scheduleSlots) {
        _slots.add(_SlotEntry.fromModel(s));
      }
      for (final c in model.challenges) {
        _challenges.add(_ChallengeEntry.fromModel(c));
      }
      for (final m in model.medals) {
        _medals.add(_MedalEntry.fromModel(m));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked));
  }

  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];
    setState(() => _uploadingImages = true);
    final urls = <String>[];
    try {
      for (final xFile in _newImages) {
        final rawExt = xFile.path.split('.').last.toLowerCase();
        final ext = (rawExt == 'heic' || rawExt == 'heif') ? 'jpg' : rawExt;
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final name =
            'adventure_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$ext';
        final ref = FirebaseStorage.instance.ref().child(
          'admin_listings/ventures/$name',
        );
        final bytes = await xFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: mime));
        urls.add(await ref.getDownloadURL());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newUrls = await _uploadNewImages();
    final allImages = [..._existingUrls, ...newUrls];

    final tiersData = _tiers
        .where((t) => t.nameCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (e) => PricingTier(
            id: 'tier_${e.key}',
            name: e.value.nameCtrl.text.trim(),
            pricePerPerson: double.tryParse(e.value.priceCtrl.text.trim()) ?? 0,
            minPersons: int.tryParse(e.value.minCtrl.text.trim()) ?? 1,
            maxPersons: int.tryParse(e.value.maxCtrl.text.trim()) ?? 1,
            description: e.value.descCtrl.text.trim(),
            includes: e.value.includes.toList(),
            excludes: e.value.excludes.toList(),
            isPopular: e.value.isPopular,
            isAvailable: e.value.isAvailable,
          ).toJson(),
        )
        .toList();

    final startingPrice = tiersData.isEmpty
        ? 0.0
        : tiersData
              .map((t) => (t['pricePerPerson'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a < b ? a : b);

    final addonsData = _addons
        .where((a) => a.nameCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (e) => VentureAddon(
            id: 'addon_${e.key}',
            name: e.value.nameCtrl.text.trim(),
            emoji: e.value.emojiCtrl.text.trim().isNotEmpty
                ? e.value.emojiCtrl.text.trim()
                : '🎒',
            pricePerUnit: double.tryParse(e.value.priceCtrl.text.trim()) ?? 0,
            unit: e.value.unit,
            description: e.value.descCtrl.text.trim(),
            isAvailable: e.value.isAvailable,
          ).toJson(),
        )
        .toList();

    final rentalsData = _rentals
        .where((r) => r.nameCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (e) => RentalPartner(
            id: 'rental_${e.key}',
            name: e.value.nameCtrl.text.trim(),
            phone: e.value.phoneCtrl.text.trim(),
            whatsapp: e.value.whatsappCtrl.text.trim(),
            location: e.value.locationCtrl.text.trim(),
            logoUrl: e.value.logoCtrl.text.trim(),
            itemsAvailable: e.value.items.toList(),
            isVerified: e.value.isVerified,
          ).toJson(),
        )
        .toList();

    final slotsData = _slots
        .where((s) => s.labelCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) {
          final s = e.value;
          return ScheduleSlot(
            id: 'slot_${e.key}',
            label: s.labelCtrl.text.trim(),
            startTime: s.startTime != null
                ? '${s.startTime!.hour.toString().padLeft(2, '0')}:${s.startTime!.minute.toString().padLeft(2, '0')}'
                : '',
            endTime: s.endTime != null
                ? '${s.endTime!.hour.toString().padLeft(2, '0')}:${s.endTime!.minute.toString().padLeft(2, '0')}'
                : '',
            durationHours: int.tryParse(s.durationCtrl.text.trim()) ?? 0,
            maxGroupSize: int.tryParse(s.maxCtrl.text.trim()) ?? 10,
            spotsLeft: int.tryParse(s.spotsCtrl.text.trim()) ?? 0,
          ).toJson();
        })
        .toList();

    final challengesData = _challenges
        .where((c) => c.titleCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (e) => VentureChallenge(
            id: 'challenge_${e.key}',
            title: e.value.titleCtrl.text.trim(),
            description: e.value.descCtrl.text.trim(),
            instructions: e.value.instrCtrl.text.trim(),
            proofRequired: e.value.proofType,
            pointsOnComplete:
                int.tryParse(e.value.pointsCtrl.text.trim()) ?? 50,
            linkedMedalId: e.value.linkedMedalId,
            difficulty: e.value.difficulty,
            isOptional: e.value.isOptional,
            orderIndex: e.key,
          ).toJson(),
        )
        .toList();

    final totalPoints = challengesData.fold<int>(
      0,
      (runningTotal, challenge) =>
          runningTotal +
          ((challenge['pointsOnComplete'] as num?)?.toInt() ?? 0),
    );

    final medalsData = _medals
        .where((m) => m.nameCtrl.text.trim().isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map(
          (e) => VentureAchievementMedal(
            id: 'medal_${e.key}',
            name: e.value.nameCtrl.text.trim(),
            description: e.value.descCtrl.text.trim(),
            imageUrl: e.value.imageUrlCtrl.text.trim(),
            tier: e.value.tier,
            pointsAwarded: int.tryParse(e.value.pointsCtrl.text.trim()) ?? 10,
            isSecret: e.value.isSecret,
          ).toJson(),
        )
        .toList();

    Map<String, dynamic>? operatorData;
    if (_opNameCtrl.text.trim().isNotEmpty) {
      operatorData = OperatorInfo(
        name: _opNameCtrl.text.trim(),
        phone: _opPhoneCtrl.text.trim(),
        email: _opEmailCtrl.text.trim(),
        whatsapp: _opWhatsappCtrl.text.trim(),
        website: _opWebsiteCtrl.text.trim(),
        isVerified: _opVerified,
      ).toJson();
    }

    List<String> split(String value) => value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    List<String> splitNl(String value) => value
        .split('\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'tagline': _taglineCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'images': allImages,
      'location': _locationCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      if (_latCtrl.text.trim().isNotEmpty)
        'latitude': double.tryParse(_latCtrl.text.trim()),
      if (_lngCtrl.text.trim().isNotEmpty)
        'longitude': double.tryParse(_lngCtrl.text.trim()),
      'meetingPoint': _meetingPointCtrl.text.trim(),
      'category': _category.name,
      'difficulty': _difficulty.name,
      'seasons': _seasons.map((s) => s.name).toList(),
      'durationDays': int.tryParse(_durationDaysCtrl.text.trim()) ?? 1,
      'durationNights': int.tryParse(_durationNightsCtrl.text.trim()) ?? 0,
      'departurePeriod': _departureCtrl.text.trim(),
      'maxGroupSize': int.tryParse(_maxGroupCtrl.text.trim()) ?? 20,
      'minAge': int.tryParse(_minAgeCtrl.text.trim()) ?? 0,
      'advanceBookingDays': int.tryParse(_advanceBookingCtrl.text.trim()) ?? 1,
      'instantBooking': _instantBooking,
      'requiresApproval': _requiresApproval,
      'pricingTiers': tiersData,
      'startingPrice': startingPrice,
      'addons': addonsData,
      'rentalPartners': rentalsData,
      'scheduleSlots': slotsData,
      'challenges': challengesData,
      'medals': medalsData,
      'totalPointsPossible': totalPoints,
      'highlights': splitNl(_highlightsCtrl.text),
      'whatToExpect': splitNl(_expectCtrl.text),
      'whatToBring': splitNl(_bringCtrl.text),
      'safetyNotes': _safetyCtrl.text.trim(),
      'cancellationPolicy': _cancelCtrl.text.trim(),
      'tags': split(_tagsCtrl.text),
      'languages': split(_langCtrl.text),
      'operator': operatorData,
      'isFeatured': _isFeatured,
      'isAvailable': _isAvailable,
      'status': _status,
    };

    final notifier = ref.read(adminListingNotifierProvider.notifier);
    final ok = _isEditMode
        ? await notifier.updateListing(_collection, widget.docId!, data)
        : await notifier.createListing(_collection, data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                _isEditMode
                    ? 'Venture updated successfully.'
                    : 'Venture created successfully.',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
    } else {
      final errMsg =
          ref.read(adminListingNotifierProvider).message ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Failed to save: $errMsg')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: col.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Venture Editor',
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _isEditMode
                  ? 'Update an existing venture'
                  : 'Create a new venture',
              style: TextStyle(color: col.textSecondary, fontSize: 11),
            ),
          ],
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
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: col.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: col.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.note_text,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'Editing venture details'
                                  : 'Creating a new venture',
                              style: TextStyle(
                                color: col.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Add and edit now use the same editor for structure, pricing, schedule, challenges, and operator info.',
                              style: TextStyle(
                                color: col.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _section('Basic Info', Iconsax.note_text, _buildBasicInfo()),
                _section(
                  'Location & Category',
                  Iconsax.location,
                  _buildLocation(),
                ),
                _section('Timing & Booking', Iconsax.clock, _buildTiming()),
                _sectionWithCount(
                  'Pricing Packages',
                  Iconsax.card,
                  _tiers.length,
                  _buildPricingTiers(),
                ),
                _sectionWithCount(
                  'Gear Add-ons',
                  Iconsax.bag_2,
                  _addons.length,
                  _buildAddons(),
                ),
                _sectionWithCount(
                  'Rental Partners',
                  Iconsax.building,
                  _rentals.length,
                  _buildRentals(),
                ),
                _sectionWithCount(
                  'Schedule Slots',
                  Iconsax.calendar,
                  _slots.length,
                  _buildSlots(),
                ),
                _sectionWithCount(
                  'Challenges / Dares',
                  Iconsax.flag,
                  _challenges.length,
                  _buildChallenges(),
                ),
                _sectionWithCount(
                  'Achievement Medals',
                  Iconsax.medal,
                  _medals.length,
                  _buildMedals(),
                ),
                _section(
                  'Content & Info',
                  Iconsax.document_text,
                  _buildContent(),
                ),
                _section('Guide / Operator', Iconsax.user, _buildOperator()),
                _section('Settings', Iconsax.setting_2, _buildSettings()),
              ],
            ),
          ),
          if (_isLoading && _isEditMode)
            Positioned.fill(
              child: Container(
                color: col.bg.withValues(alpha: 0.72),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String heading, IconData icon, Widget child) =>
      _sectionWithCount(heading, icon, -1, child);

  Widget _sectionWithCount(
    String heading,
    IconData icon,
    int count,
    Widget child,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (count >= 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _VCard(child: child),
      ],
    );
  }

  // ─── 1. Basic info ─────────────────────────────────────────────────────────

  Widget _buildBasicInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Title *'),
      _field(
        _titleCtrl,
        hint: 'e.g. Murlen Bird Watching Trail',
        validator: (v) => (v?.isEmpty ?? true) ? 'Title is required' : null,
      ),
      _gap(),
      _lbl('Tagline'),
      _field(
        _taglineCtrl,
        hint: 'Short hook — e.g. Spot 300+ endemic species at dawn',
      ),
      _gap(),
      _lbl('Description'),
      _field(_descCtrl, hint: 'Full description…', maxLines: 5),
      _gap(),
      _lbl('Photos'),
      _ImagePickerWidget(
        existingUrls: _existingUrls,
        newImages: _newImages,
        uploading: _uploadingImages,
        onPick: _pickImages,
        onRemoveExisting: (i) => setState(() => _existingUrls.removeAt(i)),
        onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
      ),
    ],
  );

  // ─── 2. Location ──────────────────────────────────────────────────────────

  Widget _buildLocation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Location Name'),
      _field(_locationCtrl, hint: 'e.g. Phawngpui Blue Mountain'),
      _gap(),
      _lbl('District'),
      _field(_districtCtrl, hint: 'e.g. Lawngtlai'),
      _gap(),
      _lbl('Meeting / Start Point'),
      _field(_meetingPointCtrl, hint: 'e.g. Phawngpui Base Camp gate'),
      _gap(),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Latitude'),
                _field(
                  _latCtrl,
                  hint: '22.82',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Longitude'),
                _field(
                  _lngCtrl,
                  hint: '92.67',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      _gap(),
      _lbl('Category'),
      _DropdownField<PackageCategory>(
        value: _category,
        items: PackageCategory.values,
        labelOf: (c) => c.label,
        onChanged: (v) => setState(() => _category = v!),
      ),
      _gap(),
      _lbl('Difficulty'),
      Row(
        children: DifficultyLevel.values.map((d) {
          final sel = _difficulty == d;
          final color = Color(d.colorHex);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: 0.15)
                      : context.col.surfaceElevated,
                  border: Border.all(
                    color: sel ? color : context.col.border,
                    width: sel ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      d.label,
                      style: TextStyle(
                        color: sel ? color : context.col.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      _gap(),
      _lbl('Best Seasons'),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: PackageSeason.values.map((s) {
          final sel = _seasons.contains(s);
          return FilterChip(
            avatar: Icon(
              _seasonIconFor(s),
              size: 14,
              color: sel ? AppColors.primary : context.col.textMuted,
            ),
            label: Text(s.label),
            selected: sel,
            onSelected: (v) => setState(() {
              if (v) {
                _seasons.add(s);
              } else if (_seasons.length > 1) {
                _seasons.remove(s);
              }
            }),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: sel ? AppColors.primary : context.col.textSecondary,
              fontSize: 11,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        }).toList(),
      ),
    ],
  );

  // ─── 3. Timing ─────────────────────────────────────────────────────────────

  Widget _buildTiming() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: _numBox('Days', _durationDaysCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _numBox('Nights', _durationNightsCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _numBox('Max Group', _maxGroupCtrl)),
        ],
      ),
      _gap(),
      Row(
        children: [
          Expanded(child: _numBox('Min Age', _minAgeCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _numBox('Advance Booking Days', _advanceBookingCtrl)),
        ],
      ),
      _gap(),
      _lbl('Departure Frequency'),
      _field(_departureCtrl, hint: 'Daily  /  Weekends  /  On request'),
      _gap(),
      _SwitchRow(
        label: 'Instant Booking',
        subtitle: 'Confirmed without admin approval',
        value: _instantBooking,
        onChanged: (v) => setState(() => _instantBooking = v),
      ),
      const SizedBox(height: 4),
      _SwitchRow(
        label: 'Requires Approval',
        subtitle: 'Admin reviews each registration',
        value: _requiresApproval,
        onChanged: (v) => setState(() => _requiresApproval = v),
      ),
    ],
  );

  // ─── 4. Pricing packages ───────────────────────────────────────────────────

  Widget _buildPricingTiers() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_tiers.isEmpty)
        _emptyHint(
          'No pricing packages yet.\nTap below to add your first one.',
        ),
      ..._tiers.asMap().entries.map(
        (e) => _TierCard(
          index: e.key,
          entry: e.value,
          onRemove: () => setState(() {
            e.value.dispose();
            _tiers.removeAt(e.key);
          }),
          onChanged: () => setState(() {}),
        ),
      ),
      const SizedBox(height: 10),
      _AddBtn(
        label: 'Add Pricing Package',
        icon: Icons.add_card_outlined,
        onTap: () => setState(() => _tiers.add(_TierEntry())),
      ),
    ],
  );

  // ─── 5. Add-ons ────────────────────────────────────────────────────────────

  Widget _buildAddons() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Quick-add preset grid
      _lbl('Quick-add common gear'),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _kPresetGear.map((g) {
          final already = _addons.any(
            (a) => a.nameCtrl.text.toLowerCase() == g.name.toLowerCase(),
          );
          return GestureDetector(
            onTap: already
                ? null
                : () {
                    final entry = _AddonEntry();
                    entry.emojiCtrl.text = g.emoji;
                    entry.nameCtrl.text = g.name;
                    setState(() => _addons.add(entry));
                  },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: already ? 0.35 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: already
                      ? context.col.surfaceElevated
                      : AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: already
                        ? context.col.border
                        : AppColors.primary.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  g.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: already ? context.col.textMuted : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      if (_addons.isNotEmpty) ...[
        _lbl('Added add-ons'),
        ..._addons.asMap().entries.map(
          (e) => _AddonCard(
            index: e.key,
            entry: e.value,
            onRemove: () => setState(() {
              e.value.dispose();
              _addons.removeAt(e.key);
            }),
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 10),
      ],
      _AddBtn(
        label: 'Add Custom Gear / Add-on',
        icon: Icons.backpack_outlined,
        onTap: () => setState(() => _addons.add(_AddonEntry())),
      ),
    ],
  );

  // ─── 6. Rental partners ────────────────────────────────────────────────────

  Widget _buildRentals() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_rentals.isEmpty)
        _emptyHint('Add local shops or guides that rent gear to participants.'),
      ..._rentals.asMap().entries.map(
        (e) => _RentalCard(
          index: e.key,
          entry: e.value,
          onRemove: () => setState(() {
            e.value.dispose();
            _rentals.removeAt(e.key);
          }),
        ),
      ),
      const SizedBox(height: 10),
      _AddBtn(
        label: 'Add Rental Partner',
        icon: Icons.store_outlined,
        onTap: () => setState(() => _rentals.add(_RentalEntry())),
      ),
    ],
  );

  // ─── 7. Schedule slots ─────────────────────────────────────────────────────

  Widget _buildSlots() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_slots.isEmpty)
        _emptyHint(
          'Define daily or weekly session slots with start/end times.',
        ),
      ..._slots.asMap().entries.map(
        (e) => _SlotCard(
          index: e.key,
          entry: e.value,
          onRemove: () => setState(() {
            e.value.dispose();
            _slots.removeAt(e.key);
          }),
          onChanged: () => setState(() {}),
        ),
      ),
      const SizedBox(height: 10),
      _AddBtn(
        label: 'Add Schedule Slot',
        icon: Icons.schedule_outlined,
        onTap: () => setState(() => _slots.add(_SlotEntry())),
      ),
    ],
  );

  // ─── 8. Challenges ─────────────────────────────────────────────────────────

  Widget _buildChallenges() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_challenges.isEmpty)
        _emptyHint(
          'Challenges are objectives or dares participants must\ncomplete to earn medals and points.',
        ),
      ..._challenges.asMap().entries.map(
        (e) => _ChallengeCard(
          index: e.key,
          entry: e.value,
          medalOptions: _medals
              .asMap()
              .entries
              .map(
                (me) => (
                  id: 'medal_${me.key}',
                  name: me.value.nameCtrl.text.isNotEmpty
                      ? me.value.nameCtrl.text
                      : 'Medal ${me.key + 1}',
                  icon: _medalIconFor(me.value.tier),
                ),
              )
              .toList(),
          onRemove: () => setState(() {
            e.value.dispose();
            _challenges.removeAt(e.key);
          }),
          onChanged: () => setState(() {}),
        ),
      ),
      const SizedBox(height: 10),
      _AddBtn(
        label: 'Add Challenge / Dare',
        icon: Icons.flag_outlined,
        onTap: () => setState(() => _challenges.add(_ChallengeEntry())),
      ),
    ],
  );

  // ─── 9. Medals ─────────────────────────────────────────────────────────────

  Widget _buildMedals() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_medals.isEmpty)
        _emptyHint('Create achievement medals. Link them to challenges above.'),
      ..._medals.asMap().entries.map(
        (e) => _MedalCard(
          index: e.key,
          entry: e.value,
          onRemove: () => setState(() {
            e.value.dispose();
            _medals.removeAt(e.key);
          }),
          onChanged: () => setState(() {}),
        ),
      ),
      const SizedBox(height: 10),
      _AddBtn(
        label: 'Add Achievement Medal',
        icon: Icons.emoji_events_outlined,
        onTap: () => setState(() => _medals.add(_MedalEntry())),
      ),
    ],
  );

  // ─── 10. Content ───────────────────────────────────────────────────────────

  Widget _buildContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Highlights (one per line)'),
      _field(
        _highlightsCtrl,
        hint: 'Spot 300+ bird species\nWalk through ancient bamboo groves',
        maxLines: 4,
      ),
      _gap(),
      _lbl('What to Expect (one per line)'),
      _field(
        _expectCtrl,
        hint: '5-hour guided trail\nBreakfast at camp included',
        maxLines: 4,
      ),
      _gap(),
      _lbl('What to Bring (one per line)'),
      _field(
        _bringCtrl,
        hint: 'Binoculars\nWater bottle (2L)\nComfortable trekking shoes',
        maxLines: 4,
      ),
      _gap(),
      _lbl('Safety Notes'),
      _field(
        _safetyCtrl,
        hint: 'Stay on marked trails. Inform your guide if…',
        maxLines: 3,
      ),
      _gap(),
      _lbl('Cancellation Policy'),
      _field(
        _cancelCtrl,
        hint: 'Full refund if cancelled 48 hours before…',
        maxLines: 2,
      ),
      _gap(),
      _lbl('Languages Spoken (comma-separated)'),
      _field(_langCtrl, hint: 'English, Mizo, Hindi'),
      _gap(),
      _lbl('Search Tags (comma-separated)'),
      _field(
        _tagsCtrl,
        hint: 'birding, wildlife, sunrise, photography, nature',
      ),
    ],
  );

  // ─── 11. Operator ──────────────────────────────────────────────────────────

  Widget _buildOperator() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Guide / Operator Name'),
      _field(_opNameCtrl, hint: 'e.g. Mizoram Bird Tours'),
      _gap(),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Phone'),
                _field(
                  _opPhoneCtrl,
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('WhatsApp'),
                _field(
                  _opWhatsappCtrl,
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ],
      ),
      _gap(),
      _lbl('Email'),
      _field(
        _opEmailCtrl,
        hint: 'guide@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      _gap(),
      _lbl('Website'),
      _field(
        _opWebsiteCtrl,
        hint: 'https://mizorambirds.com',
        keyboardType: TextInputType.url,
      ),
      _gap(),
      _SwitchRow(
        label: 'Verified Operator',
        subtitle: 'Shows a verified badge on the client app',
        value: _opVerified,
        onChanged: (v) => setState(() => _opVerified = v),
      ),
    ],
  );

  // ─── 12. Settings ──────────────────────────────────────────────────────────

  Widget _buildSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl('Publish Status'),
      Row(
        children: _statuses.map((s) {
          final sel = _status == s;
          final color = s == 'active'
              ? const Color(0xFF22C55E)
              : s == 'draft'
              ? const Color(0xFFF59E0B)
              : AppColors.error;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _status = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: 0.15)
                      : context.col.surfaceElevated,
                  border: Border.all(
                    color: sel ? color : context.col.border,
                    width: sel ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s[0].toUpperCase() + s.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: sel ? color : context.col.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      _gap(),
      _SwitchRow(
        label: 'Featured',
        subtitle: 'Pin to home screen featured banner',
        value: _isFeatured,
        onChanged: (v) => setState(() => _isFeatured = v),
      ),
      const SizedBox(height: 4),
      _SwitchRow(
        label: 'Open for Registrations',
        subtitle: 'Allow participants to sign up',
        value: _isAvailable,
        onChanged: (v) => setState(() => _isAvailable = v),
      ),
    ],
  );

  // ─── Small helpers ─────────────────────────────────────────────────────────

  Widget _lbl(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        color: context.col.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _gap() => const SizedBox(height: 14);

  Widget _numBox(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _lbl(label),
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.col.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.col.surfaceElevated,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.col.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.col.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    ],
  );

  Widget _field(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    style: TextStyle(color: context.col.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.col.textMuted, fontSize: 13),
      filled: true,
      fillColor: context.col.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.col.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.col.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );

  Widget _emptyHint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: TextStyle(color: context.col.textMuted, fontSize: 13, height: 1.5),
      textAlign: TextAlign.center,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry data models  (hold mutable state for each dynamic list row)
// ─────────────────────────────────────────────────────────────────────────────

class _TierEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final minCtrl = TextEditingController(text: '1');
  final maxCtrl = TextEditingController(text: '10');
  final descCtrl = TextEditingController();
  // includes / excludes stored as chip lists
  final List<String> includes = [];
  final List<String> excludes = [];
  bool isPopular = false;
  bool isAvailable = true;

  _TierEntry();

  factory _TierEntry.fromModel(PricingTier t) {
    final e = _TierEntry();
    e.nameCtrl.text = t.name;
    e.priceCtrl.text = t.pricePerPerson.toStringAsFixed(0);
    e.minCtrl.text = t.minPersons.toString();
    e.maxCtrl.text = t.maxPersons.toString();
    e.descCtrl.text = t.description;
    e.includes.addAll(t.includes);
    e.excludes.addAll(t.excludes);
    e.isPopular = t.isPopular;
    e.isAvailable = t.isAvailable;
    return e;
  }

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    minCtrl.dispose();
    maxCtrl.dispose();
    descCtrl.dispose();
  }
}

class _AddonEntry {
  final emojiCtrl = TextEditingController(text: '🎒');
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  String unit = 'per person';
  bool isAvailable = true;

  static const units = [
    'per person',
    'per day',
    'per set',
    'per item',
    'per trip',
  ];

  _AddonEntry();

  factory _AddonEntry.fromModel(VentureAddon a) {
    final e = _AddonEntry();
    e.emojiCtrl.text = a.emoji;
    e.nameCtrl.text = a.name;
    e.priceCtrl.text = a.pricePerUnit.toStringAsFixed(0);
    e.descCtrl.text = a.description;
    e.unit = a.unit;
    e.isAvailable = a.isAvailable;
    return e;
  }

  void dispose() {
    emojiCtrl.dispose();
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
  }
}

class _RentalEntry {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final logoCtrl = TextEditingController();
  // items stored as chip list
  final List<String> items = [];
  bool isVerified = false;

  _RentalEntry();

  factory _RentalEntry.fromModel(RentalPartner r) {
    final e = _RentalEntry();
    e.nameCtrl.text = r.name;
    e.phoneCtrl.text = r.phone;
    e.whatsappCtrl.text = r.whatsapp;
    e.locationCtrl.text = r.location;
    e.logoCtrl.text = r.logoUrl;
    e.items.addAll(r.itemsAvailable);
    e.isVerified = r.isVerified;
    return e;
  }

  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    whatsappCtrl.dispose();
    locationCtrl.dispose();
    logoCtrl.dispose();
  }
}

class _SlotEntry {
  final labelCtrl = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final durationCtrl = TextEditingController();
  final maxCtrl = TextEditingController(text: '10');
  final spotsCtrl = TextEditingController(text: '10');

  _SlotEntry();

  factory _SlotEntry.fromModel(ScheduleSlot s) {
    final e = _SlotEntry();
    e.labelCtrl.text = s.label;
    e.durationCtrl.text = s.durationHours.toString();
    e.maxCtrl.text = s.maxGroupSize.toString();
    e.spotsCtrl.text = s.spotsLeft.toString();
    // parse HH:mm
    TimeOfDay? parse(String t) {
      final parts = t.split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    e.startTime = parse(s.startTime);
    e.endTime = parse(s.endTime);
    return e;
  }

  void dispose() {
    labelCtrl.dispose();
    durationCtrl.dispose();
    maxCtrl.dispose();
    spotsCtrl.dispose();
  }
}

class _ChallengeEntry {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final instrCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '50');
  String proofType = 'Photo'; // chip selection
  DifficultyLevel difficulty = DifficultyLevel.moderate;
  bool isOptional = true;
  String linkedMedalId = '';

  static const proofTypes = [
    'Photo',
    'Video',
    'Screenshot',
    'Check-in',
    'Self-report',
  ];

  _ChallengeEntry();

  factory _ChallengeEntry.fromModel(VentureChallenge c) {
    final e = _ChallengeEntry();
    e.titleCtrl.text = c.title;
    e.descCtrl.text = c.description;
    e.instrCtrl.text = c.instructions;
    e.pointsCtrl.text = c.pointsOnComplete.toString();
    e.proofType = _ChallengeEntry.proofTypes.contains(c.proofRequired)
        ? c.proofRequired
        : 'Photo';
    e.difficulty = c.difficulty;
    e.isOptional = c.isOptional;
    e.linkedMedalId = c.linkedMedalId;
    return e;
  }

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    instrCtrl.dispose();
    pointsCtrl.dispose();
  }
}

class _MedalEntry {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final imageUrlCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '100');
  MedalTier tier = MedalTier.bronze;
  bool isSecret = false;

  _MedalEntry();

  factory _MedalEntry.fromModel(VentureAchievementMedal m) {
    final e = _MedalEntry();
    e.nameCtrl.text = m.name;
    e.descCtrl.text = m.description;
    e.imageUrlCtrl.text = m.imageUrl;
    e.pointsCtrl.text = m.pointsAwarded.toString();
    e.tier = m.tier;
    e.isSecret = m.isSecret;
    return e;
  }

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    imageUrlCtrl.dispose();
    pointsCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dynamic card widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── Pricing Tier card ────────────────────────────────────────────────────────

class _TierCard extends StatefulWidget {
  final int index;
  final _TierEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _TierCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  @override
  State<_TierCard> createState() => _TierCardState();
}

class _TierCardState extends State<_TierCard> {
  final _inclCtrl = TextEditingController();
  final _exclCtrl = TextEditingController();

  @override
  void dispose() {
    _inclCtrl.dispose();
    _exclCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return _ItemCard(
      leadingIcon: Iconsax.card,
      title: e.nameCtrl.text.isEmpty
          ? 'Package ${widget.index + 1}'
          : e.nameCtrl.text,
      badge: e.isPopular ? '⭐ Popular' : null,
      badgeColor: AppColors.primary,
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + price row
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.nameCtrl,
                  hint: 'Package name',
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: _SF(
                  ctrl: e.priceCtrl,
                  hint: '₹ / person',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Group size
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.minCtrl,
                  hint: 'Min persons',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SF(
                  ctrl: e.maxCtrl,
                  hint: 'Max persons',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          _SF(ctrl: e.descCtrl, hint: 'Package description', maxLines: 2),
          const SizedBox(height: 10),
          // Includes chips
          _ChipListEditor(
            label: 'Included',
            items: e.includes,
            chipColor: const Color(0xFF22C55E),
            hint: 'e.g. Breakfast',
            onAdd: (v) => setState(() => e.includes.add(v)),
            onRemove: (i) => setState(() => e.includes.removeAt(i)),
          ),
          const SizedBox(height: 8),
          // Excludes chips
          _ChipListEditor(
            label: 'Excluded',
            items: e.excludes,
            chipColor: AppColors.error,
            hint: 'e.g. Transport',
            onAdd: (v) => setState(() => e.excludes.add(v)),
            onRemove: (i) => setState(() => e.excludes.removeAt(i)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniSwitch(
                'Popular',
                e.isPopular,
                (v) => setState(() => e.isPopular = v),
              ),
              const SizedBox(width: 16),
              _miniSwitch(
                'Available',
                e.isAvailable,
                (v) => setState(() => e.isAvailable = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add-on card ──────────────────────────────────────────────────────────────

class _AddonCard extends StatefulWidget {
  final int index;
  final _AddonEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _AddonCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  @override
  State<_AddonCard> createState() => _AddonCardState();
}

class _AddonCardState extends State<_AddonCard> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final title = e.nameCtrl.text.isEmpty
        ? 'Add-on ${widget.index + 1}'
        : e.nameCtrl.text;
    return _ItemCard(
      leadingIcon: _addonIconForName(e.nameCtrl.text),
      title: title,
      badge: e.isAvailable ? null : 'Unavailable',
      badgeColor: AppColors.error,
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _addonIconForName(e.nameCtrl.text),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SF(
                  ctrl: e.nameCtrl,
                  hint: 'Item name',
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.priceCtrl,
                  hint: '₹ price',
                  keyboardType: TextInputType.number,
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: e.unit,
                  decoration: _sfDeco(context, 'Per unit'),
                  items: _AddonEntry.units
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(u, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => e.unit = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SF(ctrl: e.descCtrl, hint: 'Short description (optional)'),
          const SizedBox(height: 8),
          _miniSwitch(
            'Available',
            e.isAvailable,
            (v) => setState(() => e.isAvailable = v),
          ),
        ],
      ),
    );
  }
}

// ── Rental partner card ──────────────────────────────────────────────────────

class _RentalCard extends StatefulWidget {
  final int index;
  final _RentalEntry entry;
  final VoidCallback onRemove;
  const _RentalCard({
    required this.index,
    required this.entry,
    required this.onRemove,
  });
  @override
  State<_RentalCard> createState() => _RentalCardState();
}

class _RentalCardState extends State<_RentalCard> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return _ItemCard(
      leadingIcon: Iconsax.building,
      title: e.nameCtrl.text.isEmpty
          ? 'Partner ${widget.index + 1}'
          : e.nameCtrl.text,
      badge: e.isVerified ? '✓ Verified' : null,
      badgeColor: const Color(0xFF22C55E),
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SF(
            ctrl: e.nameCtrl,
            hint: 'Shop / guide name',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.phoneCtrl,
                  hint: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SF(
                  ctrl: e.whatsappCtrl,
                  hint: 'WhatsApp',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SF(ctrl: e.locationCtrl, hint: 'Address / Location'),
          const SizedBox(height: 8),
          _SF(ctrl: e.logoCtrl, hint: 'Logo image URL (optional)'),
          const SizedBox(height: 10),
          _ChipListEditor(
            label: 'Items available for rent',
            items: e.items,
            chipColor: AppColors.primary,
            hint: 'e.g. Tent',
            onAdd: (v) => setState(() => e.items.add(v)),
            onRemove: (i) => setState(() => e.items.removeAt(i)),
          ),
          const SizedBox(height: 8),
          _miniSwitch(
            'Verified Partner',
            e.isVerified,
            (v) => setState(() => e.isVerified = v),
          ),
        ],
      ),
    );
  }
}

// ── Schedule slot card ───────────────────────────────────────────────────────

class _SlotCard extends StatefulWidget {
  final int index;
  final _SlotEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _SlotCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> {
  String _fmt(TimeOfDay? t) => t == null
      ? 'Pick time'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (widget.entry.startTime ?? const TimeOfDay(hour: 6, minute: 0))
        : (widget.entry.endTime ?? const TimeOfDay(hour: 12, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          widget.entry.startTime = picked;
        } else {
          widget.entry.endTime = picked;
        }
        // auto-compute duration
        if (widget.entry.startTime != null && widget.entry.endTime != null) {
          final startMin =
              widget.entry.startTime!.hour * 60 +
              widget.entry.startTime!.minute;
          final endMin =
              widget.entry.endTime!.hour * 60 + widget.entry.endTime!.minute;
          final diff = endMin - startMin;
          if (diff > 0) {
            widget.entry.durationCtrl.text = (diff / 60)
                .toStringAsFixed(1)
                .replaceAll('.0', '');
          }
        }
        widget.onChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return _ItemCard(
      leadingIcon: Iconsax.calendar,
      title: e.labelCtrl.text.isEmpty
          ? 'Slot ${widget.index + 1}'
          : e.labelCtrl.text,
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SF(
            ctrl: e.labelCtrl,
            hint: 'Label (e.g. Morning Session)',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Start time picker
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: _TimeTile(
                    label: 'Start Time',
                    value: _fmt(e.startTime),
                    isSet: e.startTime != null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // End time picker
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: _TimeTile(
                    label: 'End Time',
                    value: _fmt(e.endTime),
                    isSet: e.endTime != null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.durationCtrl,
                  hint: 'Duration (hrs)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SF(
                  ctrl: e.maxCtrl,
                  hint: 'Max group',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SF(
                  ctrl: e.spotsCtrl,
                  hint: 'Spots left',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Challenge card ───────────────────────────────────────────────────────────

class _ChallengeCard extends StatefulWidget {
  final int index;
  final _ChallengeEntry entry;
  final List<({String id, String name, IconData icon})> medalOptions;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _ChallengeCard({
    required this.index,
    required this.entry,
    required this.medalOptions,
    required this.onRemove,
    required this.onChanged,
  });
  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final col = context.col;
    final allMedals = [
      (id: '', name: 'None', icon: Iconsax.slash),
      ...widget.medalOptions,
    ];
    final validLinked = allMedals.any((m) => m.id == e.linkedMedalId)
        ? e.linkedMedalId
        : '';

    return _ItemCard(
      leadingIcon: Iconsax.flag,
      title: e.titleCtrl.text.isEmpty
          ? 'Challenge ${widget.index + 1}'
          : e.titleCtrl.text,
      badge: '${e.pointsCtrl.text.isNotEmpty ? e.pointsCtrl.text : '50'} pts',
      badgeColor: AppColors.primary,
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SF(
            ctrl: e.titleCtrl,
            hint: 'Challenge title (e.g. Spot 5 species before sunrise)',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 8),
          _SF(ctrl: e.descCtrl, hint: 'Description', maxLines: 2),
          const SizedBox(height: 8),
          _SF(
            ctrl: e.instrCtrl,
            hint: 'Step-by-step instructions',
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          // Proof type chips
          _lblSmall('Proof Required', col),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: _ChallengeEntry.proofTypes.map((p) {
              final sel = e.proofType == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 11)),
                selected: sel,
                onSelected: (v) {
                  if (v) setState(() => e.proofType = p);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: sel ? AppColors.primary : col.textSecondary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Points + difficulty
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.pointsCtrl,
                  hint: 'Points on complete',
                  keyboardType: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<DifficultyLevel>(
                  initialValue: e.difficulty,
                  decoration: _sfDeco(context, 'Difficulty'),
                  items: DifficultyLevel.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(d.colorHex),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => e.difficulty = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Medal link
          DropdownButtonFormField<String>(
            initialValue: validLinked,
            decoration: _sfDeco(context, 'Award Medal (optional)'),
            items: allMedals
                .map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Row(
                      children: [
                        Icon(m.icon, size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => e.linkedMedalId = v ?? ''),
          ),
          const SizedBox(height: 8),
          _miniSwitch(
            'Optional / Bonus challenge',
            e.isOptional,
            (v) => setState(() => e.isOptional = v),
          ),
        ],
      ),
    );
  }
}

// ── Medal card ───────────────────────────────────────────────────────────────

class _MedalCard extends StatefulWidget {
  final int index;
  final _MedalEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _MedalCard({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  @override
  State<_MedalCard> createState() => _MedalCardState();
}

class _MedalCardState extends State<_MedalCard> {
  bool _uploadingBadge = false;
  XFile? _pickedBadge;

  Future<void> _uploadBadgeImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _pickedBadge = picked;
      _uploadingBadge = true;
    });
    try {
      final ext = picked.path.split('.').last.toLowerCase();
      final safeExt = (ext == 'heic' || ext == 'heif') ? 'jpg' : ext;
      final mime = safeExt == 'png' ? 'image/png' : 'image/jpeg';
      final name =
          'medal_badge_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final ref = FirebaseStorage.instance.ref().child(
        'admin_listings/medals/$name',
      );
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() {
          widget.entry.imageUrlCtrl.text = url;
          _uploadingBadge = false;
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingBadge = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Badge upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final tierColor = Color(e.tier.colorHex);
    return _ItemCard(
      leadingIcon: _medalIconFor(e.tier),
      leadingIconColor: tierColor,
      title: e.nameCtrl.text.isEmpty
          ? 'Medal ${widget.index + 1}'
          : e.nameCtrl.text,
      badge: e.tier.label,
      badgeColor: tierColor,
      onRemove: widget.onRemove,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + tier
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.nameCtrl,
                  hint: 'Medal name (e.g. Early Bird)',
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<MedalTier>(
                  initialValue: e.tier,
                  decoration: _sfDeco(context, 'Tier'),
                  items: MedalTier.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(
                                _medalIconFor(t),
                                size: 15,
                                color: Color(t.colorHex),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(t.colorHex),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => e.tier = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SF(ctrl: e.descCtrl, hint: 'How to earn (description)', maxLines: 2),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SF(
                  ctrl: e.pointsCtrl,
                  hint: 'Points awarded',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BadgeImagePicker(
                  entry: e,
                  uploading: _uploadingBadge,
                  pickedFile: _pickedBadge,
                  onTap: _uploadBadgeImage,
                  onClear: () => setState(() {
                    e.imageUrlCtrl.clear();
                    _pickedBadge = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _miniSwitch(
            'Hidden until earned',
            e.isSecret,
            (v) => setState(() => e.isSecret = v),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge image picker
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeImagePicker extends StatelessWidget {
  final _MedalEntry entry;
  final bool uploading;
  final XFile? pickedFile;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _BadgeImagePicker({
    required this.entry,
    required this.uploading,
    required this.pickedFile,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final hasUrl = entry.imageUrlCtrl.text.trim().isNotEmpty;
    final hasLocal = pickedFile != null;
    final hasAny = hasUrl || hasLocal || uploading;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: col.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasAny ? col.primary.withValues(alpha: 0.5) : col.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: uploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : hasLocal
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(pickedFile!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholder(col),
                  ),
                  Positioned(top: 2, right: 2, child: _clearBtn(col)),
                ],
              )
            : hasUrl
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    entry.imageUrlCtrl.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholder(col),
                  ),
                  Positioned(top: 2, right: 2, child: _clearBtn(col)),
                ],
              )
            : _placeholder(col),
      ),
    );
  }

  Widget _placeholder(AppColorScheme col) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Iconsax.image, size: 18, color: col.textSecondary),
      const SizedBox(width: 4),
      Text('Badge', style: TextStyle(fontSize: 12, color: col.textSecondary)),
    ],
  );

  Widget _clearBtn(AppColorScheme col) => GestureDetector(
    onTap: onClear,
    child: Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(Icons.close, size: 12, color: Colors.white),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable shared widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Card container for every dynamic list item.
class _ItemCard extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Widget child;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.title,
    required this.child,
    required this.onRemove,
    this.badge,
    this.badgeColor,
    this.leadingIcon,
    this.leadingIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: col.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (leadingIconColor ?? AppColors.primary).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    leadingIcon,
                    size: 15,
                    color: leadingIconColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primary).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Iconsax.trash,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Time picker display tile.
class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  const _TimeTile({
    required this.label,
    required this.value,
    required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isSet
            ? AppColors.primary.withValues(alpha: 0.1)
            : col.surfaceElevated,
        border: Border.all(
          color: isSet ? AppColors.primary.withValues(alpha: 0.5) : col.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.clock,
            size: 15,
            color: isSet ? AppColors.primary : col.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: col.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isSet ? AppColors.primary : col.textSecondary,
                    fontSize: 13,
                    fontWeight: isSet ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip list editor (add tag + tap × to remove).
class _ChipListEditor extends StatefulWidget {
  final String label;
  final List<String> items;
  final Color chipColor;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  const _ChipListEditor({
    required this.label,
    required this.items,
    required this.chipColor,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<_ChipListEditor> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    widget.onAdd(v);
    _ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lblSmall(widget.label, col),
        const SizedBox(height: 4),
        if (widget.items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.items.asMap().entries.map((e) {
              return Chip(
                label: Text(
                  e.value,
                  style: TextStyle(
                    color: widget.chipColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: widget.chipColor.withValues(alpha: 0.1),
                side: BorderSide(
                  color: widget.chipColor.withValues(alpha: 0.4),
                ),
                deleteIconColor: widget.chipColor,
                onDeleted: () => widget.onRemove(e.key),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                style: TextStyle(color: col.textPrimary, fontSize: 12),
                decoration: _sfDeco(context, widget.hint),
                onFieldSubmitted: (value) => _add(),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _add,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Iconsax.add_circle,
                  color: widget.chipColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateless helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _lblSmall(String text, AppColorScheme col) => Text(
  text,
  style: TextStyle(
    color: col.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  ),
);

/// Small text field used inside item cards.
class _SF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? prefixText;
  final VoidCallback? onChanged;

  const _SF({
    required this.ctrl,
    this.hint = '',
    this.maxLines = 1,
    this.keyboardType,
    this.prefixText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged != null ? (value) => onChanged!() : null,
      style: TextStyle(color: context.col.textPrimary, fontSize: 13),
      decoration: _sfDeco(context, hint).copyWith(prefixText: prefixText),
    );
  }
}

InputDecoration _sfDeco(BuildContext context, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: context.col.textMuted, fontSize: 12),
  filled: true,
  fillColor: context.col.bg,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: context.col.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: context.col.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
);

Widget _miniSwitch(String label, bool value, ValueChanged<bool> onChanged) =>
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );

class _VCard extends StatelessWidget {
  final Widget child;
  const _VCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.col.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.col.border),
    ),
    child: child,
  );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.col.surfaceElevated,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (i) => DropdownMenuItem<T>(
              value: i,
              child: Text(
                labelOf(i),
                style: TextStyle(color: context.col.textPrimary, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: context.col.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    ],
  );
}

class _AddBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AddBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ImagePickerWidget extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newImages;
  final bool uploading;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  const _ImagePickerWidget({
    required this.existingUrls,
    required this.newImages,
    required this.uploading,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text('Uploading images…', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...existingUrls.asMap().entries.map(
              (e) => _ImgThumb(
                url: e.value,
                onRemove: () => onRemoveExisting(e.key),
              ),
            ),
            ...newImages.asMap().entries.map(
              (e) => _ImgThumbFile(
                file: e.value,
                onRemove: () => onRemoveNew(e.key),
              ),
            ),
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.col.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
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

class _ImgThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImgThumb({required this.url, required this.onRemove});
  @override
  Widget build(BuildContext context) => _thumbStack(
    child: Image.network(
      url,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(width: 72, height: 72),
    ),
    onRemove: onRemove,
  );
}

class _ImgThumbFile extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _ImgThumbFile({required this.file, required this.onRemove});
  @override
  Widget build(BuildContext context) => _thumbStack(
    child: Image.network(
      file.path,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 72,
        height: 72,
        color: context.col.surfaceElevated,
        child: const Icon(Icons.image_outlined),
      ),
    ),
    onRemove: onRemove,
  );
}

Widget _thumbStack({required Widget child, required VoidCallback onRemove}) =>
    Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
