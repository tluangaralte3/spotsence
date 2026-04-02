// lib/screens/admin/visitor_guides/admin_visitor_guide_screen.dart
//
// Admin CMS for per-state Visitor Guides.
// Shows a list of all 8 NE states with their current Firestore status.
// Tap any state to open an edit page with:
//   • Banner image upload
//   • Emoji, tagline, about fields
//   • Dos / don'ts lists (add / reorder / delete)
//   • Quick-facts list (label + value)
//   • Published toggle
//   • Save to Firestore

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/visitor_guide_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/visitor_guide_model.dart';
import '../../../services/visitor_guide_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// All known NE states and their default emoji
// ─────────────────────────────────────────────────────────────────────────────

const _kStates = [
  (key: 'Mizoram', emoji: '🏔️', displayName: 'Mizoram'),
  (key: 'Manipur', emoji: '💎', displayName: 'Manipur'),
  (key: 'Meghalaya', emoji: '☁️', displayName: 'Meghalaya'),
  (key: 'Assam', emoji: '🦏', displayName: 'Assam'),
  (key: 'Nagaland', emoji: '🦅', displayName: 'Nagaland'),
  (key: 'Tripura', emoji: '🏛️', displayName: 'Tripura'),
  (key: 'Arunachal', emoji: '🌄', displayName: 'Arunachal Pradesh'),
  (key: 'Sikkim', emoji: '🏔️', displayName: 'Sikkim'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminVisitorGuideScreen extends ConsumerWidget {
  const AdminVisitorGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidesAsync = ref.watch(allVisitorGuidesProvider);
    final col = context.col;

    // Build a lookup map from the stream result
    final Map<String, VisitorGuideModel> guideMap = {};
    guidesAsync.asData?.value.forEach((g) {
      guideMap[g.id] = g;
    });

    return Scaffold(
      backgroundColor: col.bg,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Material(
              color: col.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      'Visitor Guides',
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${guideMap.length} / ${_kStates.length} configured',
                      style: TextStyle(
                          color: col.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: col.border),

            // ── List ───────────────────────────────────────────────────
            Expanded(
              child: guidesAsync.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: _kStates.length,
                        separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final state = _kStates[i];
                        final guide = guideMap[state.key];
                        return _StateCard(
                          stateKey: state.key,
                          displayName: state.displayName,
                          emoji: state.emoji,
                          guide: guide,
                          onTap: () => _openEditor(
                            context,
                            stateKey: state.key,
                            displayName: state.displayName,
                            defaultEmoji: state.emoji,
                            existing: guide,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    {
    required String stateKey,
    required String displayName,
    required String defaultEmoji,
    VisitorGuideModel? existing,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideEditorPage(
          stateKey: stateKey,
          displayName: displayName,
          defaultEmoji: defaultEmoji,
          existing: existing,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State card in the list
// ─────────────────────────────────────────────────────────────────────────────

class _StateCard extends StatelessWidget {
  final String stateKey;
  final String displayName;
  final String emoji;
  final VisitorGuideModel? guide;
  final VoidCallback onTap;

  const _StateCard({
    required this.stateKey,
    required this.displayName,
    required this.emoji,
    required this.guide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final hasGuide = guide != null;
    final isPublished = guide?.isPublished ?? false;

    return Material(
      color: col.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Banner thumbnail or emoji placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: (guide?.bannerImageUrl.isNotEmpty == true)
                      ? CachedNetworkImage(
                          imageUrl: guide!.bannerImageUrl,
                          fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                              _EmojiBox(emoji: emoji),
                        )
                      : _EmojiBox(emoji: emoji),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasGuide
                          ? (guide!.tagline.isNotEmpty
                              ? guide!.tagline
                              : 'No tagline set')
                          : 'Not yet configured',
                      style: TextStyle(
                          color: col.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(
                          label: isPublished
                              ? 'Published'
                              : hasGuide
                                  ? 'Draft'
                                  : 'Not Created',
                          color: isPublished
                              ? AppColors.success
                              : hasGuide
                                  ? AppColors.warning
                                  : col.textMuted,
                        ),
                        if (hasGuide) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${guide!.dos.length} dos · ${guide!.donts.length} don\'ts',
                            style: TextStyle(
                                color: col.textMuted, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: col.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiBox extends StatelessWidget {
  final String emoji;
  const _EmojiBox({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceElevated,
      child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 26))),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor page — ConsumerStatefulWidget
// ─────────────────────────────────────────────────────────────────────────────

class GuideEditorPage extends ConsumerStatefulWidget {
  final String stateKey;
  final String displayName;
  final String defaultEmoji;
  final VisitorGuideModel? existing;

  const GuideEditorPage({
    required this.stateKey,
    required this.displayName,
    required this.defaultEmoji,
    required this.existing,
    super.key,
  });

  @override
  ConsumerState<GuideEditorPage> createState() =>
      _GuideEditorPageState();
}

class _GuideEditorPageState extends ConsumerState<GuideEditorPage> {
  late final TextEditingController _tagline;
  late final TextEditingController _about;
  late final TextEditingController _emoji;

  late List<String> _dos;
  late List<String> _donts;
  late List<GuideQuickFact> _facts;
  late bool _isPublished;
  late String _bannerImageUrl;

  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _tagline = TextEditingController(text: g?.tagline ?? '');
    _about = TextEditingController(text: g?.about ?? '');
    _emoji = TextEditingController(
        text: g?.emoji ?? widget.defaultEmoji);
    _dos = List<String>.from(g?.dos ?? []);
    _donts = List<String>.from(g?.donts ?? []);
    _facts = List<GuideQuickFact>.from(g?.facts ?? []);
    _isPublished = g?.isPublished ?? false;
    _bannerImageUrl = g?.bannerImageUrl ?? '';
  }

  @override
  void dispose() {
    _tagline.dispose();
    _about.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final service = ref.read(visitorGuideServiceProvider);
      final url = await service.uploadBannerImage(
        stateKey: widget.stateKey,
        bytes: bytes,
        extension: ext,
      );
      setState(() => _bannerImageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (_tagline.text.trim().isEmpty && _about.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least a tagline or about text.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final guide = VisitorGuideModel(
        id: widget.stateKey,
        stateName: widget.displayName,
        emoji: _emoji.text.trim().isEmpty
            ? widget.defaultEmoji
            : _emoji.text.trim(),
        tagline: _tagline.text.trim(),
        about: _about.text.trim(),
        bannerImageUrl: _bannerImageUrl,
        dos: _dos,
        donts: _donts,
        facts: _facts,
        isPublished: _isPublished,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(visitorGuideServiceProvider)
          .saveGuide(widget.stateKey, guide);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.displayName} guide saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addDo() => _showAddItemDialog(
        title: 'Add Do',
        hint: 'e.g. Remove footwear before entering homes',
        onAdd: (v) => setState(() => _dos.add(v)),
      );

  void _addDont() => _showAddItemDialog(
        title: 'Add Don\'t',
        hint: 'e.g. Don\'t photograph military installations',
        onAdd: (v) => setState(() => _donts.add(v)),
      );

  void _addFact() => _showAddFactDialog();

  void _showAddItemDialog({
    required String title,
    required String hint,
    required void Function(String) onAdd,
  }) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(title,
            style: TextStyle(color: context.col.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          style: TextStyle(color: context.col.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.col.textMuted),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) {
                onAdd(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddFactDialog({int? editIndex}) {
    final labelCtrl = TextEditingController(
        text: editIndex != null ? _facts[editIndex].label : '');
    final valueCtrl = TextEditingController(
        text: editIndex != null ? _facts[editIndex].value : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(editIndex == null ? 'Add Quick Fact' : 'Edit Fact',
            style: TextStyle(color: context.col.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: TextStyle(color: context.col.textPrimary),
              decoration: InputDecoration(
                labelText: 'Label (e.g. Population)',
                labelStyle:
                    TextStyle(color: context.col.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              style: TextStyle(color: context.col.textPrimary),
              decoration: InputDecoration(
                labelText: 'Value (e.g. ~1.1 Million)',
                labelStyle:
                    TextStyle(color: context.col.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            onPressed: () {
              final label = labelCtrl.text.trim();
              final value = valueCtrl.text.trim();
              if (label.isNotEmpty && value.isNotEmpty) {
                setState(() {
                  final fact = GuideQuickFact(
                      label: label, value: value, iconName: 'info');
                  if (editIndex != null) {
                    _facts[editIndex] = fact;
                  } else {
                    _facts.add(fact);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Text(
          '${_emoji.text.isNotEmpty ? "${_emoji.text} " : ""}${widget.displayName}',
          style: TextStyle(
            color: col.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('Save'),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _SectionTitle('Banner Image'),
          const SizedBox(height: 8),
          _BannerImagePicker(
            imageUrl: _bannerImageUrl,
            uploading: _uploadingImage,
            onTap: _pickBanner,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Basic Info'),
          const SizedBox(height: 8),
          _EditorField(
            label: 'Emoji',
            controller: _emoji,
            hint: '🏔️',
            maxLines: 1,
          ),
          const SizedBox(height: 10),
          _EditorField(
            label: 'Tagline',
            controller: _tagline,
            hint: 'e.g. Land of the Blue Mountains',
            maxLines: 1,
          ),
          const SizedBox(height: 20),
          _SectionTitle('About'),
          const SizedBox(height: 8),
          _EditorField(
            label: 'About the state',
            controller: _about,
            hint: 'Write a short description of the state for visitors…',
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          _SectionTitle('Quick Facts'),
          const SizedBox(height: 8),
          ..._facts.asMap().entries.map(
                (e) => _FactChip(
                  fact: e.value,
                  onEdit: () => _showAddFactDialog(editIndex: e.key),
                  onDelete: () => setState(() => _facts.removeAt(e.key)),
                ),
              ),
          _AddButton(label: 'Add Quick Fact', onTap: _addFact),
          const SizedBox(height: 20),
          _SectionTitle('What To Do ✅'),
          const SizedBox(height: 8),
          ..._dos.asMap().entries.map(
                (e) => _ListItemChip(
                  text: e.value,
                  color: AppColors.success,
                  onDelete: () => setState(() => _dos.removeAt(e.key)),
                ),
              ),
          _AddButton(label: 'Add Do', onTap: _addDo),
          const SizedBox(height: 20),
          _SectionTitle('What Not To Do 🚫'),
          const SizedBox(height: 8),
          ..._donts.asMap().entries.map(
                (e) => _ListItemChip(
                  text: e.value,
                  color: AppColors.error,
                  onDelete: () => setState(() => _donts.removeAt(e.key)),
                ),
              ),
          _AddButton(label: 'Add Don\'t', onTap: _addDont),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: col.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  color: _isPublished ? AppColors.success : col.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Published',
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isPublished
                            ? 'Visible to users in the app'
                            : 'Hidden from users (draft)',
                        style: TextStyle(
                          color: col.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable editor components
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.col.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _EditorField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: col.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: col.textMuted, fontSize: 14),
            filled: true,
            fillColor: col.surfaceElevated,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _BannerImagePicker extends StatelessWidget {
  final String imageUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _BannerImagePicker({
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          color: col.surfaceElevated,
        ),
        child: uploading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 10),
                    Text('Uploading…',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              )
            : imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('Change',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 36),
                      const SizedBox(height: 8),
                      Text('Tap to upload banner image',
                          style: TextStyle(
                              color: col.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Recommended: 1200×400 px',
                          style: TextStyle(
                              color: col.textMuted, fontSize: 11)),
                    ],
                  ),
      ),
    );
  }
}

class _ListItemChip extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onDelete;

  const _ListItemChip({
    required this.text,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.drag_handle_rounded,
              color: context.col.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 13,
                    height: 1.4)),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final GuideQuickFact fact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FactChip({
    required this.fact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: col.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '${fact.label}: ',
                  style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: fact.value,
                  style: TextStyle(
                      color: col.textPrimary,
                      fontSize: 12),
                ),
              ]),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined,
                color: col.textSecondary, size: 16),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded,
                color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
