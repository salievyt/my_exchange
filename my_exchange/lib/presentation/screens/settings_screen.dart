import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/localization_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final local = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(local.t('settings_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ────────────────────────────────────────
          _ProfileCard(user: user),
          const SizedBox(height: 24),

          // ── Settings sections ───────────────────────────────────
          _SectionTitle(text: local.t('settings_profile')),

          // Language selector
          _SettingsTile(
            icon: Icons.language,
            title: local.t('settings_language'),
            subtitle: local.isRussian
                ? local.t('settings_language_ru')
                : local.t('settings_language_kg'),
            trailing: _LanguageSwitcher(),
          ),
          const Divider(height: 1, indent: 72),

          // Theme selector
          _SettingsTile(
            icon: Icons.dark_mode,
            title: local.t('settings_theme'),
            subtitle: context.watch<ThemeProvider>().isDark
                ? local.t('settings_theme_dark')
                : local.t('settings_theme_light'),
            trailing: _ThemeSwitcher(),
          ),
          const Divider(height: 1, indent: 72),

          // Biometric login toggle
          if (context.watch<AuthProvider>().biometricAvailable)
            _SettingsTile(
              icon: Icons.fingerprint,
              title: local.t('settings_biometric_login'),
              subtitle: local.t('settings_biometric_login_desc'),
              trailing: _BiometricSwitch(),
            ),
          if (context.watch<AuthProvider>().biometricAvailable)
            const Divider(height: 1, indent: 72),

          // App version
          _SettingsTile(
            icon: Icons.info_outline,
            title: local.t('settings_app_version'),
            subtitle: AppConstants.appVersion,
          ),
          const SizedBox(height: 24),

          // ── Information section ─────────────────────────────────
          _SectionTitle(text: local.t('settings_privacy_policy')),

          // Privacy policy link — opens Google Docs
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: local.t('settings_privacy_policy'),
            subtitle: local.t('settings_privacy_note'),
            onTap: () => _openPrivacyPolicy(),
          ),
          const Divider(height: 1, indent: 72),

          // Contact support — opens email app
          _SettingsTile(
            icon: Icons.mail_outline,
            title: local.t('settings_contact_support'),
            subtitle: local.t('settings_support_email'),
            onTap: () => _sendEmail(),
          ),
          const Divider(height: 1, indent: 72),

          // Delete account
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: local.t('settings_delete_account'),
            subtitle: local.t('settings_delete_account_desc'),
            iconColor: AppColors.error,
            onTap: () => _confirmDeleteAccount(context, local),
          ),
          const SizedBox(height: 32),

          // ── Logout Button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, local),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                local.t('settings_logout'),
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Version info at bottom
          Center(
            child: Text(
              '${local.t('login_version')} ${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://docs.google.com/document/d/13BFVcVsj43N06JOvTCbpjDv4StNfjQgUP0sBYpAEsxc/edit?usp=sharing',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'salievyt@gmail.com',
      queryParameters: {
        'subject': 'My Exchange — поддержка',
        'body': '',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmLogout(BuildContext context, LocalizationProvider local) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(local.t('settings_logout_confirm')),
        content: Text(local.t('settings_logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(local.t('settings_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              local.t('settings_confirm'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, LocalizationProvider local) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(local.t('settings_delete_account')),
        content: Text(local.t('settings_delete_account_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(local.t('settings_cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(local.t('settings_delete_account_confirm')),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              local.t('settings_confirm'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final User? user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleDisplay = user?.role.displayName ?? '—';
    final name = user?.fullName ?? '—';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roleDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (user?.username != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '@${user!.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: AppColors.success,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: trailing ?? (onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textHint)
          : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ThemeSwitcher extends StatefulWidget {
  @override
  State<_ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<_ThemeSwitcher> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return SizedBox(
      width: 160,
      child: ToggleButtons(
        isSelected: [theme.isLight, theme.isDark],
        onPressed: (index) {
          theme.setThemeMode(
            index == 0 ? ThemeMode.light : ThemeMode.dark,
          );
        },
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textSecondary,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.light_mode, size: 14),
                const SizedBox(width: 2),
                Text(context.watch<LocalizationProvider>().t('settings_theme_light')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dark_mode, size: 14),
                const SizedBox(width: 2),
                Text(context.watch<LocalizationProvider>().t('settings_theme_dark')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricSwitch extends StatefulWidget {
  @override
  State<_BiometricSwitch> createState() => _BiometricSwitchState();
}

class _BiometricSwitchState extends State<_BiometricSwitch> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Switch(
      value: auth.biometricEnabled,
      onChanged: (v) => auth.setBiometricEnabled(v),
      activeThumbColor: AppColors.primary,
    );
  }
}

class _LanguageSwitcher extends StatefulWidget {
  @override
  State<_LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<_LanguageSwitcher> {
  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();

    return SizedBox(
      width: 80,
      child: ToggleButtons(
        isSelected: [local.isRussian, local.isKyrgyz],
        onPressed: (index) {
          final newLocale = index == 0 ? 'ru' : 'ky';
          local.setLocale(newLocale);
        },
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textSecondary,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('RU'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('KG'),
          ),
        ],
      ),
    );
  }
}
