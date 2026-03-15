import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/bucket_list_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unified listing result — flattened from any Firestore collection
// ─────────────────────────────────────────────────────────────────────────────

class _ListingResult {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final double rating;
  final String collection;
  final BucketCategory bucketCategory;

  const _ListingResult({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.collection,
    required this.bucketCategory,
  });

  static _ListingResult fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String collection,
    BucketCategory category,
  ) {
    final d = doc.data() ?? {};
    final images =
        (d['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return _ListingResult(
      id: doc.id,
      name: d['name']?.toString() ?? d['title']?.toString() ?? '',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      imageUrl:
          d['imageUrl']?.toString() ??
          d['image']?.toString() ??
          (images.isNotEmpty ? images.first : ''),
      rating: ((d['rating'] ?? d['averageRating']) as num?)?.toDouble() ?? 0.0,
      collection: collection,
      bucketCategory: category,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collection tab config
// ─────────────────────────────────────────────────────────────────────────────

class _TabConfig {
  final String label;
  final String emoji;
  final String collection;
  final BucketCategory category;
  const _TabConfig(this.label, this.emoji, this.collection, this.category);

  @override
  bool operator ==(Object other) =>
      other is _TabConfig && other.collection == collection;

  @override
  int get hashCode => collection.hashCode;
}

const _tabs = [
  _TabConfig('Spots', '\u{1F5FA}\uFE0F', 'spots', BucketCategory.spot),
  _TabConfig(
    'Restaurants',
    '\u{1F37D}\uFE0F',
    'restaurants',
    BucketCategory.restaurant,
  ),
  _TabConfig('Caf\u00E9s', '\u2615', 'cafes', BucketCategory.cafe),
  _TabConfig('Hotels', '\u{1F3E8}', 'hotels', BucketCategory.hotel),
  _TabConfig('Homestays', '\u{1F3E1}', 'homestays', BucketCategory.homestay),
  _TabConfig(
    'Adventure',
    '\u{1F9D7}',
    'adventureSpots',
    BucketCategory.adventure,
  ),
  _TabConfig(
    'Shopping',
    '\u{1F6CD}\uFE0F',
    'shoppingAreas',
    BucketCategory.shopping,
  ),
  _TabConfig('Custom', '\u270F\uFE0F', '', BucketCategory.other),
];

// ─────────────────────────────────────────────────────────────────────────────
// Provider — fetches listings for a given collection (cached, auto-dispose)
// ─────────────────────────────────────────────────────────────────────────────

final _listingSearchProvider = FutureProvider.autoDispose
    .family<List<_ListingResult>, _TabConfig>((ref, tab) async {
      if (tab.collection.isEmpty) return [];
      final db = FirebaseFirestore.instance;
      try {
        final snap = await db
            .collection(tab.collection)
            .orderBy('name')
            .limit(80)
            .get();
        return _mapDocs(snap.docs, tab);
      } catch (_) {
        // Fallback without orderBy if index is missing
        final snap = await db.collection(tab.collection).limit(80).get();
        return _mapDocs(snap.docs, tab);
      }
    });

List<_ListingResult> _mapDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  _TabConfig tab,
) {
  return docs
      .where((d) {
        final status = d.data()['status']?.toString().toLowerCase() ?? '';
        return status.isEmpty ||
            status == 'approved' ||
            status == 'active' ||
            status == 'published';
      })
      .map((d) => _ListingResult.fromDoc(d, tab.collection, tab.category))
      .where((r) => r.name.isNotEmpty)
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// AddBucketItemScreen
// ─────────────────────────────────────────────────────────────────────────────

class AddBucketItemScreen extends ConsumerStatefulWidget {
  final String listId;
  const AddBucketItemScreen({super.key, required this.listId});

  @override
  ConsumerState<AddBucketItemScreen> createState() =>
      _AddBucketItemScreenState();
}

class _AddBucketItemScreenState extends ConsumerState<AddBucketItemScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  final _searchCtrl = TextEditingController();
  String _query = '';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  BucketCategory _customCategory = BucketCategory.spot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _searchCtrl.clear();
        setState(() => _query = '');
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    _noteCtrl.dispose();
    _customCatCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFromListing(_ListingResult listing, {String? note}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final item = BucketItem(
      id: const Uuid().v4(),
      name: listing.name,
      category: listing.bucketCategory,
      imageUrl: listing.imageUrl.isNotEmpty ? listing.imageUrl : null,
      note: note,
      listingId: listing.id,
      listingType: listing.collection,
      isChecked: false,
    );
    await ref
        .read(bucketListControllerProvider.notifier)
        .addItem(widget.listId, item);
    if (mounted) context.pop();
  }

  Future<void> _addCustomItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = BucketItem(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      category: _customCategory,
      customCategory:
          _customCategory == BucketCategory.other &&
              _customCatCtrl.text.trim().isNotEmpty
          ? _customCatCtrl.text.trim()
          : null,
      imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      isChecked: false,
    );
    await ref
        .read(bucketListControllerProvider.notifier)
        .addItem(widget.listId, item);
    if (mounted) context.pop();
  }

  void _showAddConfirm(_ListingResult listing) {
    if (_saving) return;
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ListingThumb(url: listing.imageUrl, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.name,
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (listing.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          listing.location,
                          style: TextStyle(
                            color: context.col.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (listing.rating > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.star,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              listing.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: context.col.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: context.col.border),
            const SizedBox(height: 12),
            Text(
              'Note (optional)',
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: context.col.textPrimary, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Try their special dish!',
                hintStyle: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: context.col.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addFromListing(
                    listing,
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.col.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to List',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.col.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add to Bucket List',
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.col.textSecondary,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            dividerColor: context.col.border,
            tabs: _tabs.map((t) => Tab(text: '${t.emoji} ${t.label}')).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (int i = 0; i < _tabs.length - 1; i++)
            _ListingTab(
              tab: _tabs[i],
              searchCtrl: _searchCtrl,
              query: _query,
              onQueryChanged: (q) => setState(() => _query = q),
              onSelect: _showAddConfirm,
            ),
          _CustomItemTab(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            imageCtrl: _imageCtrl,
            noteCtrl: _noteCtrl,
            customCatCtrl: _customCatCtrl,
            category: _customCategory,
            onCategoryChanged: (c) => setState(() => _customCategory = c),
            onSave: _saving ? null : _addCustomItem,
            saving: _saving,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ListingTab
// ─────────────────────────────────────────────────────────────────────────────

class _ListingTab extends ConsumerWidget {
  final _TabConfig tab;
  final TextEditingController searchCtrl;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_ListingResult> onSelect;

  const _ListingTab({
    required this.tab,
    required this.searchCtrl,
    required this.query,
    required this.onQueryChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_listingSearchProvider(tab));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchCtrl,
            style: TextStyle(color: context.col.textPrimary, fontSize: 14),
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search ${tab.label.toLowerCase()}...',
              hintStyle: TextStyle(color: context.col.textMuted, fontSize: 14),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: context.col.textMuted,
                size: 20,
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: context.col.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        searchCtrl.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.col.surfaceElevated,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: context.col.textMuted,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load ${tab.label}',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.toString(),
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (listings) {
              final filtered = query.isEmpty
                  ? listings
                  : listings
                        .where(
                          (l) =>
                              l.name.toLowerCase().contains(
                                query.toLowerCase(),
                              ) ||
                              l.location.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tab.emoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        query.isEmpty
                            ? 'No ${tab.label} available'
                            : 'No results for "\$query"',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(color: context.col.border, height: 1),
                itemBuilder: (_, i) =>
                    _ListingTile(listing: filtered[i], onTap: onSelect),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ListingTile
// ─────────────────────────────────────────────────────────────────────────────

class _ListingTile extends StatelessWidget {
  final _ListingResult listing;
  final ValueChanged<_ListingResult> onTap;
  const _ListingTile({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(listing),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _ListingThumb(url: listing.imageUrl, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (listing.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      listing.location,
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (listing.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          listing.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                '+ Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ListingThumb
// ─────────────────────────────────────────────────────────────────────────────

class _ListingThumb extends StatelessWidget {
  final String url;
  final double size;
  const _ListingThumb({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (ctx, __, ___) => _placeholder(ctx),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: size,
    height: size,
    color: context.col.surfaceElevated,
    child: Icon(
      Icons.image_not_supported_rounded,
      color: context.col.textMuted,
      size: 22,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CustomItemTab
// ─────────────────────────────────────────────────────────────────────────────

class _CustomItemTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController imageCtrl;
  final TextEditingController noteCtrl;
  final TextEditingController customCatCtrl;
  final BucketCategory category;
  final ValueChanged<BucketCategory> onCategoryChanged;
  final VoidCallback? onSave;
  final bool saving;

  const _CustomItemTab({
    required this.formKey,
    required this.nameCtrl,
    required this.imageCtrl,
    required this.noteCtrl,
    required this.customCatCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Add a custom item not found in the listings above.',
            style: TextStyle(color: context.col.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _label(context, 'Item Name *'),
          TextFormField(
            controller: nameCtrl,
            style: TextStyle(color: context.col.textPrimary, fontSize: 14),
            decoration: _deco(
              context,
              hint: 'e.g. Visit a hidden waterfall trail',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),
          _label(context, 'Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BucketCategory.values.map((cat) {
              final sel = category == cat;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primary : context.col.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '${cat.emoji}  ${cat.label}',
                    style: TextStyle(
                      color: sel
                          ? AppColors.primary
                          : context.col.textSecondary,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (category == BucketCategory.other) ...[
            const SizedBox(height: 12),
            _label(context, 'Custom Category Name'),
            TextFormField(
              controller: customCatCtrl,
              style: TextStyle(color: context.col.textPrimary, fontSize: 14),
              decoration: _deco(context, hint: 'e.g. Street Food'),
            ),
          ],
          const SizedBox(height: 20),
          _label(context, 'Image URL (optional)'),
          TextFormField(
            controller: imageCtrl,
            style: TextStyle(color: context.col.textPrimary, fontSize: 14),
            decoration: _deco(context, hint: 'https://...'),
          ),
          const SizedBox(height: 20),
          _label(context, 'Note (optional)'),
          TextFormField(
            controller: noteCtrl,
            style: TextStyle(color: context.col.textPrimary, fontSize: 14),
            decoration: _deco(context, hint: 'Tips or things to remember...'),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.col.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.col.bg,
                      ),
                    )
                  : const Text(
                      'Add Custom Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: context.col.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static InputDecoration _deco(BuildContext context, {required String hint}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.col.textMuted, fontSize: 14),
        filled: true,
        fillColor: context.col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}
