// lib/screens/admin/settings/admin_app_info_board_screen.dart
//
// Admin CMS for the App Information Board section.
// Accessible via Admin Settings → Content → App Information Board.
//
// Features:
//   • Toggle section visibility
//   • Edit sectionTitle, title, subtitle, description, ctaText
//   • Toggle isLocked badge
//   • Manage feature chips (add / reorder / delete)
//   • Seeds Firestore defaults on first load

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/app_info_board_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_info_board_model.dart';
import '../../../services/app_info_board_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminAppInfoBoardScreen extends ConsumerStatefulWidget {
  const AdminAppInfoBoardScreen({super.key});

  @override
  ConsumerState<AdminAppInfoBoardScreen> createState() =>
      _AdminAppInfoBoardScreenState();
}

class _AdminAppInfoBoardScreenState extends ConsumerState<AdminAppInfoBoardScreen> {
  // Local editing state — populated from Firestore on first load
  bool _loaded = false;
  bool _saving = false;

  // Controllers
  late final TextEditingController _sectionTitleCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ctaCtrl;

  bool _sectionVisible = true;
  bool _isLocked = true;
  List<AppInfoBoardFeatureItem> _features = [];

  @override
  void initState() {
    super.initState();
    _sectionTitleCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    _subtitleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _ctaCtrl = TextEditingController();

    // Seed Firestore defaults if doc is missing
    ref.read(appInfoBoardServiceProvider).seedDefaults();
  }

  @override
  void dispose() {
    _sectionTitleCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _ctaCtrl.dispose();
    super.dispose();
  }

