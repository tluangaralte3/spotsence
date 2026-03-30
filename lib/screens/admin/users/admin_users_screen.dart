// lib/screens/admin/users/admin_users_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/user_model.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final usersAsync = ref.watch(adminUsersProvider);

    ref.listen(adminUserNotifierProvider, (_, next) {
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
        ref.read(adminUserNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: col.bg,
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Material(
            color: col.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: TextStyle(color: col.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: TextStyle(color: col.textMuted),
                  prefixIcon: Icon(Icons.search, color: col.textMuted),
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
          ),
          Divider(height: 1, color: col.border),
          // ── User list ─────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (users) {
                final filtered = _query.isEmpty
                    ? users
                    : users
                          .where(
                            (u) =>
                                u.displayName.toLowerCase().contains(_query) ||
                                u.email.toLowerCase().contains(_query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: col.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No users match "$_query"'
                              : 'No users found.',
                          style: TextStyle(
                            color: col.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${filtered.length} user(s)',
                            style: TextStyle(
                              color: col.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) => _UserRow(user: filtered[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  final UserModel user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final isActive = (user.toJson()['isActive'] as bool?) ?? true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: col.surfaceElevated,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.accent, size: 12),
                    Text(
                      ' ${user.points} pts',
                      style: TextStyle(color: col.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lvl ${user.level}',
                      style: TextStyle(color: AppColors.primary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: col.surfaceElevated,
            icon: Icon(Icons.more_vert, color: col.textSecondary),
            onSelected: (val) => _onAction(context, ref, val),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: isActive ? 'suspend' : 'activate',
                child: Text(
                  isActive ? 'Suspend User' : 'Activate User',
                  style: TextStyle(
                    color: isActive ? AppColors.error : AppColors.success,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'suspend') {
      await ref
          .read(adminUserNotifierProvider.notifier)
          .setUserActive(user.id, isActive: false);
    } else if (action == 'activate') {
      await ref
          .read(adminUserNotifierProvider.notifier)
          .setUserActive(user.id, isActive: true);
    }
  }
}
