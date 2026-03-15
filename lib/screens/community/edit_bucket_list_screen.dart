import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/bucket_list_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditBucketListScreen
// ─────────────────────────────────────────────────────────────────────────────

class EditBucketListScreen extends ConsumerWidget {
  final String listId;
  const EditBucketListScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bucketListDetailProvider(listId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(backgroundColor: context.col.bg),
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (list) => list == null
          ? Scaffold(
              backgroundColor: context.col.bg,
              appBar: AppBar(backgroundColor: context.col.bg),
              body: Center(
                child: Text(
                  'List not found',
                  style: TextStyle(color: context.col.textSecondary),
                ),
              ),
            )
          : _EditBody(list: list),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EditBody
// ─────────────────────────────────────────────────────────────────────────────

class _EditBody extends ConsumerStatefulWidget {
  final BucketListModel list;
  const _EditBody({required this.list});

  @override
  ConsumerState<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends ConsumerState<_EditBody> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers pre-filled from the existing list
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _customCatCtrl;
  late final TextEditingController _challengeCtrl;

  // Banner state
  File? _newBannerFile; // picked but not uploaded yet
  late String _bannerUrl; // current URL (existing or freshly uploaded)
  bool _uploadingBanner = false;

  // Editable fields
  late BucketCategory _category;
  late BucketVisibility _visibility;
  late int _maxMembers;
  late int _xpReward;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.list;
    _titleCtrl = TextEditingController(text: l.title);
    _descCtrl = TextEditingController(text: l.description);
    _customCatCtrl = TextEditingController(text: l.customCategory ?? '');
    _challengeCtrl = TextEditingController(text: l.challengeTitle ?? '');
    _bannerUrl = l.bannerUrl;
    _category = l.category;
    _visibility = l.visibility;
    _maxMembers = l.maxMembers;
    _xpReward = l.xpReward;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _customCatCtrl.dispose();
    _challengeCtrl.dispose();
    super.dispose();
  }

  // ── Banner helpers ────────────────────────────────────────────────────────

  Future<void> _pickBanner() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile == null) return;
    setState(() {
      _newBannerFile = File(xFile.path);
      _bannerUrl = ''; // will be replaced after upload
    });
  }

  /// Uploads [_newBannerFile] to Firebase Storage and returns the download URL.
  /// Returns [_bannerUrl] unchanged when no new file was picked.
  /// Throws on upload failure so the caller can surface the error.
  Future<String> _uploadBannerIfNeeded() async {
    if (_newBannerFile == null) return _bannerUrl;
    setState(() => _uploadingBanner = true);
    try {
      // Use actual file extension (could be .heic / .png / .jpg on iOS)
      final ext = _newBannerFile!.path.split('.').last.toLowerCase();
      final name =
          '${widget.list.hostId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storageRef = FirebaseStorage.instance.ref().child(
        'bucket_list_banners/$name',
      );

      // putData avoids iOS NSURL content-decode errors caused by MIME mismatch
      final bytes = await _newBannerFile!.readAsBytes();
      final snapshot = await storageRef.putData(bytes);
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final String finalBannerUrl;
    try {
      finalBannerUrl = await _uploadBannerIfNeeded();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Banner upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final ok = await ref
        .read(bucketListControllerProvider.notifier)
        .updateList(
          listId: widget.list.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bannerUrl: finalBannerUrl,
          category: _category,
          customCategory:
              _category == BucketCategory.other &&
                  _customCatCtrl.text.trim().isNotEmpty
              ? _customCatCtrl.text.trim()
              : null,
          visibility: _visibility,
          maxMembers: _maxMembers,
          xpReward: _xpReward,
          challengeTitle: _challengeCtrl.text.trim().isNotEmpty
              ? _challengeCtrl.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bucket list updated ✨'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pop();
    } else {
      final err =
          ref.read(bucketListControllerProvider).error ?? 'Update failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          'Edit Bucket List',
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
                foregroundColor: context.col.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: (_saving || _uploadingBanner)
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.col.bg,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Banner ─────────────────────────────────────────────────
            _Section(title: 'Banner Image', child: _buildBannerPicker()),

            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────────────
            _Section(
              title: 'Title *',
              child: _AppField(
                controller: _titleCtrl,
                hint: 'e.g. Mizoram Waterfalls Road Trip',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
            ),

            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────
            _Section(
              title: 'Short Description',
              child: _AppField(
                controller: _descCtrl,
                hint: "What's this adventure about?",
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────────────
            _Section(
              title: 'Category',
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BucketCategory.values.map((cat) {
                      final selected = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : context.col.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : context.col.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '${cat.emoji}  ${cat.label}',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : context.col.textSecondary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_category == BucketCategory.other) ...[
                    const SizedBox(height: 12),
                    _AppField(
                      controller: _customCatCtrl,
                      hint: 'Enter your category name',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Visibility ────────────────────────────────────────────
            _Section(
              title: 'Visibility',
              child: Row(
                children: [
                  _ToggleChip(
                    label: '🌐  Public',
                    subtitle: 'Anyone can discover',
                    selected: _visibility == BucketVisibility.public,
                    onTap: () =>
                        setState(() => _visibility = BucketVisibility.public),
                  ),
                  const SizedBox(width: 10),
                  _ToggleChip(
                    label: '🔒  Private',
                    subtitle: 'Join code only',
                    selected: _visibility == BucketVisibility.private,
                    onTap: () =>
                        setState(() => _visibility = BucketVisibility.private),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Max members ───────────────────────────────────────────
            _Section(
              title: 'Max Members: $_maxMembers',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: context.col.border,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: _maxMembers.toDouble(),
                  min: 2,
                  max: 20,
                  divisions: 18,
                  label: '$_maxMembers',
                  onChanged: (v) => setState(() => _maxMembers = v.round()),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Gamification ──────────────────────────────────────────
            _Section(
              title: '🎮 Gamification',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'XP Reward on Completion',
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+$_xpReward XP',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: context.col.border,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: _xpReward.toDouble(),
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '+$_xpReward',
                      onChanged: (v) => setState(() => _xpReward = v.round()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AppField(
                    controller: _challengeCtrl,
                    hint: 'Challenge name (optional, e.g. "7 Wonders Sprint")',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner picker widget ───────────────────────────────────────────────────

  Widget _buildBannerPicker() {
    // A new file has been picked — show local preview
    if (_newBannerFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _newBannerFile!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          if (_uploadingBanner)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          _overlayRemoveButton(() => setState(() => _newBannerFile = null)),
          _overlayChangeButton(),
        ],
      );
    }

    // Existing network banner
    if (_bannerUrl.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: _bannerUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context0, url0) => Container(
                height: 160,
                color: context.col.surfaceElevated,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (context0, url0, err) =>
                  Container(height: 160, color: context.col.surfaceElevated),
            ),
          ),
          _overlayRemoveButton(() => setState(() => _bannerUrl = '')),
          _overlayChangeButton(),
        ],
      );
    }

    // No banner — tap to pick
    return GestureDetector(
      onTap: _pickBanner,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: context.col.textMuted,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Tap to pick a banner photo',
                style: TextStyle(color: context.col.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overlayRemoveButton(VoidCallback onTap) => Positioned(
    top: 8,
    right: 8,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
      ),
    ),
  );

  Widget _overlayChangeButton() => Positioned(
    bottom: 8,
    right: 8,
    child: GestureDetector(
      onTap: _pickBanner,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Change',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form widgets (mirrors create_bucket_list_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.col.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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

  const _AppField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: context.col.textPrimary, fontSize: 14),
      validator: validator,
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

class _ToggleChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.subtitle,
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
                ? AppColors.primary.withValues(alpha: 0.12)
                : context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : context.col.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : context.col.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
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
