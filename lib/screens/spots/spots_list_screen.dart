import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/spots_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/spot_cards.dart';

class SpotsListScreen extends ConsumerWidget {
  const SpotsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spotsControllerProvider);
    final controller = ref.read(spotsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter pills
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: AppConstants.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = AppConstants.categories[i];
                final catId = cat['id'] == 'all' ? null : cat['id'];
                final selected = state.selectedCategory == catId;
                return CategoryChip(
                  label: cat['label']!,
                  emoji: cat['emoji']!,
                  selected: selected,
                  onTap: () => controller.setCategory(catId),
                );
              },
            ),
          ),

          // Spots grid
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.refresh,
              child: state.spots.isEmpty && state.isLoading
                  ? _LoadingGrid()
                  : state.spots.isEmpty
                  ? const EmptyState(
                      emoji: '🗺️',
                      title: 'No spots found',
                      subtitle: 'Try a different category',
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 300) {
                          controller.loadMore();
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount:
                            state.spots.length + (state.isLoading ? 2 : 0),
                        itemBuilder: (ctx, i) {
                          if (i >= state.spots.length) {
                            return const ShimmerBox(
                              width: double.infinity,
                              height: double.infinity,
                              radius: 16,
                            );
                          }
                          final spot = state.spots[i];
                          return SpotCard(
                            spot: spot,
                            onTap: () =>
                                ctx.push(AppRoutes.spotDetailPath(spot.id)),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
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
