// lib/screens/admin/banners/admin_banners_screen.dart
//
// Admin panel for managing home-screen banners.
// Features:
//   • List all banners (active + inactive)
//   • Toggle section-level visibility
//   • Add / Edit / Delete individual banners
//   • Toggle per-banner active state

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/banner_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/banner_model.dart';
import '../../../services/banner_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Banners Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final configAsync = ref.watch(bannerSectionConfigProvider);
    final bannersAsync = ref.watch(allBannersProvider);

    return Scaffold(
      backgroundColor: col.bg,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Material(
              color: col.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Home Banners',
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Iconsax.add_circle,
                          color: AppColors.primary),
                      tooltip: 'Add banner',
                      onPressed: () => _openEditor(context, ref, null),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: col.border),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Section visibility toggle ──────────────────────
                  configAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cfg) => _SectionVisibilityCard(
                      visible: cfg.sectionVisible,
                      onToggle: (v) => ref
                          .read(bannerServiceProvider)
                          .setSectionVisible(v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Banners list ───────────────────────────────────
                  Text(
                    'Banners',
                    style: TextStyle(
                      color: col.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  bannersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text(
                      'Error: $e',
                      style: TextStyle(color: col.textSecondary),
                    ),
                    data: (banners) {
                      if (banners.isEmpty) {
                        return _EmptyBannersState(
                          onAdd: () => _openEditor(context, ref, null),
                        );
                      }
                      return Column(
                        children: banners
                            .map((b) => _BannerListTile(
                                  banner: b,
                                  onEdit: () =>
                                      _openEditor(context, ref, b),
                                  onToggle: () => ref
                                      .read(bannerServiceProvider)
                                      .toggleBannerActive(b),
                                  onDelete: () =>
                                      _confirmDelete(context, ref, b),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, BannerModel? banner) {
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete banner?'),
        content: Text(
            '"${banner.title}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bannerServiceProvider).deleteBanner(banner.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
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
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Icon(Iconsax.eye, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
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
                  'Controls whether the carousel is visible on the home screen',
                  style: TextStyle(
                      color: col.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
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
// Banner List Tile
// ─────────────────────────────────────────────────────────────────────────────

class _BannerListTile extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerListTile({
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
        border: Border.all(color: col.border),
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
                  width: 64,
                  height: 50,
                  child: banner.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _PlaceholderThumb(),
                        )
                      : _PlaceholderThumb(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title.isEmpty ? '(No title)' : banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (banner.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        banner.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: col.textSecondary, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: banner.linkType == BannerLinkType.none
                              ? 'No link'
                              : banner.linkType ==
                                      BannerLinkType.internalRoute
                                  ? 'Internal'
                                  : 'External',
                          color: banner.linkType == BannerLinkType.none
                              ? col.textMuted
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Active toggle
              Switch(
                value: banner.isActive,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.primary,
              ),
              // Delete
              IconButton(
                icon: Icon(Iconsax.trash,
                    size: 18, color: Colors.red.shade400),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceElevated,
      child: Icon(Iconsax.image, size: 20, color: context.col.textMuted),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyBannersState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBannersState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Iconsax.image, size: 48, color: col.textMuted),
          const SizedBox(height: 12),
          Text(
            'No banners yet',
            style: TextStyle(
                color: col.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first promotion or announcement',
            textAlign: TextAlign.center,
            style: TextStyle(color: col.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner Editor Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BannerEditorSheet extends StatefulWidget {
  final BannerModel? existing;
  final ValueChanged<BannerModel> onSave;

  const _BannerEditorSheet({this.existing, required this.onSave});

  @override
  State<_BannerEditorSheet> createState() => _BannerEditorSheetState();
}

class _BannerEditorSheetState extends State<_BannerEditorSheet> {
  late final _titleCtrl = TextEditingController(
      text: widget.existing?.title ?? '');
  late final _subtitleCtrl = TextEditingController(
      text: widget.existing?.subtitle ?? '');
  late final _linkValueCtrl = TextEditingController(
      text: widget.existing?.linkValue ?? '');
  late BannerLinkType _linkType =
      widget.existing?.linkType ?? BannerLinkType.none;
  late bool _isActive = widget.existing?.isActive ?? true;

  /// Existing network image URL (from Firestore). Cleared when a new file
  /// is picked so the UI shows the local preview instead.
  late String _existingImageUrl = widget.existing?.imageUrl ?? '';

  XFile? _pickedFile;   // newly picked local file
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
      _existingImageUrl = ''; // local preview takes over
    });
  }

  /// Uploads [_pickedFile] to Firebase Storage under `banners/` and returns
  /// the download URL. Returns [_existingImageUrl] unchanged when no new
  /// file was picked.
  Future<String> _uploadImageIfNeeded() async {
    if (_pickedFile == null) return _existingImageUrl;
    setState(() => _uploading = true);
    try {
      final ext = _pickedFile!.path.split('.').last.toLowerCase();
      final name =
          'banner_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref('banners/$name');
      final bytes = await _pickedFile!.readAsBytes();
      final snapshot = await ref.putData(
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
          SnackBar(content: Text('Upload failed: $e')),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: col.bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
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
                  color: col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Banner' : 'New Banner',
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),

            _Field(label: 'Title', controller: _titleCtrl),
            const SizedBox(height: 12),
            _Field(
                label: 'Subtitle',
                controller: _subtitleCtrl,
                maxLines: 2),
            const SizedBox(height: 16),

            // ── Image picker ──────────────────────────────────────────
            Text(
              'Banner Image',
              style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploading || _saving ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_pickedFile != null || _existingImageUrl.isNotEmpty)
                        ? AppColors.primary
                        : col.border,
                    width: (_pickedFile != null || _existingImageUrl.isNotEmpty)
                        ? 1.5
                        : 1,
                  ),
                ),
                child: _uploading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _pickedFile != null
                        // Local preview
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_pickedFile!.path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _ImageBadge(label: 'Change'),
                              ),
                            ],
                          )
                        : _existingImageUrl.isNotEmpty
                            // Existing network image
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _existingImageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _PickerPlaceholder(),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _ImageBadge(label: 'Change'),
                                  ),
                                ],
                              )
                            // Nothing picked yet
                            : _PickerPlaceholder(),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Link type',
              style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
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
                          color: selected
                              ? AppColors.primary
                              : col.border,
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
                          fontSize: 12,
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
            Row(
              children: [
                Icon(Iconsax.eye,
                    size: 18, color: col.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Active',
                  style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_saving || _uploading) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        Text(
          label,
          style: TextStyle(
              color: col.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: col.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: col.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image picker helper widgets ───────────────────────────────────────────────

class _PickerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.image, size: 32, color: col.textMuted),
        const SizedBox(height: 8),
        Text(
          'Tap to pick an image',
          style: TextStyle(color: col.textMuted, fontSize: 12),
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
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
