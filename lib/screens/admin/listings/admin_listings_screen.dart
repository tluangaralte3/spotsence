// lib/screens/admin/listings/admin_listings_screen.dart
//
// Tabbed listings management for all content types.
// Each tab shows a searchable, scrollable list with edit / delete.
// The FAB opens AdminAddListingScreen for the active collection.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  ConsumerState<AdminListingsScreen> createState() =>
      _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _search = TextEditingController();
  String _query = '';

  static final _tabs = ListingTab.values;

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
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final activeTab = ref.watch(selectedListingTabProvider);
    final crudState = ref.watch(adminListingNotifierProvider);

    // Show snackbar on crud result
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

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        title: Text(
          'Listings',
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: TextStyle(color: col.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name…',
                    hintStyle: TextStyle(color: col.textMuted),
                    prefixIcon: Icon(Icons.search, color: col.textMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: col.textMuted),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: col.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: col.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((tab) => _ListingTabContent(tab: tab, query: _query))
            .toList(),
      ),
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
// One tab's content
// ─────────────────────────────────────────────────────────────────────────────

class _ListingTabContent extends ConsumerWidget {
  final ListingTab tab;
  final String query;

  const _ListingTabContent({required this.tab, required this.query});

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
        var docs = snapshot.docs;

        // Client-side filter by query
        if (query.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = (data['name'] as String? ?? '').toLowerCase();
            return name.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, color: col.textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  query.isNotEmpty
                      ? 'No results for "$query"'
                      : 'No ${tab.label.toLowerCase()} yet.',
                  style: TextStyle(color: col.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _ListingRow(
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
// Single listing row
// ─────────────────────────────────────────────────────────────────────────────

class _ListingRow extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String collection;

  const _ListingRow({
    required this.docId,
    required this.data,
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final name = data['name'] as String? ?? 'Unnamed';
    final location =
        data['location'] as String? ?? data['address'] as String? ?? '';
    final imageUrl =
        data['imageUrl'] as String? ??
        (data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty
            ? (data['imageUrls'] as List).first as String
            : null);

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlaceholderIcon(col: col),
                )
              : _PlaceholderIcon(col: col),
        ),
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

class _PlaceholderIcon extends StatelessWidget {
  final AppColorScheme col;
  const _PlaceholderIcon({required this.col});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: col.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.image_outlined, color: col.textMuted, size: 20),
  );
}
