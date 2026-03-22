// lib/screens/admin/ventures/admin_ventures_screen.dart
//
// Admin "Ventures" tab — shows all adventureSpot packages,
// plus collectionGroup streams for registrations and feedback.
// Adding / editing ventures is done via AdminVentureFormScreen
// (accessible from Listings → Adventure, or the "New Venture" button here).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../controllers/admin_controller.dart';

String _firstNonEmptyString(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final k in keys) {
    final v = data[k];
    if (v == null) continue;
    final s = v.toString();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return fallback;
}

double _readDouble(
  Map<String, dynamic> data,
  String key, {
  double fallback = 0,
}) {
  final v = data[key];
  if (v is num) return v.toDouble();
  if (v == null) return fallback;
  return double.tryParse(v.toString()) ?? fallback;
}

bool _readBool(
  Map<String, dynamic> data,
  String key, {
  required bool fallback,
}) {
  final v = data[key];
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return fallback;
}

int _readListLen(Map<String, dynamic> data, String key) {
  final v = data[key];
  return v is List ? v.length : 0;
}

String? _readFirstImageUrl(Map<String, dynamic> data) {
  final v = data['images'];
  if (v is List && v.isNotEmpty) {
    final s = v.first?.toString() ?? '';
    if (s.isNotEmpty && s != 'null') return s;
  }
  final single = data['imageUrl']?.toString() ?? '';
  if (single.isNotEmpty && single != 'null') return single;
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of all venture packages from the 'ventures' collection.
final venturePackagesProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('ventures')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// All registrations across every venture (Firestore collectionGroup).
final allVentureRegistrationsProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('registrations')
      .snapshots();
});

/// All feedback across every adventureSpot (Firestore collectionGroup).
final allVentureFeedbackProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance.collectionGroup('feedback').snapshots();
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen — NOTE: no Scaffold here; the AdminShell already provides one.
// ─────────────────────────────────────────────────────────────────────────────

class AdminVenturesScreen extends ConsumerStatefulWidget {
  const AdminVenturesScreen({super.key});

  @override
  ConsumerState<AdminVenturesScreen> createState() =>
      _AdminVenturesScreenState();
}

