// lib/screens/admin/listings/admin_add_listing_screen.dart
//
// Universal "Add / Edit" form for any listing collection.
// Route params: collection (required), docId (optional — for edit mode).

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';

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

  bool _isLoading = false;
  bool _isEditMode = false;

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
        _nameCtrl.text = d['name']?.toString() ?? '';
        _descCtrl.text = d['description']?.toString() ?? '';
        _locationCtrl.text =
            d['location']?.toString() ?? d['address']?.toString() ?? '';
        _tagsCtrl.text = (d['tags'] as List?)?.join(', ') ?? '';

        // Load existing images — spots use 'imagesUrl', others use 'images'
        final imageField = widget.collection == 'spots'
            ? 'imagesUrl'
            : 'images';
        final raw = d[imageField];
        if (raw is List) {
          _existingImageUrls.addAll(
            raw.whereType<String>().where((u) => u.isNotEmpty),
          );
        }

        // Load extra collection-specific fields
        for (final key in _extraKeys) {
          _extraControllers[key] ??= TextEditingController();
          _extraControllers[key]!.text = d[key]?.toString() ?? '';
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _extraKeys => switch (widget.collection) {
    'restaurants' || 'cafes' => ['cuisine', 'priceRange', 'openingHours'],
    'hotels' => ['starRating', 'pricePerNight', 'amenities'],
    'homestays' => ['pricePerNight', 'capacity', 'amenities'],
    'adventureSpots' => ['difficulty', 'duration', 'equipment'],
    'shoppingAreas' => ['category', 'openingHours', 'paymentMethods'],
    'events' => ['startDate', 'endDate', 'ticketPrice', 'organizer'],
    'tour_packages' => ['duration', 'basePrice', 'difficulty', 'category'],
    _ => ['district', 'category'],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _tagsCtrl.dispose();
    for (final c in _extraControllers.values) c.dispose();
    super.dispose();
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
  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];
    setState(() => _uploadingImages = true);
    final urls = <String>[];
    try {
      final bucket = widget.collection;
      for (final xFile in _newImages) {
        final ext = xFile.path.split('.').last.toLowerCase();
        final name =
            '${bucket}_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.$ext';
        final ref = FirebaseStorage.instance.ref().child(
          'admin_listings/$bucket/$name',
        );
        await ref.putFile(File(xFile.path));
        urls.add(await ref.getDownloadURL());
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
    } finally {
      setState(() => _uploadingImages = false);
    }
    return urls;
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

    // spots → 'imagesUrl'; everything else → 'images'
    final imageField = widget.collection == 'spots' ? 'imagesUrl' : 'images';

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      imageField: allImages,
      'tags': tags,
      for (final k in _extraKeys)
        if ((_extraControllers[k]?.text.trim() ?? '').isNotEmpty)
          k: _extraControllers[k]!.text.trim(),
    };

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
                  _FieldCard(
                    children: [
                      _FieldLabel('Name *'),
                      _TextField(
                        controller: _nameCtrl,
                        hint: 'e.g. Blue Mountain Homestay',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Name is required' : null,
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
                  _FieldCard(
                    children: [
                      _FieldLabel('Location / Address'),
                      _TextField(
                        controller: _locationCtrl,
                        hint: 'e.g. Aizawl, Mizoram',
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Images'),
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
                        hint: 'e.g. scenic, trekking, family',
                      ),
                    ],
                  ),
                  if (_extraKeys.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _FieldCard(
                      children: [
                        _FieldLabel('Additional Details'),
                        const SizedBox(height: 8),
                        for (final key in _extraKeys) ...[
                          _FieldLabel(_capitalise(key)),
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
