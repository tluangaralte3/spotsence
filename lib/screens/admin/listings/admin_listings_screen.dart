// lib/screens/admin/listings/admin_listings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Picks the best image URL from a raw Firestore document map.
/// Field name survey across collections:
///   spots          → imagesUrl  (List)
///   restaurants/hotels/cafes/homestays/adventure/shopping → images (List)
///   events/ventures → imageUrl (String)
String? _resolveImage(Map<String, dynamic> data) {
  // Try every known List-type image field
  for (final key in const ['imagesUrl', 'images', 'imageUrls']) {
    final v = data[key];
    if (v is List && v.isNotEmpty) {
      final first = v.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
  }
  // Try every known String-type image field
  for (final key in const ['imageUrl', 'image', 'coverImage', 'thumbnail']) {
    final v = data[key]?.toString() ?? '';
    if (v.isNotEmpty) return v;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  ConsumerState<AdminListingsScreen> createState() =>
      _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGrid = false;
  bool _filterVisible = true;
  String _sortBy = 'name'; // 'name' | 'newest'
  static final _tabs = ListingTab.values;

  void _onScrollUpdate(ScrollUpdateNotification n) {
    final delta = n.scrollDelta ?? 0;
    if (delta > 4 && _filterVisible) {
      setState(() => _filterVisible = false);
    } else if (delta < -4 && !_filterVisible) {
      setState(() => _filterVisible = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(selectedListingTabProvider.notifier)
            .set(_tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final activeTab = ref.watch(selectedListingTabProvider);
    final crudState = ref.watch(adminListingNotifierProvider);

    ref.listen(adminListingNotifierProvider, (_, next) {
      if (next.isSuccess || next.isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? ''),
            backgroundColor: next.isSuccess
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(adminListingNotifierProvider.notifier).reset();
      }
    });

    // The shell's _NarrowLayout already provides a Scaffold with SafeArea on
    // the app-bar row. The inner Scaffold must NOT re-apply safe-area insets
    // or the tab bar renders below its tap target (offset by status bar height).
    return Scaffold(
      backgroundColor: col.bg,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          children: [
            // ── Row 1: Tab bar only (full width — no overlapping widgets) ──
            Material(
              color: col.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: col.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.5,
                dividerColor: col.border,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                splashFactory: InkRipple.splashFactory,
                tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
              ),
            ),
            // ── Row 2: Filter toolbar — collapses when scrolling down ────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _filterVisible
                  ? Container(
                      color: col.surface,
                      padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                      child: Row(
                        children: [
                          _SortChip(
                            label: 'Name',
                            selected: _sortBy == 'name',
                            onTap: () => setState(() => _sortBy = 'name'),
                          ),
                          const SizedBox(width: 6),
                          _SortChip(
                            label: 'Newest',
                            selected: _sortBy == 'newest',
                            onTap: () => setState(() => _sortBy = 'newest'),
                          ),
                          const Spacer(),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _isGrid = !_isGrid),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                _isGrid
                                    ? Icons.view_list_outlined
                                    : Icons.grid_view,
                                color: _isGrid
                                    ? AppColors.primary
                                    : col.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // ── Divider ────────────────────────────────────────────────────
            Divider(height: 1, color: col.border),
            // ── Tab content ────────────────────────────────────────────────
            Expanded(
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  _onScrollUpdate(n);
                  return false;
                },
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map(
                        (tab) => _ListingTabContent(
                          tab: tab,
                          isGrid: _isGrid,
                          sortBy: _sortBy,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ), // end Column
      ), // end MediaQuery.removePadding
      floatingActionButton: crudState.isLoading
          ? const FloatingActionButton(
              heroTag: 'admin_listings_fab_loading',
              onPressed: null,
              backgroundColor: AppColors.primary,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            )
          : FloatingActionButton.extended(
              heroTag: 'admin_listings_fab',
              onPressed: () =>
                  context.push('/admin/listings/add/${activeTab.collection}'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.black),
              label: Text(
                'Add ${activeTab.label}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab content
// ─────────────────────────────────────────────────────────────────────────────

class _ListingTabContent extends ConsumerWidget {
  final ListingTab tab;
  final bool isGrid;
  final String sortBy;
  const _ListingTabContent({
    required this.tab,
    required this.isGrid,
    required this.sortBy,
  });

  StreamProvider<QuerySnapshot> _provider(ListingTab t) => switch (t) {
    ListingTab.spots => adminSpotsProvider,
    ListingTab.restaurants => adminRestaurantsProvider,
    ListingTab.hotels => adminHotelsProvider,
    ListingTab.cafes => adminCafesProvider,
    ListingTab.homestays => adminHomestaysProvider,
    ListingTab.adventure => adminAdventureSpotsProvider,
    ListingTab.shopping => adminShoppingAreasProvider,
    ListingTab.events => adminEventsProvider,
    ListingTab.ventures => adminVenturesProvider,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final snapAsync = ref.watch(_provider(tab));

    return snapAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (snapshot) {
        final docs = List.of(snapshot.docs);
        // Apply sort
        if (sortBy == 'name') {
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aName = (aData['name'] ?? aData['title'] ?? '')
                .toString()
                .toLowerCase();
            final bName = (bData['name'] ?? bData['title'] ?? '')
                .toString()
                .toLowerCase();
            return aName.compareTo(bName);
          });
        } else if (sortBy == 'newest') {
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData['createdAt'];
            final bTs = bData['createdAt'];
            if (aTs is Timestamp && bTs is Timestamp) {
              return bTs.compareTo(aTs);
            }
            return 0;
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, color: col.textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No ${tab.label.toLowerCase()} yet.',
                  style: TextStyle(color: col.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (isGrid) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _GridCard(
                docId: doc.id,
                data: data,
                collection: tab.collection,
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _ListRow(
              docId: doc.id,
              data: data,
              collection: tab.collection,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List row
// ─────────────────────────────────────────────────────────────────────────────

class _ListRow extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String collection;

  const _ListRow({
    required this.docId,
    required this.data,
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final name =
        data['name'] as String? ?? data['title'] as String? ?? 'Unnamed';
    final location =
        data['location'] as String? ?? data['address'] as String? ?? '';
    final imageUrl = _resolveImage(data);

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _Thumb(imageUrl: imageUrl, size: 52, radius: 10),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: col.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: location.isNotEmpty
            ? Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: col.textSecondary, fontSize: 12),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              tooltip: 'Edit',
              onPressed: () =>
                  context.push('/admin/listings/edit/$collection/$docId'),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Delete listing?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'This will permanently remove the listing from Firestore.',
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
          .deleteListing(collection, docId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid card
// ─────────────────────────────────────────────────────────────────────────────

class _GridCard extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String collection;

  const _GridCard({
    required this.docId,
    required this.data,
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final name =
        data['name'] as String? ?? data['title'] as String? ?? 'Unnamed';
    final location =
        data['location'] as String? ?? data['address'] as String? ?? '';
    final imageUrl = _resolveImage(data);

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: _Thumb(imageUrl: imageUrl, size: double.infinity, radius: 0),
          ),
          // Info + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: col.textMuted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.secondary,
                    size: 17,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/admin/listings/edit/$collection/$docId'),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 17,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, ref),
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
          'Delete listing?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'This will permanently remove the listing from Firestore.',
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
          .deleteListing(collection, docId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort chip
// ─────────────────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : col.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : col.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : col.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared thumbnail widget
// ─────────────────────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double radius;
  const _Thumb({
    required this.imageUrl,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isExpanded = size == double.infinity;

    Widget placeholder = Container(
      width: isExpanded ? double.infinity : size,
      height: isExpanded ? double.infinity : size,
      decoration: BoxDecoration(
        color: col.surfaceElevated,
        borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
      ),
      child: Icon(
        Icons.image_outlined,
        color: col.textMuted,
        size: isExpanded ? 32 : 20,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    final img = Image.network(
      imageUrl!,
      width: isExpanded ? double.infinity : size,
      height: isExpanded ? double.infinity : size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: isExpanded ? double.infinity : size,
          height: isExpanded ? double.infinity : size,
          color: col.surfaceElevated,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );

    if (radius > 0) {
      return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
    }
    return img;
  }
}
