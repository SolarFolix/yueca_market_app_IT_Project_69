import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_bottom_nav.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName =
        (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'Guest';
    final email = user?.email ?? 'Not signed in';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: (user?.photoURL != null)
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AccountSettingsScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('logged in as $email', style: AppTextStyles.subheading),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _statColumn('6', 'Bookings')),
                Container(height: 30, width: 1, color: AppColors.border),
                Expanded(child: _statColumn('4.8', 'Rating')),
                Container(height: 30, width: 1, color: AppColors.border),
                Expanded(child: _statColumn('2026', 'Member since')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            Icons.person_outline,
            'Your Account Settings',
            subtitle: 'Username, email, password',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AccountSettingsScreen())),
          ),
          _AppearanceTile(),
          _tile(context, Icons.privacy_tip_outlined, 'Privacy & Safety',
              onTap: () => _comingSoon(context)),
          _tile(context, Icons.notifications_none_rounded, 'Alerts & Updates',
              onTap: () => Navigator.of(context).pushNamed('/notifications')),
          _tile(context, Icons.language_rounded, 'Region & Language',
              onTap: () => _comingSoon(context)),
          if (AuthService.instance.isAvailable) ...[
            const Divider(height: 32),
            _tile(
              context,
              Icons.cloud_sync_outlined,
              'Seed Demo Market Data',
              subtitle: 'Dev tool — fills Firestore if stores/stalls are empty',
              onTap: () => _seedDemoData(context),
            ),
          ],
          const Divider(height: 32),
          _tile(context, Icons.logout_rounded, 'Logout',
              onTap: () => _confirmLogout(context)),
          _tile(context, Icons.delete_outline_rounded, 'Delete My Account',
              color: AppColors.danger,
              onTap: () => _confirmDeleteAccount(context)),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  static void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  static Future<void> _seedDemoData(BuildContext context) async {
    try {
      await MarketService.instance.seedDemoDataIfEmpty();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Demo stores & stalls are ready (skipped if already seeded).')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not seed data — check Firestore rules are deployed.'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign in again to book a stall."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  }

  static Future<void> _confirmDeleteAccount(BuildContext context) async {
    if (AuthService.instance.currentUser == null) {
      _comingSoon(context);
      return;
    }
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Delete your account?'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'This permanently deletes your account and cannot be undone. Enter your password to confirm.',
                      style: TextStyle(fontSize: 12.5)),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(hintText: 'Current password'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        try {
                          await AuthService.instance
                              .deleteAccount(passwordController.text);
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      AuthService.instance.messageForError(e)),
                                  backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Delete',
                        style: TextStyle(color: AppColors.danger)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      {String? subtitle, VoidCallback? onTap, Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: TextStyle(fontSize: 13, color: c)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary))
          : null,
      trailing: Icon(Icons.chevron_right, color: c.withOpacity(0.6), size: 18),
      onTap: onTap ?? () {},
    );
  }
}

/// Appearance row — expands into a System/Light/Dark radio picker.
/// Lives as its own widget so it can hold the ValueListenableBuilder
/// needed to show the current selection.
class _AppearanceTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.dark_mode_outlined,
              color: AppColors.textPrimary, size: 20),
          title: Text('Appearance',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          subtitle: Text(_label(mode),
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          trailing: Icon(Icons.chevron_right,
              color: AppColors.textPrimary.withOpacity(0.6), size: 18),
          onTap: () => _openPicker(context, mode),
        );
      },
    );
  }

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Future<void> _openPicker(BuildContext context, ThemeMode current) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: current,
                    activeColor: AppColors.primary,
                    title: Text(
                      _label(mode),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (value) => Navigator.of(context).pop(value),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await ThemeController.set(selected);
    }
  }
}
