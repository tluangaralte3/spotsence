// ignore_for_file: sort_child_properties_last
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/gamification_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/gamification_widgets.dart';
import '../../services/analytics_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gamificationControllerProvider.notifier).recordDailyLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexForLocation(location);

    return Scaffold(
      body: XpToastOverlay(child: widget.child),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () => context.go('/debug'),
              child: const Icon(Icons.bug_report),
              tooltip: 'Diagnostics',
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.col.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard_rounded),
              label: 'Rankings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.listings)) return 1;
    if (location.startsWith(AppRoutes.leaderboard)) return 2;
    if (location.startsWith(AppRoutes.community)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        AnalyticsService.instance.logTabChange(tabName: 'home', index: 0);
        context.go(AppRoutes.home);
      case 1:
        AnalyticsService.instance.logTabChange(tabName: 'listings', index: 1);
        context.go(AppRoutes.listings);
      case 2:
        AnalyticsService.instance.logTabChange(
          tabName: 'leaderboard',
          index: 2,
        );
        context.go(AppRoutes.leaderboard);
      case 3:
        AnalyticsService.instance.logTabChange(tabName: 'community', index: 3);
        context.go(AppRoutes.community);
      case 4:
        AnalyticsService.instance.logTabChange(tabName: 'profile', index: 4);
        context.go(AppRoutes.profile);
    }
  }
}
