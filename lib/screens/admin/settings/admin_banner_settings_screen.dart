// lib/screens/admin/settings/admin_banner_settings_screen.dart
//
// Standalone banner-management page accessible from Admin Settings.
// Full create / edit / delete / toggle + section-visibility switch.
// Same functionality as the main Banners nav tab, but navigable via
// Navigator.push with a back button.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/banner_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/banner_model.dart';
import '../../../services/banner_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminBannerSettingsScreen extends ConsumerWidget {
  const AdminBannerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final configAsync = ref.watch(bannerSectionConfigProvider);
    final bannersAsync = ref.watch(allBannersProvider);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        foregroundColor: col.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: col.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.image, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Banner Management'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
            tooltip: 'Add banner',
            onPressed: () => _openEditor(context, ref, null),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: col.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── Section visibility toggle ────────────────────────────────
          configAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (cfg) => _SectionVisibilityCard(
              visible: cfg.sectionVisible,
              onToggle: (v) =>
                  ref.read(bannerServiceProvider).setSectionVisible(v),
            ),
          ),
          const SizedBox(height: 24),

          // ── Banners list ─────────────────────────────────────────────
          Row(
            children: [
              Text(
                'BANNERS',
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              bannersAsync.when(
                data: (b) => Text(
                  '${b.length} total',
                  style: TextStyle(
                      color: context.col.textMuted, fontSize: 11),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          bannersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => _ErrorState(message: e.toString()),
            data: (banners) {
              if (banners.isEmpty) {
                return _EmptyState(
                    onAdd: () => _openEditor(context, ref, null));
              }
              return Column(
                children: banners.asMap().entries.map((entry) {
                  final b = entry.value;
                  return _BannerCard(
                    banner: b,
                    onEdit: () => _openEditor(context, ref, b),
                    onToggle: () =>
                        ref.read(bannerServiceProvider).toggleBannerActive(b),
                    onDelete: () => _confirmDelete(context, ref, b),
                  ).animate(delay: Duration(milliseconds: entry.key * 50))
                    .fadeIn()
                    .slideY(begin: 0.05);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Quick add FAB replacement ─────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _openEditor(context, ref, null),
            icon: const Icon(Iconsax.add_circle, size: 16, color: AppColors.primary),
            label: const Text(
              'Add New Banner',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _openEditor(
      BuildContext context, WidgetRef ref, BannerModel? banner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerEditorSheet(
        existing: banner,
        onSave: (b) {
          final svc = ref.read(bannerServiceProvider);
          if (b.id.isEmpty) {
            svc.createBanner(b);
          } else {
            svc.updateBanner(b);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, BannerModel banner) {
    final col = context.col;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: col.surface,
        title: Text('Delete Banner?',
            style: TextStyle(color: col.textPrimary)),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: col.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: '"'),
              TextSpan(
                text: banner.title.isEmpty ? 'This banner' : banner.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                  text: '" will be permanently removed from the home screen.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46)),
                  child: Text('Cancel',
                      style: TextStyle(color: col.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(0, 46)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(bannerServiceProvider).deleteBanner(banner.id);
                  },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Visibility Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionVisibilityCard extends StatelessWidget {
  final bool visible;
  final ValueChanged<bool> onToggle;

  const _SectionVisibilityCard({
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: visible
              ? AppColors.primary.withValues(alpha: 0.35)
              : col.border,
          width: visible ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Iconsax.eye, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Banner Section',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Controls whether the promo carousel is visible on the home screen',
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: visible,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Card
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: banner.isActive
              ? col.border
              : col.border.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: banner.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _ThumbPlaceholder(),
                        )
                      : _ThumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            banner.title.isEmpty ? '(Untitled)' : banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!banner.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: col.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'HIDDEN',
                              style: TextStyle(
                                  color: col.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                    if (banner.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        banner.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: col.textSecondary, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 5),
                    _LinkBadge(banner: banner),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Controls column
              Column(
                children: [
                  Switch(
                    value: banner.isActive,
                    onChanged: (_) => onToggle(),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Iconsax.trash,
                          size: 16, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  final BannerModel banner;
  const _LinkBadge({required this.banner});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (banner.linkType) {
      case BannerLinkType.internalRoute:
        color = AppColors.primary;
        label = 'Route: ${banner.linkValue ?? '—'}';
        icon = Iconsax.routing;
        break;
      case BannerLinkType.externalUrl:
        color = AppColors.secondary;
        label = 'URL';
        icon = Iconsax.global;
        break;
      case BannerLinkType.none:
        color = context.col.textMuted;
        label = 'No link';
        icon = Iconsax.slash;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceElevated,
      child: Center(
        child: Icon(Iconsax.image, size: 22, color: context.col.textMuted),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.image, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No banners yet',
            style: TextStyle(
              color: col.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first promotional banner\nto display on the home screen carousel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: col.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Banner'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Iconsax.warning_2, size: 32, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            'Failed to load banners',
            style: TextStyle(
                color: context.col.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(color: context.col.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Editor Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BannerEditorSheet extends StatefulWidget {
  final BannerModel? existing;
  final ValueChanged<BannerModel> onSave;

  const _BannerEditorSheet({this.existing, required this.onSave});

  @override
  State<_BannerEditorSheet> createState() => _BannerEditorSheetState();
}

class _BannerEditorSheetState extends State<_BannerEditorSheet> {
  late final _titleCtrl =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _subtitleCtrl =
      TextEditingController(text: widget.existing?.subtitle ?? '');
  late final _linkValueCtrl =
      TextEditingController(text: widget.existing?.linkValue ?? '');
  late BannerLinkType _linkType =
      widget.existing?.linkType ?? BannerLinkType.none;
  late bool _isActive = widget.existing?.isActive ?? true;
  late String _existingImageUrl = widget.existing?.imageUrl ?? '';

  XFile? _pickedFile;
  bool _uploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _linkValueCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (xFile == null) return;
    setState(() {
      _pickedFile = xFile;
      _existingImageUrl = '';
    });
  }

  Future<String> _uploadImageIfNeeded() async {
    if (_pickedFile == null) return _existingImageUrl;
    setState(() => _uploading = true);
    try {
      final ext = _pickedFile!.path.split('.').last.toLowerCase();
      final name = 'banner_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storageRef = FirebaseStorage.instance.ref('banners/$name');
      final bytes = await _pickedFile!.readAsBytes();
      final snapshot = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return snapshot.ref.getDownloadURL();
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final imageUrl = await _uploadImageIfNeeded();
      final now = DateTime.now();
      final banner = BannerModel(
        id: widget.existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        imageUrl: imageUrl,
        linkType: _linkType,
        linkValue: _linkValueCtrl.text.trim().isEmpty
            ? null
            : _linkValueCtrl.text.trim(),
        isActive: _isActive,
        order: widget.existing?.order ?? 999,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );
      widget.onSave(banner);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
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
    final col = context.col;
    final isEdit = widget.existing != null;

    return Container(
      decoration: BoxDecoration(
        color: col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: col.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.image,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Edit Banner' : 'New Banner',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Image picker ──────────────────────────────────────────
            _Label('Banner Image', col),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploading || _saving ? null : _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (_pickedFile != null ||
                            _existingImageUrl.isNotEmpty)
                        ? AppColors.primary
                        : col.border,
                    width: (_pickedFile != null ||
                            _existingImageUrl.isNotEmpty)
                        ? 1.5
                        : 1,
                  ),
                ),
                child: _uploading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _pickedFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_pickedFile!.path),
                                  fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _ImageBadge(label: 'Change'),
                              ),
                            ],
                          )
                        : _existingImageUrl.isNotEmpty
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _existingImageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) =>
                                        _PickerPlaceholder(),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _ImageBadge(label: 'Change'),
                                  ),
                                ],
                              )
                            : _PickerPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Fields ────────────────────────────────────────────────
            _Field(label: 'Title', controller: _titleCtrl),
            const SizedBox(height: 12),
            _Field(
                label: 'Subtitle (optional)',
                controller: _subtitleCtrl,
                maxLines: 2),
            const SizedBox(height: 16),

            // ── Link type ─────────────────────────────────────────────
            _Label('Link type', col),
            const SizedBox(height: 8),
            Row(
              children: BannerLinkType.values.map((t) {
                final selected = _linkType == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _linkType = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : col.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : col.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        switch (t) {
                          BannerLinkType.none => 'None',
                          BannerLinkType.internalRoute => 'Route',
                          BannerLinkType.externalUrl => 'URL',
                        },
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : col.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_linkType != BannerLinkType.none) ...[
              const SizedBox(height: 12),
              _Field(
                label: _linkType == BannerLinkType.internalRoute
                    ? 'App route  (e.g. /listings)'
                    : 'External URL  (https://...)',
                controller: _linkValueCtrl,
              ),
            ],

            const SizedBox(height: 16),

            // ── Active toggle ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: col.border),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.eye,
                      size: 18,
                      color: _isActive
                          ? AppColors.primary
                          : col.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active / Visible',
                          style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        Text(
                          'Show this banner on the home screen',
                          style: TextStyle(
                              color: col.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Save button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploading) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(
                        isEdit ? 'Save Changes' : 'Create Banner',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, col),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: col.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: col.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppColorScheme col;
  const _Label(this.text, this.col);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: col.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _PickerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.camera, size: 32, color: col.textMuted),
        const SizedBox(height: 8),
        Text(
          'Tap to pick an image',
          style: TextStyle(color: col.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: 16:9, max 1600px wide',
          style: TextStyle(color: col.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final String label;
  const _ImageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
