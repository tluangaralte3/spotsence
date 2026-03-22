// lib/screens/admin/ventures/admin_ventures_screen.dart
//
// Manage Dare & Venture bookings — view requests, approve / reject.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';

class AdminVenturesScreen extends ConsumerWidget {
  const AdminVenturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final venturesAsync = ref.watch(adminVenturesProvider);

    return Scaffold(
      backgroundColor: col.bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_ventures_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _AddVentureSheet(),
            fullscreenDialog: true,
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'New Venture',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: venturesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (snap) {
          if (snap.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_outlined, color: col.textMuted, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'No ventures yet.',
                    style: TextStyle(color: col.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snap.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _VentureCard(doc: snap.docs[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Venture card
// ─────────────────────────────────────────────────────────────────────────────

class _VentureCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  const _VentureCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] as String? ?? 'Unnamed';
    final price = data['basePrice'] ?? data['price'] ?? 0;
    final diff = data['difficulty'] as String? ?? '';
    final dur = data['duration'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 60,
                  color: col.surfaceElevated,
                  child: Icon(Icons.explore, color: col.textMuted),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹$price',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (diff.isNotEmpty || dur.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (diff.isNotEmpty) _Tag(diff, AppColors.secondary),
                      if (dur.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Tag(dur, col.textMuted),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Delete venture?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'This is permanent.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(adminListingNotifierProvider.notifier)
          .deleteListing('tour_packages', doc.id);
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Add Venture sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddVentureSheet extends ConsumerStatefulWidget {
  const _AddVentureSheet();

  @override
  ConsumerState<_AddVentureSheet> createState() => _AddVentureSheetState();
}

class _AddVentureSheetState extends ConsumerState<_AddVentureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _location = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _duration.dispose();
    _location.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(adminListingNotifierProvider.notifier)
        .createListing('tour_packages', {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'location': _location.text.trim(),
          'imageUrl': _imageUrl.text.trim(),
          'basePrice': double.tryParse(_price.text) ?? 0,
          'duration': _duration.text.trim(),
        });
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        leading: BackButton(color: col.textPrimary),
        title: Text(
          'New Venture',
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: Text(
              'Create',
              style: const TextStyle(
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
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(
              'Name *',
              _name,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildField('Description', _desc, maxLines: 3),
            const SizedBox(height: 12),
            _buildField('Location', _location),
            const SizedBox(height: 12),
            _buildField(
              'Base Price (₹)',
              _price,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildField('Duration (e.g. 3 days)', _duration),
            const SizedBox(height: 12),
            _buildField('Image URL', _imageUrl, keyboard: TextInputType.url),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Create Venture',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: col.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: validator,
          style: TextStyle(color: col.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: col.surface,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