class _AdminVenturesScreenState extends ConsumerState<AdminVenturesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: col.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏕️  Ventures',
                            style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            'Packages · Registrations · Feedback',
                            style: TextStyle(
                              color: col.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push('ventures/add'),
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'New Venture',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: col.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: col.border,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Packages'),
                    Tab(text: 'Registrations'),
                    Tab(text: 'Feedback'),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: col.border),
          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _PackagesTab(),
                _RegistrationsTab(),
                _FeedbackTab(),
              ],
            ),
          ),
        ],
      ), // end body Column
    ); // end Scaffold
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Packages tab
// ─────────────────────────────────────────────────────────────────────────────

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(venturePackagesProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              Text(
                'Could not load ventures',
                style: TextStyle(color: context.col.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (snap) {
        if (snap.docs.isEmpty) {
          return _EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'No venture packages yet',
            subtitle:
                'Create your first adventure venture. Once added it will appear here for you to manage.',
            actionLabel: 'Add First Venture',
            onAction: () => context.push(AppRoutes.adminAddVenturePath()),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final doc = snap.docs[i];
            try {
              final raw = doc.data();
              final map = (raw is Map<String, dynamic>)
                  ? raw
                  : (raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : <String, dynamic>{});
              return _PackageCard(docId: doc.id, data: map);
            } catch (e) {
              final col = context.col;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: col.border),
                ),
                child: Text(
                  'Invalid venture data (${doc.id}): $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _PackageCard extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _PackageCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final title = _firstNonEmptyString(data, const [
      'title',
      'name',
    ], fallback: 'Untitled');
    final category = _firstNonEmptyString(data, const ['category']);
    final difficulty = _firstNonEmptyString(data, const ['difficulty']);
    final startingPrice = _readDouble(data, 'startingPrice');
    final isAvailable = _readBool(data, 'isAvailable', fallback: true);
    final isFeatured = _readBool(data, 'isFeatured', fallback: false);
    final tiers = _readListLen(data, 'pricingTiers');
    final medals = _readListLen(data, 'medals');
    final challenges = _readListLen(data, 'challenges');
    final imageUrl = _readFirstImageUrl(data);

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Image.network(
                imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                        title,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFeatured) ...[
                      const SizedBox(width: 6),
                      _Badge('⭐ Featured', AppColors.primary),
                    ],
                    if (!isAvailable) ...[
                      const SizedBox(width: 4),
                      _Badge('Closed', AppColors.error),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (category.isNotEmpty)
                      _Badge(category, context.col.textMuted),
                    if (difficulty.isNotEmpty)
                      _Badge(difficulty, _diffColor(difficulty)),
                    _Badge(
                      '₹${startingPrice.toStringAsFixed(0)}+',
                      AppColors.primary,
                    ),
                    _Badge(
                      '$tiers pkg${tiers == 1 ? '' : 's'}',
                      col.textSecondary,
                    ),
                    _Badge('$medals medals', const Color(0xFFF59E0B)),
                    _Badge('$challenges dares', const Color(0xFF8B5CF6)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.adminEditVenturePath(docId)),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
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

  Color _diffColor(String d) => switch (d.toLowerCase()) {
    'easy' => const Color(0xFF22C55E),
    'moderate' => const Color(0xFFF59E0B),
    'challenging' => const Color(0xFFEF4444),
    'extreme' => const Color(0xFF7C3AED),
    _ => const Color(0xFF6B7280),
  };

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Delete venture?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'All registrations and feedback will remain in Firestore.',
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
    if (ok == true) {
      await ref
          .read(adminListingNotifierProvider.notifier)
          .deleteListing('ventures', docId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Registrations tab
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrationsTab extends ConsumerWidget {
  const _RegistrationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final async = ref.watch(allVentureRegistrationsProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 8),
            Text(
              'Could not load registrations',
              style: TextStyle(color: col.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              e.toString(),
              style: const TextStyle(color: AppColors.error, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (snap) {
        if (snap.docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.how_to_reg_outlined,
            title: 'No registrations yet',
            subtitle:
                'Once users book a venture package, their registrations will show up here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final doc = snap.docs[i];
            try {
              final raw = doc.data();
              final map = (raw is Map<String, dynamic>)
                  ? raw
                  : (raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : <String, dynamic>{});
              return _RegistrationCard(docId: doc.id, data: map);
            } catch (e) {
              final col = ctx.col;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: col.border),
                ),
                child: Text(
                  'Invalid registration data (${doc.id}): $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _RegistrationCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final userName = _firstNonEmptyString(data, const [
      'userName',
      'displayName',
    ], fallback: 'User');
    final userEmail = _firstNonEmptyString(data, const ['userEmail']);
    final ventureName = _firstNonEmptyString(data, const [
      'ventureName',
    ], fallback: 'Venture');
    final status = _firstNonEmptyString(data, const [
      'status',
    ], fallback: 'pending');
    final persons = _readDouble(data, 'numberOfPersons', fallback: 1).toInt();
    final tierName = _firstNonEmptyString(data, const ['selectedTier']);
    final totalPrice = _readDouble(data, 'totalPrice');
    final addons = _readListLen(data, 'selectedAddons');
    final ts = data['createdAt'];
    final dateStr = ts is Timestamp
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';

    final statusColor = switch (status) {
      'confirmed' => const Color(0xFF22C55E),
      'cancelled' => AppColors.error,
      'completed' => AppColors.primary,
      _ => const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: TextStyle(color: col.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              _Badge(
                status.isNotEmpty
                    ? status[0].toUpperCase() + status.substring(1)
                    : 'Pending',
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _InfoChip(Icons.explore_outlined, ventureName),
              _InfoChip(
                Icons.people_outlined,
                '$persons person${persons == 1 ? '' : 's'}',
              ),
              if (tierName.isNotEmpty)
                _InfoChip(Icons.layers_outlined, tierName),
              _InfoChip(
                Icons.currency_rupee,
                '₹${totalPrice.toStringAsFixed(0)}',
              ),
              if (addons > 0)
                _InfoChip(
                  Icons.backpack_outlined,
                  '$addons add-on${addons == 1 ? '' : 's'}',
                ),
              if (dateStr.isNotEmpty)
                _InfoChip(Icons.calendar_today_outlined, dateStr),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback tab
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackTab extends ConsumerWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final async = ref.watch(allVentureFeedbackProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 8),
            Text(
              'Could not load feedback',
              style: TextStyle(color: col.textSecondary),
            ),
          ],
        ),
      ),
      data: (snap) {
        if (snap.docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No feedback yet',
            subtitle:
                'After users complete a venture and leave a review, ratings and comments will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final doc = snap.docs[i];
            try {
              final raw = doc.data();
              final map = (raw is Map<String, dynamic>)
                  ? raw
                  : (raw is Map
                        ? Map<String, dynamic>.from(raw)
                        : <String, dynamic>{});
              return _FeedbackCard(data: map);
            } catch (e) {
              final col = ctx.col;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: col.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: col.border),
                ),
                child: Text(
                  'Invalid feedback data (${doc.id}): $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final userName = _firstNonEmptyString(data, const [
      'userName',
      'displayName',
    ], fallback: 'User');
    final ventureName = _firstNonEmptyString(data, const [
      'ventureName',
    ], fallback: 'Venture');
    final rating = _readDouble(data, 'rating');
    final comment = _firstNonEmptyString(data, const ['comment']);
    final ts = data['createdAt'];
    final dateStr = ts is Timestamp
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      ventureName,
                      style: TextStyle(color: col.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(dateStr, style: TextStyle(color: col.textMuted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: context.col.textMuted),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(color: context.col.textSecondary, fontSize: 11),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: col.surface,
                shape: BoxShape.circle,
                border: Border.all(color: col.border, width: 1.5),
              ),
              child: Icon(icon, color: col.textMuted, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
