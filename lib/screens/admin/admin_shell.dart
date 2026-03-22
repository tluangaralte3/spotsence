// lib/screens/admin/admin_shell.dart
//
// Root shell for the Super Admin section.
// Provides a persistent NavigationDrawer / BottomNavigationBar
// depending on screen width.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/admin_model.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'listings/admin_listings_screen.dart';
import 'users/admin_users_screen.dart';
import 'analytics/admin_analytics_screen.dart';
import 'ventures/admin_ventures_screen.dart';
import 'moderation/admin_moderation_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation items
// ─────────────────────────────────────────────────────────────────────────────

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

const _navItems = [
  _AdminNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
  ),
  _AdminNavItem(
    label: 'Listings',
    icon: Icons.place_outlined,
    activeIcon: Icons.place,
  ),
  _AdminNavItem(
    label: 'Users',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
  ),
  _AdminNavItem(
    label: 'Analytics',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
  ),
  _AdminNavItem(
    label: 'Ventures',
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore,
  ),
  _AdminNavItem(
    label: 'Moderation',
    icon: Icons.shield_outlined,
    activeIcon: Icons.shield,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────

class _AdminTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

final adminTabIndexProvider = NotifierProvider<_AdminTabNotifier, int>(
  _AdminTabNotifier.new,
);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const _screens = [
    AdminDashboardScreen(),
    AdminListingsScreen(),
    AdminUsersScreen(),
    AdminAnalyticsScreen(),
    AdminVenturesScreen(),
    AdminModerationScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(isSuperAdminProvider);
    final col = context.col;

    // While the token refresh is in-flight, show a spinner
    if (claimAsync.isLoading) {
      return Scaffold(
        backgroundColor: col.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Claim resolved as false — access denied
    final isSuperAdmin = claimAsync.asData?.value ?? false;
    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: col.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.error, size: 56),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have super admin privileges.',
                style: TextStyle(color: col.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final index = ref.watch(adminTabIndexProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final profile = ref.watch(adminProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: col.bg,
      body: isWide
          ? _WideLayout(index: index, profile: profile, screens: _screens)
          : _NarrowLayout(index: index, profile: profile, screens: _screens),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide (tablet/desktop) — NavigationRail
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  final int index;
  final AdminModel? profile;
  final List<Widget> screens;

  const _WideLayout({
    required this.index,
    required this.profile,
    required this.screens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;

    return Row(
      children: [
        NavigationRail(
          backgroundColor: col.surface,
          selectedIndex: index,
          extended: true,
          minExtendedWidth: 200,
          leading: _AdminRailHeader(profile: profile),
          destinations: _navItems
              .map(
                (n) => NavigationRailDestination(
                  icon: Icon(n.icon),
                  selectedIcon: Icon(n.activeIcon),
                  label: Text(n.label),
                ),
              )
              .toList(),
          selectedIconTheme: IconThemeData(color: AppColors.primary),
          unselectedIconTheme: IconThemeData(color: col.textSecondary),
          selectedLabelTextStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: TextStyle(color: col.textSecondary),
          onDestinationSelected: (i) =>
              ref.read(adminTabIndexProvider.notifier).set(i),
          trailing: _SignOutButton(),
        ),
        VerticalDivider(color: col.border, width: 1),
        Expanded(
          child: IndexedStack(index: index, children: screens),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow (phone) — BottomNavigationBar
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends ConsumerWidget {
  final int index;
  final AdminModel? profile;
  final List<Widget> screens;

  const _NarrowLayout({
    required this.index,
    required this.profile,
    required this.screens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;

    return Column(
      children: [
        // App bar
        Container(
          color: col.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('👑', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    profile?.displayName ?? 'Admin Panel',
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  _SignOutButton(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(index: index, children: screens),
        ),
        // Bottom nav — show only first 5 tabs; 6th (Moderation) in a menu
        Container(
          decoration: BoxDecoration(
            color: col.surface,
            border: Border(top: BorderSide(color: col.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: index > 4 ? 0 : index,
            backgroundColor: col.surface,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: col.textMuted,
            showUnselectedLabels: true,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: _navItems
                .take(5)
                .map(
                  (n) => BottomNavigationBarItem(
                    icon: Icon(n.icon, size: 22),
                    activeIcon: Icon(n.activeIcon, size: 22),
                    label: n.label,
                  ),
                )
                .toList(),
            onTap: (i) => ref.read(adminTabIndexProvider.notifier).set(i),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rail header widget
// ─────────────────────────────────────────────────────────────────────────────

class _AdminRailHeader extends StatelessWidget {
  final AdminModel? profile;
  const _AdminRailHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile?.displayName ?? 'Admin',
            style: TextStyle(
              color: col.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            profile?.role.label ?? 'Super Admin',
            style: TextStyle(color: AppColors.primary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Divider(color: col.border),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-out button
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).signOut();
        if (context.mounted) context.go('/');
      },
      icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
      label: Text(
        'Sign Out',
        style: TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}
