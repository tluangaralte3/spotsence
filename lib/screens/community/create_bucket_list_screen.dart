import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _bannerCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  final _challengeCtrl = TextEditingController();

  BucketCategory _category = BucketCategory.spot;
  BucketVisibility _visibility = BucketVisibility.public;
  int _maxMembers = 6;
  int _xpReward = 100;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _bannerCtrl.dispose();
    _customCatCtrl.dispose();
    _challengeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    final result = await ref
        .read(bucketListControllerProvider.notifier)
        .create(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bannerUrl: _bannerCtrl.text.trim(),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'New Bucket List',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bg,
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
            // ── Banner URL ─────────────────────────────────────────────
            _Section(
              title: 'Banner Image',
              child: Column(
                children: [
                  if (_bannerCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _bannerCtrl.text.trim(),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _AppField(
                    controller: _bannerCtrl,
                    hint: 'Paste an image URL (optional)',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
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
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '${cat.emoji}  ${cat.label}',
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
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
                  inactiveTrackColor: AppColors.border,
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
                      const Expanded(
                        child: Text(
                          'XP Reward on Completion',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                      inactiveTrackColor: AppColors.border,
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
          style: const TextStyle(
            color: AppColors.textPrimary,
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
  final void Function(String)? onChanged;

  const _AppField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceElevated,
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
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
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
