import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/spots_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/spot_model.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/spot_cards.dart';

// Category tabs — matching actual Firestore values
const _kCategories = [
  (id: null, label: 'All', emoji: '🗺️'),
  (id: 'Mountains', label: 'Mountains', emoji: '⛰️'),
  (id: 'Waterfalls', label: 'Waterfalls', emoji: '💧'),
  (id: 'Cultural Sites', label: 'Cultural Sites', emoji: '🏛️'),
  (id: 'Viewpoints', label: 'Viewpoints', emoji: '👁️'),
  (id: 'Adventure', label: 'Adventure', emoji: '🧗'),
  (id: 'Lakes', label: 'Lakes', emoji: '🏞️'),
  (id: 'Caves', label: 'Caves', emoji: '🕳️'),
];

class SpotsListScreen extends ConsumerStatefulWidget {
  const SpotsListScreen({super.key});

  @override
  ConsumerState<SpotsListScreen> createState() => _SpotsListScreenState();
}

class _SpotsListScreenState extends ConsumerState<SpotsListScreen> {
  String? _selectedCategory; // null = all

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(
      allSpotsByCategoryStreamProvider(_selectedCategory),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Spots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category filter tabs ──────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _kCategories[i];
                final selected = _selectedCategory == cat.id;
                return GestureDetector(
                  onTap: () {
                    if (_selectedCategory != cat.id) {
                      setState(() => _selectedCategory = cat.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${cat.emoji}  ${cat.label}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Spots grid ────────────────────────────────────────────────
          Expanded(
            child: spotsAsync.when(
              loading: () => _LoadingGrid(),
              error: (_, __) => const EmptyState(
                emoji: '😕',
                title: 'Could not load spots',
                subtitle: 'Check your connection and try again',
              ),
              data: (spots) => spots.isEmpty
                  ? EmptyState(
                      emoji: '🗺️',
                      title: 'No spots found',
                      subtitle: _selectedCategory == null
                          ? 'Check back soon!'
                          : 'No $_selectedCategory spots yet',
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => ref.refresh(
                        allSpotsByCategoryStreamProvider(_selectedCategory),
                      ),
                      child: _SpotsGrid(spots: spots),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotsGrid extends StatelessWidget {
  final List<SpotModel> spots;
  const _SpotsGrid({required this.spots});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: spots.length,
      itemBuilder: (ctx, i) {
        final spot = spots[i];
        return SpotCard(
          spot: spot,
          onTap: () => ctx.push(AppRoutes.spotDetailPath(spot.id)),
        );
      },
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        radius: 16,
      ),
    );
  }
}
