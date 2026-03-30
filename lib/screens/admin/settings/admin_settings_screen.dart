// lib/screens/admin/settings/admin_settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/admin_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _notifListings = true;
  bool _notifUsers = true;
  bool _notifModeration = false;
  bool _devMode = false;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final profile = ref.watch(adminProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: col.bg,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Material(
              color: col.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: col.border),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Admin Profile card ─────────────────────────────
                  _ProfileCard(profile: profile),
                  const SizedBox(height: 20),

                  // ── Account section ────────────────────────────────
                  _SectionHeader('Account'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        iconColor: AppColors.secondary,
                        title: 'Display Name',
                        subtitle: profile?.displayName ?? '—',
                        trailing: _InfoBadge(profile?.role.label ?? ''),
                        onTap: () =>
                            _showEditDisplayNameSheet(context, profile),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.info,
                        title: 'Email',
                        subtitle:
                            profile?.email ??
                            FirebaseAuth.instance.currentUser?.email ??
                            '—',
                        onTap: null,
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.primary,
                        title: 'Role',
                        subtitle: profile?.role.label ?? 'Super Admin',
                        trailing: Text(
                          profile?.role.emoji ?? '👑',
                          style: const TextStyle(fontSize: 18),
                        ),
                        onTap: null,
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.key_outlined,
                        iconColor: AppColors.warning,
                        title: 'Change Password',
                        subtitle: 'Send a password-reset email',
                        onTap: () => _sendPasswordReset(context, profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Notifications section ──────────────────────────
                  _SectionHeader('Notifications'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        icon: Icons.place_outlined,
                        iconColor: AppColors.primary,
                        title: 'Listing Alerts',
                        subtitle: 'New listings need review',
                        value: _notifListings,
                        onChanged: (v) => setState(() => _notifListings = v),
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.people_outline,
                        iconColor: AppColors.secondary,
                        title: 'User Signups',
                        subtitle: 'New user registration alerts',
                        value: _notifUsers,
                        onChanged: (v) => setState(() => _notifUsers = v),
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.flag_outlined,
                        iconColor: AppColors.error,
                        title: 'Moderation Flags',
                        subtitle: 'Content flagged for review',
                        value: _notifModeration,
                        onChanged: (v) => setState(() => _notifModeration = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Permissions section ────────────────────────────
                  if (profile != null) ...[
                    _SectionHeader('Permissions'),
                    const SizedBox(height: 8),
                    _PermissionsCard(permissions: profile.permissions),
                    const SizedBox(height: 20),
                  ],

                  // ── Developer section ──────────────────────────────
                  _SectionHeader('Developer'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        icon: Icons.code_outlined,
                        iconColor: AppColors.accent,
                        title: 'Developer Mode',
                        subtitle: 'Show debug info and raw document IDs',
                        value: _devMode,
                        onChanged: (v) => setState(() => _devMode = v),
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.content_copy_outlined,
                        iconColor: col.textSecondary,
                        title: 'Copy Admin UID',
                        subtitle: FirebaseAuth.instance.currentUser?.uid ?? '—',
                        onTap: () {
                          final uid =
                              FirebaseAuth.instance.currentUser?.uid ?? '';
                          if (uid.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: uid));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UID copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── App info section ───────────────────────────────
                  _SectionHeader('About'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        iconColor: AppColors.info,
                        title: 'App Name',
                        subtitle: 'SpotMizoram Admin Panel',
                        onTap: null,
                      ),
                      _Divider(),
                      _SettingsTile(
                        icon: Icons.verified_outlined,
                        iconColor: AppColors.success,
                        title: 'Version',
                        subtitle: '1.0.0 (build 1)',
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Sign out ───────────────────────────────────────
                  _SignOutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _sendPasswordReset(
    BuildContext context,
    AdminModel? profile,
  ) async {
    final email =
        profile?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditDisplayNameSheet(BuildContext context, AdminModel? profile) {
    final ctrl = TextEditingController(text: profile?.displayName ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final col = ctx.col;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Display Name',
                style: TextStyle(
                  color: col.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: col.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: TextStyle(color: col.textMuted),
                  filled: true,
                  fillColor: col.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: col.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: col.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = ctrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    // Update Firebase Auth display name
                    await FirebaseAuth.instance.currentUser?.updateDisplayName(
                      name,
                    );
                    // Optionally update Firestore profile here via a service
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Display name updated'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AdminModel? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final initials = _initials(
      profile?.displayName ?? user?.displayName ?? '?',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? user?.displayName ?? 'Admin',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile?.email ?? user?.email ?? '',
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile?.role.emoji ?? '👑',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile?.role.label ?? 'Super Admin',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profile?.isActive ?? true) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permissions card
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsCard extends StatelessWidget {
  final AdminPermissions permissions;
  const _PermissionsCard({required this.permissions});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final items = [
      ('Manage Spots', permissions.canManageSpots, Icons.place_outlined),
      (
        'Manage Listings',
        permissions.canManageListings,
        Icons.list_alt_outlined,
      ),
      ('Manage Events', permissions.canManageEvents, Icons.event_outlined),
      (
        'Manage Ventures',
        permissions.canManageVentures,
        Icons.explore_outlined,
      ),
      ('Manage Users', permissions.canManageUsers, Icons.people_outline),
      (
        'View Analytics',
        permissions.canViewAnalytics,
        Icons.bar_chart_outlined,
      ),
      (
        'Manage Community',
        permissions.canManageCommunity,
        Icons.forum_outlined,
      ),
      (
        'Manage Admins',
        permissions.canManageAdmins,
        Icons.admin_panel_settings_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Your access permissions',
              style: TextStyle(color: col.textMuted, fontSize: 12),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final (label, granted, icon) = item;
                return _PermChip(label: label, icon: icon, granted: granted);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool granted;
  const _PermChip({
    required this.label,
    required this.icon,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success.withValues(alpha: 0.12)
            : col.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.4)
              : col.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? icon : Icons.block_outlined,
            size: 12,
            color: granted ? AppColors.success : col.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: granted ? AppColors.success : col.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign out button
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: context.col.surface,
              title: Text(
                'Sign out?',
                style: TextStyle(color: context.col.textPrimary),
              ),
              content: Text(
                'You will be taken back to the login screen.',
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
                    'Sign Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) context.go('/');
          }
        },
        icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
        label: const Text(
          'Sign Out',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.col.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(color: col.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: col.textMuted, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: col.textMuted,
            inactiveTrackColor: col.surfaceElevated,
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  const _InfoBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: context.col.border, indent: 64, endIndent: 0);
}
