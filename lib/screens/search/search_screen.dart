import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/spots_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/spot_cards.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextFormField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search spots, restaurants...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          onChanged: controller.search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                controller.clear();
              },
            ),
        ],
      ),
      body: state.query.isEmpty
          ? const EmptyState(
              emoji: '🔍',
              title: 'Search Mizoram',
              subtitle: 'Find waterfalls, restaurants, mountains and more',
            )
          : state.isSearching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.results.isEmpty
          ? EmptyState(
              emoji: '😕',
              title: 'No results for "${state.query}"',
              subtitle: 'Try a different keyword',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.results.length,
              itemBuilder: (ctx, i) {
                final spot = state.results[i];
                return SpotCard(
                  spot: spot,
                  onTap: () => ctx.push(AppRoutes.spotDetailPath(spot.id)),
                );
              },
            ),
    );
  }
}
