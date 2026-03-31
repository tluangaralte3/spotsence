import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'dare_tab.dart';
import 'community_map.dart';
import 'dilemmas_tab.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.col.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Dare'),
            Tab(text: 'Dilemmas'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _tabs,
        builder: (context, _) => TabBarView(
          controller: _tabs,
          // Disable swipe on the map tab so pan/zoom gestures reach flutter_map
          physics: _tabs.index == 0
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          children: const [CommunityMap(), DareTab(), DilemmasTab()],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (context, _) {
          if (_tabs.index == 1) {
            // Bucket lists tab: show create + join FABs
            final user = ref.read(currentUserProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'join_list',
                  onPressed: () {
                    if (user != null) {
                      showJoinCodeSheet(context, user.id);
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  backgroundColor: context.col.surfaceElevated,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.link_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'create_list',
                  onPressed: () {
                    if (user != null) {
                      context.push(AppRoutes.createDare);
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: context.col.bg,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            );
          }
          // Feed (0) and Dilemmas (2): no FAB
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