  void _populateFrom(AppInfoBoardModel m) {
    if (_loaded) return; // only once
    _loaded = true;
    _sectionTitleCtrl.text = m.sectionTitle;
    _titleCtrl.text = m.title;
    _subtitleCtrl.text = m.subtitle;
    _descCtrl.text = m.description;
    _ctaCtrl.text = m.ctaText;
    _sectionVisible = m.sectionVisible;
    _isLocked = m.isLocked;
    _features = List.from(m.features);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final model = AppInfoBoardModel(
        sectionVisible: _sectionVisible,
        sectionTitle: _sectionTitleCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        features: _features,
        ctaText: _ctaCtrl.text.trim(),
        isLocked: _isLocked,
      );
      await ref.read(appInfoBoardServiceProvider).saveSection(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App Information Board saved ✓'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
    final sectionAsync = ref.watch(appInfoBoardSectionProvider);

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
                color: AppColors.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.cpu, color: AppColors.secondary, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('App Information Board', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text('Save',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: col.border),
        ),
      ),
      body: sectionAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (section) {
          _populateFrom(section);
          return _buildForm(col);
        },
      ),
    );
  }

  Widget _buildForm(dynamic col) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
      children: [
        // ── Visibility toggle ──────────────────────────────────────────
        _SectionCard(
          children: [
            _SwitchRow(
              icon: Icons.visibility_outlined,
              iconColor: AppColors.primary,
              title: 'Section Visible',
              subtitle: 'Show or hide the AI Planner block on the home screen',
              value: _sectionVisible,
              onChanged: (v) async {
                setState(() => _sectionVisible = v);
                await ref.read(appInfoBoardServiceProvider).setVisible(v);
              },
            ),
            _Divider(),
            _SwitchRow(
              icon: Icons.lock_rounded,
              iconColor: AppColors.warning,
              title: 'Show "Locked" Badge',
              subtitle: 'Display the lock indicator on the card',
              value: _isLocked,
              onChanged: (v) => setState(() => _isLocked = v),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Text content ──────────────────────────────────────────────
        _SectionLabel('Text Content'),
        const SizedBox(height: 8),
        _SectionCard(
          children: [
            _TextFieldTile(
              label: 'Section Header',
              hint: 'e.g. AI Travel Assistant',
              controller: _sectionTitleCtrl,
              icon: Iconsax.text,
            ),
            _Divider(),
            _TextFieldTile(
              label: 'Card Title',
              hint: 'e.g. AI Travelling Planner',
              controller: _titleCtrl,
              icon: Iconsax.subtitle,
            ),
            _Divider(),
            _TextFieldTile(
              label: 'Card Subtitle',
              hint: 'e.g. & Travelling Companion',
              controller: _subtitleCtrl,
              icon: Iconsax.subtitle,
            ),
            _Divider(),
            _TextAreaTile(
              label: 'Description',
              hint: 'Short description of the feature...',
              controller: _descCtrl,
              icon: Iconsax.document_text,
            ),
            _Divider(),
            _TextFieldTile(
              label: 'CTA Button Text',
              hint: 'e.g. Coming Soon — Stay Tuned!',
              controller: _ctaCtrl,
              icon: Iconsax.notification_status,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Feature chips ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SectionLabel('Feature Chips'),
            ),
            TextButton.icon(
              onPressed: () => _showAddFeatureDialog(context),
              icon: const Icon(Icons.add, size: 16, color: AppColors.secondary),
              label: const Text('Add',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _features.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.col.border),
                ),
                child: Center(
                  child: Text('No feature chips. Tap Add to create one.',
                      style: TextStyle(color: context.col.textMuted, fontSize: 13)),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: context.col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.col.border),
                ),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _features.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = _features.removeAt(oldIdx);
                      _features.insert(newIdx, item);
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final f = _features[i];
                    return _FeatureTile(
                      key: ValueKey('$i-${f.iconKey}-${f.label}'),
                      feature: f,
                      onEdit: () => _showEditFeatureDialog(context, i, f),
                      onDelete: () => setState(() => _features.removeAt(i)),
                    );
                  },
                ),
              ),
        const SizedBox(height: 20),

        // ── Preview note ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap Save to push changes to the app. Changes are live immediately for all users.',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.col.textSecondary,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showAddFeatureDialog(BuildContext context) {
    _showFeatureDialog(
      context: context,
      title: 'Add Feature Chip',
      initial: const AppInfoBoardFeatureItem(iconKey: 'star', label: ''),
      onSave: (item) => setState(() => _features.add(item)),
    );
  }

  void _showEditFeatureDialog(
      BuildContext context, int index, AppInfoBoardFeatureItem initial) {
    _showFeatureDialog(
      context: context,
      title: 'Edit Feature Chip',
      initial: initial,
      onSave: (item) => setState(() => _features[index] = item),
    );
  }

  void _showFeatureDialog({
    required BuildContext context,
    required String title,
    required AppInfoBoardFeatureItem initial,
    required ValueChanged<AppInfoBoardFeatureItem> onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FeatureEditorSheet(
        title: title,
        initial: initial,
        onSave: (item) {
          Navigator.pop(context);
          onSave(item);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature tile in reorderable list
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final AppInfoBoardFeatureItem feature;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeatureTile({
    super.key,
    required this.feature,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: col.border, width: 0.5)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(feature.iconData, size: 16, color: AppColors.secondary),
        ),
        title: Text(
          feature.label,
          style: TextStyle(
              color: col.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          'Icon: ${feature.iconKey}',
          style: TextStyle(color: col.textMuted, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 16, color: col.textSecondary),
              onPressed: onEdit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.drag_handle, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature editor bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureEditorSheet extends StatefulWidget {
  final String title;
  final AppInfoBoardFeatureItem initial;
  final ValueChanged<AppInfoBoardFeatureItem> onSave;

  const _FeatureEditorSheet({
    required this.title,
    required this.initial,
    required this.onSave,
  });

  @override
  State<_FeatureEditorSheet> createState() => _FeatureEditorSheetState();
}

class _FeatureEditorSheetState extends State<_FeatureEditorSheet> {
  late final TextEditingController _labelCtrl;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initial.label);
    _selectedIconKey = widget.initial.iconKey;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: col.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(widget.title,
              style: TextStyle(
                  color: col.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),

          // Label field
          Text('Label',
              style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _labelCtrl,
            style: TextStyle(color: col.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Smart Itineraries',
              hintStyle: TextStyle(color: col.textMuted),
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
                    const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Icon picker
          Text('Icon',
              style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppInfoBoardFeatureItem.availableIcons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final opt = AppInfoBoardFeatureItem.availableIcons[i];
                final selected = opt.key == _selectedIconKey;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = opt.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 60,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.secondary.withValues(alpha: 0.18)
                          : col.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.secondary
                            : col.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppInfoBoardFeatureItem.iconDataFromKey(opt.key),
                          size: 22,
                          color: selected
                              ? AppColors.secondary
                              : col.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(opt.label,
                            style: TextStyle(
                                fontSize: 9,
                                color: selected
                                    ? AppColors.secondary
                                    : col.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.normal),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final label = _labelCtrl.text.trim();
                if (label.isEmpty) return;
                widget.onSave(
                    AppInfoBoardFeatureItem(iconKey: _selectedIconKey, label: label));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child:
                  const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.col.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: context.col.border, indent: 56, endIndent: 0);
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(color: col.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: col.textMuted,
            inactiveTrackColor: col.surfaceElevated,
          ),
        ],
      ),
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const _TextFieldTile({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(icon, size: 18, color: col.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: col.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: TextStyle(color: col.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(color: col.textMuted, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: col.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: col.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: col.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAreaTile extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const _TextAreaTile({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Icon(icon, size: 18, color: col.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: col.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: TextStyle(color: col.textPrimary, fontSize: 13),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(color: col.textMuted, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    filled: true,
                    fillColor: col.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: col.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: col.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
