import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/bucket_list_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';

class CreateBucketListScreen extends ConsumerStatefulWidget {
  const CreateBucketListScreen({super.key});

  @override
  ConsumerState<CreateBucketListScreen> createState() =>
      _CreateBucketListScreenState();
}

class _CreateBucketListScreenState
    extends ConsumerState<CreateBucketListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  final _challengeCtrl = TextEditingController();

  File? _bannerFile; // local file picked from device
  String? _bannerUrl; // uploaded URL (set after upload)
  bool _uploadingBanner = false;

  BucketCategory _category = BucketCategory.spot;
  BucketVisibility _visibility = BucketVisibility.public;
  int _maxMembers = 6;
  int _xpReward = 100;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _customCatCtrl.dispose();
    _challengeCtrl.dispose();
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
      _bannerUrl = null; // reset old upload
    });
  }

  Future<String?> _uploadBanner(String userId) async {
    if (_bannerFile == null) return _bannerUrl;
    setState(() => _uploadingBanner = true);
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'bucket_list_banners/$fileName',
      );
      await ref.putFile(_bannerFile!);
      final url = await ref.getDownloadURL();
      setState(() => _bannerUrl = url);
      return url;
    } catch (e) {
      debugPrint('Banner upload error: $e');
      return null;
    } finally {
      setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    // Upload banner if a local file was picked
    final bannerUrl = await _uploadBanner(user.id);

    final result = await ref
        .read(bucketListControllerProvider.notifier)
        .create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bannerUrl: bannerUrl ?? '',
          category: _category,
          customCategory:
              _category == BucketCategory.other &&
                  _customCatCtrl.text.trim().isNotEmpty
              ? _customCatCtrl.text.trim()
              : null,
          visibility: _visibility,
          maxMembers: _maxMembers,
          hostId: user.id,
          hostName: user.displayName,
          hostPhoto: user.photoURL,
          xpReward: _xpReward,
          challengeTitle: _challengeCtrl.text.trim().isNotEmpty
              ? _challengeCtrl.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      // pushReplacement atomically swaps the modal for the detail screen
      // without the pop+push race condition that caused SIGABRT
      context.pushReplacement(AppRoutes.bucketListDetailPath(result.id));
    } else {
      final errMsg = ref.read(bucketListControllerProvider).error;
      debugPrint('Create bucket list failed: $errMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg ?? 'Failed to create list. Please try again.'),
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
          'New Bucket List',
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
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.col.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.col.bg,
                      ),
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
            // ── Banner Image ───────────────────────────────────────────
            _Section(
              title: 'Banner Image',
              child: _bannerFile != null
                  // ── Preview with overlay controls ──────────────────
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _bannerFile!,
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
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        // Remove button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _bannerFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // Change button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _pickBanner,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
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
                        ),
                      ],
                    )
                  // ── Empty tap-to-pick area ─────────────────────────
                  : GestureDetector(
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
                                style: TextStyle(
                                  color: context.col.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

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
                hint: 'What\'s this adventure about?',
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
                  // XP reward
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

                  // Challenge title
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form widgets
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
