// lib/screens/admin/rentals/admin_add_rental_screen.dart
//
// Add / Edit form for a single equipment rental item.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rental_models.dart';
import '../../../services/rental_service.dart';

class AdminAddRentalScreen extends ConsumerStatefulWidget {
  final String? docId; // null = create, non-null = edit

  const AdminAddRentalScreen({super.key, this.docId});

  @override
  ConsumerState<AdminAddRentalScreen> createState() =>
      _AdminAddRentalScreenState();
}

class _AdminAddRentalScreenState extends ConsumerState<AdminAddRentalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _pricePerDayCtrl = TextEditingController();
  final _pricePerHourCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  // Specification key-value pairs
  final List<MapEntry<TextEditingController, TextEditingController>>
      _specFields = [];

  RentalCategory _category = RentalCategory.other;
  bool _isAvailable = true;
  bool _isFeatured = false;

  final List<XFile> _newImages = [];
  final List<String> _existingImageUrls = [];
  bool _uploadingImages = false;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.docId != null;
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _districtCtrl.dispose();
    _phoneCtrl.dispose();
    _contactNameCtrl.dispose();
    _pricePerDayCtrl.dispose();
    _pricePerHourCtrl.dispose();
    _qtyCtrl.dispose();
    for (final e in _specFields) {
      e.key.dispose();
      e.value.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final item = await RentalService().getById(widget.docId!);
    if (item == null || !mounted) return;
    setState(() {
      _nameCtrl.text = item.name;
      _descCtrl.text = item.description;
      _locationCtrl.text = item.location;
      _districtCtrl.text = item.district;
      _phoneCtrl.text = item.contactPhone;
      _contactNameCtrl.text = item.contactName;
      _pricePerDayCtrl.text = item.pricePerDay.toStringAsFixed(0);
      _pricePerHourCtrl.text = item.pricePerHour?.toStringAsFixed(0) ?? '';
      _qtyCtrl.text = item.quantityAvailable.toString();
      _category = item.category;
      _isAvailable = item.isAvailable;
      _isFeatured = item.isFeatured;
      _existingImageUrls.addAll(item.imageUrls);
      for (final e in item.specifications.entries) {
        _specFields.add(MapEntry(
          TextEditingController(text: e.key),
          TextEditingController(text: e.value),
        ));
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    for (final xFile in _newImages) {
      final file = File(xFile.path);
      final ref = storage.ref(
        'equipment_rentals/${DateTime.now().millisecondsSinceEpoch}_${xFile.name}',
      );
      await ref.putFile(file);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      setState(() => _uploadingImages = true);
      final newUrls = await _uploadImages();
      setState(() => _uploadingImages = false);

      final allUrls = [..._existingImageUrls, ...newUrls];

      final specs = <String, String>{};
      for (final e in _specFields) {
        final k = e.key.text.trim();
        final v = e.value.text.trim();
        if (k.isNotEmpty) specs[k] = v;
      }

      final pricePerHour = _pricePerHourCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_pricePerHourCtrl.text.trim());

      final item = RentalItem(
        id: widget.docId ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        pricePerDay: double.tryParse(_pricePerDayCtrl.text.trim()) ?? 0,
        pricePerHour: pricePerHour,
        imageUrls: allUrls,
        location: _locationCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim(),
        contactName: _contactNameCtrl.text.trim(),
        specifications: specs,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        quantityAvailable:
            int.tryParse(_qtyCtrl.text.trim()) ?? 1,
      );

      final service = RentalService();
      if (_isEditMode) {
        await service.update(widget.docId!, item);
      } else {
        await service.create(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Rental updated!' : 'Rental added!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.col.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Rental' : 'Add Rental',
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Images ─────────────────────────────────────────────────────
            _sectionLabel(context, 'Photos'),
            const SizedBox(height: 8),
            _ImagePickerRow(
              existingUrls: _existingImageUrls,
              newImages: _newImages,
              onPick: _pickImages,
              onRemoveExisting: (url) =>
                  setState(() => _existingImageUrls.remove(url)),
              onRemoveNew: (xf) =>
                  setState(() => _newImages.remove(xf)),
              uploading: _uploadingImages,
            ),
            const SizedBox(height: 20),

            // ── Basic info ─────────────────────────────────────────────────
            _sectionLabel(context, 'Basic Info'),
            const SizedBox(height: 8),
            _field(
              context,
              controller: _nameCtrl,
              label: 'Item Name',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _field(
              context,
              controller: _descCtrl,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // ── Category ──────────────────────────────────────────────────
            _sectionLabel(context, 'Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RentalCategory>(
              initialValue: _category,
              decoration: _inputDecoration(context, 'Category'),
              dropdownColor: context.col.surface,
              style: TextStyle(color: context.col.textPrimary, fontSize: 14),
              items: RentalCategory.values
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 20),

            // ── Pricing ────────────────────────────────────────────────────
            _sectionLabel(context, 'Pricing'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _field(
                    context,
                    controller: _pricePerDayCtrl,
                    label: 'Price / Day (₹)',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    context,
                    controller: _pricePerHourCtrl,
                    label: 'Price / Hour (₹) — optional',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              context,
              controller: _qtyCtrl,
              label: 'Quantity Available',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Location & Contact ─────────────────────────────────────────
            _sectionLabel(context, 'Location & Contact'),
            const SizedBox(height: 8),
            _field(context, controller: _locationCtrl, label: 'Location / Area'),
            const SizedBox(height: 12),
            _field(context, controller: _districtCtrl, label: 'District'),
            const SizedBox(height: 12),
            _field(context, controller: _contactNameCtrl, label: 'Contact Name'),
            const SizedBox(height: 12),
            _field(
              context,
              controller: _phoneCtrl,
              label: 'Contact Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // ── Specifications ─────────────────────────────────────────────
            _sectionLabel(context, 'Specifications (optional)'),
            const SizedBox(height: 8),
            ..._specFields.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _field(context,
                          controller: e.key, label: 'Key (e.g. Weight)'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _field(context,
                          controller: e.value, label: 'Value (e.g. 2 kg)'),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.minus_cirlce,
                          color: AppColors.error, size: 20),
                      onPressed: () => setState(() => _specFields.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() {
                _specFields.add(MapEntry(
                  TextEditingController(),
                  TextEditingController(),
                ));
              }),
              icon: const Icon(Iconsax.add, size: 16),
              label: const Text('Add Specification'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            const SizedBox(height: 20),

            // ── Status toggles ─────────────────────────────────────────────
            _sectionLabel(context, 'Status'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.col.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.col.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Available for Rent',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    value: _isAvailable,
                    activeThumbColor: AppColors.success,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                  Divider(height: 1, color: context.col.border),
                  SwitchListTile(
                    title: Text(
                      'Featured on Home Screen',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    value: _isFeatured,
                    activeThumbColor: AppColors.warning,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: context.col.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: context.col.textPrimary, fontSize: 14),
      decoration: _inputDecoration(context, label),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.col.textSecondary, fontSize: 13),
      filled: true,
      fillColor: context.col.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.col.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.col.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Picker Row
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePickerRow extends StatelessWidget {
  final List<String> existingUrls;
  final List<XFile> newImages;
  final VoidCallback onPick;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<XFile> onRemoveNew;
  final bool uploading;

  const _ImagePickerRow({
    required this.existingUrls,
    required this.newImages,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: uploading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      Iconsax.camera,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
          ),
          // Existing URLs
          ...existingUrls.map(
            (url) => _ImageThumb(
              child: Image.network(url, fit: BoxFit.cover),
              onRemove: () => onRemoveExisting(url),
            ),
          ),
          // New picked images
          ...newImages.map(
            (xf) => _ImageThumb(
              child: Image.file(File(xf.path), fit: BoxFit.cover),
              onRemove: () => onRemoveNew(xf),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _ImageThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
