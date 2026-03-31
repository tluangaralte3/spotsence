import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dare_camera_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dare_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateDareScreen
// ─────────────────────────────────────────────────────────────────────────────

class CreateDareScreen extends ConsumerStatefulWidget {
  const CreateDareScreen({super.key});

  @override
  ConsumerState<CreateDareScreen> createState() => _CreateDareScreenState();
}

class _CreateDareScreenState extends ConsumerState<CreateDareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  File? _bannerFile;
  String? _bannerUrl;
  bool _uploadingBanner = false;

  DareCategory _category = DareCategory.adventure;
  DareVisibility _visibility = DareVisibility.public;
  int _maxParticipants = 10;
  int _xpReward = 100;
  bool _requiresProof = true;
  bool _saving = false;
  DateTime? _deadline;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _customCatCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile == null) return;
    setState(() {
      _bannerFile = File(xFile.path);
      _bannerUrl = null;
    });
  }

  Future<String?> _uploadBanner(String userId) async {
    if (_bannerFile == null) return _bannerUrl;
    setState(() => _uploadingBanner = true);
    try {
      final fileName = 'dare_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('dare_banners/$fileName');
      await storageRef.putFile(_bannerFile!);
      final url = await storageRef.getDownloadURL();
      setState(() => _bannerUrl = url);
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    } finally {
      setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _addTag(String tag) {
    final cleaned = tag.trim().replaceAll('#', '').toLowerCase();
    if (cleaned.isNotEmpty && !_tags.contains(cleaned) && _tags.length < 5) {
      setState(() {
        _tags.add(cleaned);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    final bannerUrl = await _uploadBanner(user.id);

    final result = await ref.read(dareControllerProvider.notifier).create(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      bannerUrl: bannerUrl,
      category: _category,
      customCategory:
          _category == DareCategory.other && _customCatCtrl.text.trim().isNotEmpty
              ? _customCatCtrl.text.trim()
              : null,
      visibility: _visibility,
      maxParticipants: _maxParticipants,
      creatorId: user.id,
      creatorName: user.displayName,
      creatorPhoto: user.photoURL,
      deadline: _deadline,
      xpReward: _xpReward,
      requiresProof: _requiresProof,
      tags: List<String>.from(_tags),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dare created! Add challenges to get started.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(dareControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to create dare'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          'Create Dare',
          style: TextStyle(color: context.col.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.col.textSecondary),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: (_saving || _uploadingBanner) ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Banner ───────────────────────────────────────────────────
            _Section(
              title: 'Banner Image',
              icon: Iconsax.image,
              child: _BannerPicker(
                file: _bannerFile,
                uploading: _uploadingBanner,
                onPick: _pickBanner,
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────────
            _Section(
              title: 'Title',
              icon: Iconsax.text,
              child: _AppField(
                controller: _titleCtrl,
                hint: 'e.g. 40km Trail Marathon Challenge',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
            ),
            const SizedBox(height: 20),

            // ── Description ──────────────────────────────────────────────
            _Section(
              title: 'Description',
              icon: Iconsax.document_text,
              child: _AppField(
                controller: _descCtrl,
                hint: 'Describe the dare, rules, and what participants will do...',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
            ),
            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────
            _Section(
              title: 'Category',
              icon: Iconsax.category,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DareCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withAlpha(40)
                            : context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : context.col.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: isSelected
                                ? cat.color
                                : context.col.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: isSelected
                                  ? cat.color
                                  : context.col.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_category == DareCategory.other) ...[
              const SizedBox(height: 12),
              _AppField(
                controller: _customCatCtrl,
                hint: 'Custom category name',
              ),
            ],
            const SizedBox(height: 20),

            // ── Visibility ───────────────────────────────────────────────
            _Section(
              title: 'Visibility',
              icon: Iconsax.eye,
              child: Row(
                children: [
                  _VisChip(
                    label: 'Public',
                    subtitle: 'Anyone can join',
                    icon: Iconsax.global,
                    selected: _visibility == DareVisibility.public,
                    onTap: () =>
                        setState(() => _visibility = DareVisibility.public),
                  ),
                  const SizedBox(width: 12),
                  _VisChip(
                    label: 'Private',
                    subtitle: 'Requires approval',
                    icon: Iconsax.lock,
                    selected: _visibility == DareVisibility.private,
                    onTap: () =>
                        setState(() => _visibility = DareVisibility.private),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Settings ─────────────────────────────────────────────────
            _Section(
              title: 'Settings',
              icon: Iconsax.setting_2,
              child: Column(
                children: [
                  // Max participants
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.people,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Max Participants',
                                style: TextStyle(
                                  color: context.col.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$_maxParticipants people',
                                style: TextStyle(
                                  color: context.col.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CounterButton(
                          onDecrement: () {
                            if (_maxParticipants > 2) {
                              setState(() => _maxParticipants--);
                            }
                          },
                          onIncrement: () {
                            if (_maxParticipants < 100) {
                              setState(() => _maxParticipants++);
                            }
                          },
                          value: _maxParticipants,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // XP reward
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.cup,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completion XP Reward',
                                style: TextStyle(
                                  color: context.col.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Bonus XP for completing all challenges',
                                style: TextStyle(
                                  color: context.col.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CounterButton(
                          onDecrement: () {
                            if (_xpReward > 50) {
                              setState(() => _xpReward -= 50);
                            }
                          },
                          onIncrement: () {
                            if (_xpReward < 1000) {
                              setState(() => _xpReward += 50);
                            }
                          },
                          value: _xpReward,
                          suffix: 'XP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Requires proof
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Require Proof',
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Participants must submit image proof',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      value: _requiresProof,
                      onChanged: (v) => setState(() => _requiresProof = v),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Deadline ─────────────────────────────────────────────────
            _Section(
              title: 'Deadline (Optional)',
              icon: Iconsax.timer_1,
              child: InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.calendar,
                        size: 18,
                        color: context.col.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _deadline != null
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'No deadline — dare runs indefinitely',
                          style: TextStyle(
                            color: _deadline != null
                                ? context.col.textPrimary
                                : context.col.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: Icon(
                            Iconsax.close_circle,
                            size: 18,
                            color: context.col.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Tags ─────────────────────────────────────────────────────
            _Section(
              title: 'Tags (Optional, max 5)',
              icon: Iconsax.tag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _AppField(
                          controller: _tagCtrl,
                          hint: 'Add a tag (e.g. marathon, hiking)',
                          onSubmit: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Iconsax.add_circle,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _addTag(_tagCtrl.text),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              label: Text('#$tag'),
                              labelStyle: TextStyle(
                                color: context.col.textPrimary,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.primary.withAlpha(25),
                              side: BorderSide(
                                color: AppColors.primary.withAlpha(60),
                              ),
                              deleteIcon: const Icon(
                                Iconsax.close_circle,
                                size: 14,
                              ),
                              deleteIconColor: context.col.textMuted,
                              onDeleted: () =>
                                  setState(() => _tags.remove(tag)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AddDareChallengeScreen — add individual challenge to a dare
// ─────────────────────────────────────────────────────────────────────────────

class AddDareChallengeScreen extends ConsumerStatefulWidget {
  final String dareId;
  const AddDareChallengeScreen({super.key, required this.dareId});

  @override
  ConsumerState<AddDareChallengeScreen> createState() =>
      _AddDareChallengeScreenState();
}

class _AddDareChallengeScreenState
    extends ConsumerState<AddDareChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          'Add Challenge',
          style: TextStyle(color: context.col.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.col.textSecondary),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.col.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Iconsax.location, size: 16),
              text: 'From App',
            ),
            Tab(
              icon: Icon(Iconsax.edit, size: 16),
              text: 'Custom',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AppListingTab(dareId: widget.dareId),
          _CustomChallengeTab(dareId: widget.dareId),
        ],
      ),
    );
  }
}

// ── Dare Listing Config & Data ────────────────────────────────────────────────

typedef _DareListingConfig = ({
  String label,
  IconData icon,
  String collection,
  DareCategory dareCategory,
  String? typeFilter,
});

class _DareListingItem {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final String collection;
  final DareCategory dareCategory;
  final double rating;

  const _DareListingItem({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.collection,
    required this.dareCategory,
    required this.rating,
  });

  factory _DareListingItem.fromDoc(
    DocumentSnapshot doc,
    String collection,
    DareCategory category,
  ) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final name = (d['name'] ?? d['title'] ?? '').toString();

    String img = '';
    if (d['imageUrl'] is String && (d['imageUrl'] as String).isNotEmpty) {
      img = d['imageUrl'] as String;
    } else if (d['image'] is String && (d['image'] as String).isNotEmpty) {
      img = d['image'] as String;
    } else if (d['images'] is List && (d['images'] as List).isNotEmpty) {
      img = ((d['images'] as List).first ?? '').toString();
    } else if (d['imagesUrl'] is List && (d['imagesUrl'] as List).isNotEmpty) {
      img = ((d['imagesUrl'] as List).first ?? '').toString();
    }

    final location = (d['location'] ?? d['address'] ?? '').toString();
    final rating =
        ((d['rating'] ?? d['averageRating'] ?? 0.0) as num).toDouble();

    return _DareListingItem(
      id: doc.id,
      name: name,
      location: location,
      imageUrl: img,
      collection: collection,
      dareCategory: category,
      rating: rating,
    );
  }
}

final _dareListingFetchProvider = FutureProvider.autoDispose
    .family<List<_DareListingItem>, _DareListingConfig>((ref, cfg) async {
  final db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> docs;
  try {
    final snap =
        await db.collection(cfg.collection).orderBy('name').limit(80).get();
    docs = snap.docs;
  } catch (_) {
    // Index may be missing — fetch without orderBy
    final snap = await db.collection(cfg.collection).limit(80).get();
    docs = snap.docs;
  }

  return docs.where((d) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status.isNotEmpty &&
        status != 'approved' &&
        status != 'active' &&
        status != 'published') {
      return false;
    }
    final name = (data['name'] ?? data['title'] ?? '').toString();
    if (name.isEmpty) return false;
    if (cfg.typeFilter != null) {
      final type = (data['type'] ?? '').toString().toLowerCase();
      if (type != cfg.typeFilter) return false;
    }
    return true;
  }).map((d) => _DareListingItem.fromDoc(d, cfg.collection, cfg.dareCategory)).toList();
});

// ── App Listing Tab ───────────────────────────────────────────────────────────

class _AppListingTab extends ConsumerStatefulWidget {
  final String dareId;
  const _AppListingTab({required this.dareId});

  @override
  ConsumerState<_AppListingTab> createState() => _AppListingTabState();
}

class _AppListingTabState extends ConsumerState<_AppListingTab>
    with SingleTickerProviderStateMixin {
  static final _configs = <_DareListingConfig>[
    (
      label: 'Spots',
      icon: Iconsax.location,
      collection: 'spots',
      dareCategory: DareCategory.exploration,
      typeFilter: null,
    ),
    (
      label: 'Restaurants',
      icon: Iconsax.coffee,
      collection: 'restaurants',
      dareCategory: DareCategory.foodRating,
      typeFilter: null,
    ),
    (
      label: 'Cafés',
      icon: Iconsax.coffee,
      collection: 'cafes',
      dareCategory: DareCategory.social,
      typeFilter: null,
    ),
    (
      label: 'Hotels',
      icon: Iconsax.building,
      collection: 'accommodations',
      dareCategory: DareCategory.travel,
      typeFilter: 'hotel',
    ),
    (
      label: 'Homestays',
      icon: Iconsax.home,
      collection: 'accommodations',
      dareCategory: DareCategory.travel,
      typeFilter: 'homestay',
    ),
    (
      label: 'Adventure',
      icon: Iconsax.flash,
      collection: 'adventureSpots',
      dareCategory: DareCategory.adventure,
      typeFilter: null,
    ),
    (
      label: 'Shopping',
      icon: Iconsax.shopping_bag,
      collection: 'shoppingAreas',
      dareCategory: DareCategory.social,
      typeFilter: null,
    ),
  ];

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _configs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _showSheet(_DareListingItem item) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListingChallengeSheet(
        item: item,
        dareId: widget.dareId,
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge added!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.col.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: _configs
              .map((cfg) => Tab(icon: Icon(cfg.icon, size: 14), text: cfg.label))
              .toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: _configs
                .map(
                  (cfg) => _CollectionListingTab(
                    config: cfg,
                    onSelect: _showSheet,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CollectionListingTab extends ConsumerStatefulWidget {
  final _DareListingConfig config;
  final Future<void> Function(_DareListingItem) onSelect;

  const _CollectionListingTab({
    required this.config,
    required this.onSelect,
  });

  @override
  ConsumerState<_CollectionListingTab> createState() =>
      _CollectionListingTabState();
}

class _CollectionListingTabState extends ConsumerState<_CollectionListingTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(_dareListingFetchProvider(widget.config));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: context.col.textPrimary, fontSize: 14),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search ${widget.config.label}...',
              hintStyle: TextStyle(color: context.col.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Iconsax.search_normal,
                size: 18,
                color: context.col.textMuted,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: context.col.textMuted,
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _query = '';
                      }),
                    )
                  : null,
              filled: true,
              fillColor: context.col.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        // Listing results
        Expanded(
          child: asyncItems.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'Failed to load listings',
                style: TextStyle(color: context.col.textMuted),
              ),
            ),
            data: (items) {
              final filtered = _query.isEmpty
                  ? items
                  : items.where((i) {
                      return i.name.toLowerCase().contains(_query) ||
                          i.location.toLowerCase().contains(_query);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.search_normal,
                        size: 48,
                        color: context.col.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty
                            ? 'No ${widget.config.label} found'
                            : 'No results for "$_query"',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ListingCard(
                  item: filtered[i],
                  onTap: () => widget.onSelect(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final _DareListingItem item;
  final VoidCallback onTap;

  const _ListingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13),
              ),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 11,
                            color: context.col.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                color: context.col.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star1,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: context.col.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: context.col.surfaceElevated,
      child: Icon(
        item.dareCategory.icon,
        size: 28,
        color: item.dareCategory.color.withAlpha(120),
      ),
    );
  }
}

// ── Listing Challenge Sheet ──────────────────────────────────────────────────

class _ListingChallengeSheet extends ConsumerStatefulWidget {
  final _DareListingItem item;
  final String dareId;
  const _ListingChallengeSheet({
    required this.item,
    required this.dareId,
  });

  @override
  ConsumerState<_ListingChallengeSheet> createState() =>
      _ListingChallengeSheetState();
}

class _ListingChallengeSheetState
    extends ConsumerState<_ListingChallengeSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  File? _proofImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: 'Visit & Rate: ${widget.item.name}',
    );
    _descCtrl = TextEditingController(text: _autoDesc());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _autoDesc() {
    final name = widget.item.name;
    final loc = widget.item.location;
    final here = loc.isNotEmpty ? ' in $loc' : '';
    switch (widget.item.collection) {
      case 'restaurants':
        return 'Visit $name$here, try their signature dishes, and rate the experience. Submit a photo of your meal as proof.';
      case 'cafes':
        return 'Visit $name$here, enjoy a drink or snack, and rate the ambiance. Submit a photo of your visit as proof.';
      case 'adventureSpots':
        return 'Conquer $name$here — document your adventure and submit photo proof of completing this challenge.';
      case 'accommodations':
        return 'Stay at or visit $name$here and share your experience. Submit a check-in photo as proof.';
      case 'shoppingAreas':
        return 'Explore $name$here and find something unique. Submit a photo of your shopping adventure as proof.';
      default:
        return 'Visit $name$here, explore the location, and capture the moment. Submit a photo as proof of your achievement.';
    }
  }

  Future<void> _captureWithCamera() async {
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<File?>(
      MaterialPageRoute<File?>(
        fullscreenDialog: true,
        builder: (_) => DareCameraOverlay(
          challengeTitle: _titleCtrl.text,
          spotName: widget.item.name,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _proofImage = result);
  }

  Future<void> _pickFromGallery() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (x != null && mounted) setState(() => _proofImage = File(x.path));
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      // Use the captured proof image URL; fall back to listing thumb
      String? imageUrl =
          widget.item.imageUrl.isNotEmpty ? widget.item.imageUrl : null;
      if (_proofImage != null) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final name =
              'challenge_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
          final sr = FirebaseStorage.instance
              .ref()
              .child('challenge_samples/$name');
          await sr.putFile(_proofImage!);
          imageUrl = await sr.getDownloadURL();
        }
      }

      final challenge = DareChallenge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        imageUrl: imageUrl,
        category: widget.item.dareCategory,
        type: DareChallengeType.appListing,
        listingId: widget.item.id,
        listingCollection: widget.item.collection,
        listingLocation:
            widget.item.location.isNotEmpty ? widget.item.location : null,
        xpReward: 100,
        medalType: MedalType.bronze,
        requiresProof: true,
      );

      await ref
          .read(dareControllerProvider.notifier)
          .addChallenge(widget.dareId, challenge);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add challenge: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Listing info header ─────────────────────────────────
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: widget.item.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.item.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _iconThumb(context),
                              )
                            : _iconThumb(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: TextStyle(
                                color: context.col.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.item.location.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.location,
                                    size: 11,
                                    color: context.col.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.item.location,
                                      style: TextStyle(
                                        color: context.col.textMuted,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.item.rating > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.star1,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.item.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: context.col.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Challenge title ─────────────────────────────────────
                  Text(
                    'Challenge Title',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    style:
                        TextStyle(color: context.col.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.col.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Challenge explanation ───────────────────────────────
                  Text(
                    'Challenge Explanation',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    style:
                        TextStyle(color: context.col.textPrimary, fontSize: 14),
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.col.surfaceElevated,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Proof sample photo ──────────────────────────────────
                  Text(
                    'Sample Proof Photo (Optional)',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Show participants what kind of proof is expected',
                    style:
                        TextStyle(color: context.col.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  if (_proofImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _proofImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _proofImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.col.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Camera with overlay
                          GestureDetector(
                            onTap: _captureWithCamera,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(25),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(80),
                                    ),
                                  ),
                                  child: const Icon(
                                    Iconsax.camera,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Camera',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '+ overlay',
                                  style: TextStyle(
                                    color: context.col.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 24),
                            color: context.col.border,
                          ),
                          // Gallery
                          GestureDetector(
                            onTap: _pickFromGallery,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: context.col.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.col.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Iconsax.image,
                                    color: context.col.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gallery',
                                  style: TextStyle(
                                    color: context.col.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Add Challenge button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _add,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.bg,
                              ),
                            )
                          : const Icon(Iconsax.add_circle),
                      label: const Text('Add Challenge'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconThumb(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.item.dareCategory.color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        widget.item.dareCategory.icon,
        color: widget.item.dareCategory.color,
        size: 26,
      ),
    );
  }
}

// ── Custom Challenge Tab ──────────────────────────────────────────────────────

class _CustomChallengeTab extends ConsumerStatefulWidget {
  final String dareId;
  const _CustomChallengeTab({required this.dareId});

  @override
  ConsumerState<_CustomChallengeTab> createState() =>
      _CustomChallengeTabState();
}

class _CustomChallengeTabState extends ConsumerState<_CustomChallengeTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  DareCategory _category = DareCategory.adventure;
  MedalType _medal = MedalType.bronze;
  int _xp = 100;
  bool _requiresProof = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final challenge = DareChallenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
      category: _category,
      type: DareChallengeType.custom,
      customInstructions: _instrCtrl.text.trim().isNotEmpty
          ? _instrCtrl.text.trim()
          : null,
      xpReward: _xp,
      medalType: _medal,
      requiresProof: _requiresProof,
    );

    await ref
        .read(dareControllerProvider.notifier)
        .addChallenge(widget.dareId, challenge);

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge added!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Title
          _Section(
            title: 'Challenge Title',
            icon: Iconsax.text,
            child: _AppField(
              controller: _titleCtrl,
              hint: 'e.g. Run 40km, Explore a new cave',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _Section(
            title: 'Description (Optional)',
            icon: Iconsax.document_text,
            child: _AppField(
              controller: _descCtrl,
              hint: 'Brief description of the challenge...',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          _Section(
            title: 'Instructions (Optional)',
            icon: Iconsax.note_text,
            child: _AppField(
              controller: _instrCtrl,
              hint:
                  'Specific instructions for this challenge... e.g. "Must complete within city limits"',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),

          // Category
          _Section(
            title: 'Category',
            icon: Iconsax.category,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DareCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withAlpha(40)
                          : context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? cat.color : context.col.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 13,
                          color: sel
                              ? cat.color
                              : context.col.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: sel
                                ? cat.color
                                : context.col.textSecondary,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Rewards
          _Section(
            title: 'Reward',
            icon: Iconsax.medal_star,
            child: Column(
              children: [
                // Medal
                Row(
                  children: [
                    Text(
                      'Medal:',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: MedalType.values.map((m) {
                          final sel = _medal == m;
                          return GestureDetector(
                            onTap: () => setState(() => _medal = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? m.bgColor
                                    : context.col.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel ? m.color : context.col.border,
                                ),
                              ),
                              child: Text(
                                m.label,
                                style: TextStyle(
                                  color: sel
                                      ? m.color
                                      : context.col.textSecondary,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // XP
                Row(
                  children: [
                    Text(
                      'XP:',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CounterButton(
                        onDecrement: () {
                          if (_xp > 50) setState(() => _xp -= 50);
                        },
                        onIncrement: () {
                          if (_xp < 500) setState(() => _xp += 50);
                        },
                        value: _xp,
                        suffix: 'XP',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Requires proof
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Require Image Proof',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Participants must submit photo evidence',
                style: TextStyle(color: context.col.textMuted, fontSize: 12),
              ),
              value: _requiresProof,
              onChanged: (v) => setState(() => _requiresProof = v),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.add_circle),
              label: const Text('Add Challenge'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmit;

  const _AppField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: context.col.textPrimary, fontSize: 14),
      validator: validator,
      onFieldSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.col.textMuted, fontSize: 14),
        filled: true,
        fillColor: context.col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

class _VisChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VisChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withAlpha(25)
                : context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.col.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    selected ? AppColors.primary : context.col.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : context.col.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int value;
  final String? suffix;

  const _CounterButton({
    required this.onDecrement,
    required this.onIncrement,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.col.border),
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            suffix != null ? '$value $suffix' : '$value',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: const Icon(
              Icons.add,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerPicker extends StatelessWidget {
  final File? file;
  final bool uploading;
  final VoidCallback onPick;

  const _BannerPicker({
    required this.file,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.col.border,
            style: BorderStyle.solid,
          ),
          image: file != null
              ? DecorationImage(
                  image: FileImage(file!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: uploading
            ? const Center(child: CircularProgressIndicator())
            : file == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.image,
                        size: 36,
                        color: context.col.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select banner image',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : null,
      ),
    );
  }
}
