// lib/screens/admin/listings/admin_add_listing_screen.dart
//
// Universal "Add / Edit" form for any listing collection.
// Route params: collection (required), docId (optional — for edit mode).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _imageCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

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
        _imageCtrl.text = d['imageUrl']?.toString() ?? '';
        _tagsCtrl.text = (d['tags'] as List?)?.join(', ') ?? '';

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
    _imageCtrl.dispose();
    _tagsCtrl.dispose();
    for (final c in _extraControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'imageUrl': _imageCtrl.text.trim(),
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
                      _FieldLabel('Image URL'),
                      _TextField(
                        controller: _imageCtrl,
                        hint: 'https://…',
                        keyboard: TextInputType.url,
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
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
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
