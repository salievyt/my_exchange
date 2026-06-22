import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/localization_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/made_by_footer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final local = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(local.t('settings_title'))),
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
            subtitle: _currentLanguageName(local),
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

          /* 
          // Columns toggle
          _SettingsTile(
            icon: Icons.view_column,
            title: 'Колонки операций',
            subtitle: context.watch<OperationProvider>().columnsCount == 1
                ? '1 колонка'
                : '2 колонки',
            trailing: ColumnsToggle(
              columnsCount: context.watch<OperationProvider>().columnsCount,
              onChanged: (count) =>
                  context.read<OperationProvider>().setColumnsCount(count),
            ),
          ),
          const Divider(height: 1, indent: 72),
          */

          // PIN code setup
          _SettingsTile(
            icon: Icons.pin_outlined,
            title: local.t('settings_pin_code'),
            subtitle: local.t('settings_pin_code_desc'),
            onTap: () => _showPinSetupDialog(context, local),
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

          // Contact support — opens dialog with WhatsApp and Telegram
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            title: local.t('settings_contact_support'),
            subtitle: local.t('settings_support_chat'),
            onTap: () => _showSupportDialog(context, local),
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
          const SizedBox(height: 24),

          // ── Version + Made by Deo Studio ─────────────────────────────
          MadeByFooter(version: AppConstants.appVersion, appName: AppConstants.appName,),
        ],
      ),
    );
  }

  void _showPinSetupDialog(BuildContext context, LocalizationProvider local) {
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => _PinSetupDialog(auth: auth, local: local),
    );
  }

  String _currentLanguageName(LocalizationProvider local) {
    switch (local.locale) {
      case 'ru':
        return local.t('settings_language_ru');
      case 'ky':
        return local.t('settings_language_kg');
      case 'en':
        return local.t('settings_language_en');
      case 'uz':
        return local.t('settings_language_uz');
      case 'uz_Cyrl':
        return local.t('settings_language_uzCyrillic');
      default:
        return local.t('settings_language_ru');
    }
  }

  void _openPrivacyPolicy() async {
    final uri = Uri.parse(
      'https://docs.google.com/document/d/13BFVcVsj43N06JOvTCbpjDv4StNfjQgUP0sBYpAEsxc/edit?usp=sharing',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSupportDialog(BuildContext context, LocalizationProvider local) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        title: _FadeSlideIn(
          delayMs: 0,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                local.t('settings_support_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FadeSlideIn(
              delayMs: 100,
              child: Text(
                local.t('settings_support_description'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FadeSlideIn(
              delayMs: 250,
              slideOffset: 40,
              child: _SupportButton(
                icon: _buildBrandIcon(
                  color: const Color(0xFF25D366),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                ),
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsApp(context);
                },
              ),
            ),
            const SizedBox(height: 12),
            _FadeSlideIn(
              delayMs: 400,
              slideOffset: 40,
              child: _SupportButton(
                icon: _buildBrandIcon(
                  color: const Color(0xFF0088CC),
                  child: Transform.rotate(
                    angle: -0.3,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
                label: 'Telegram',
                color: const Color(0xFF0088CC),
                onTap: () {
                  Navigator.pop(ctx);
                  _openTelegram(context);
                },
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8),
        actions: [
          _FadeSlideIn(
            delayMs: 550,
            slideOffset: 0,
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  local.t('settings_cancel'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIcon({required Color color, required Widget child}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _openWhatsApp(BuildContext context) async {
    const phoneNumber = '996990055445';
    final message = Uri.encodeComponent(
      'Здравствуйте! Мне нужна помощь с приложением My Exchange.',
    );
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openTelegram(BuildContext context) async {
    const username = 'bc_sm1le';
    final message = Uri.encodeComponent(
      'Здравствуйте! Мне нужна помощь с приложением My Exchange.',
    );
    final uri = Uri.parse('https://t.me/$username?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
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

// ─── Animation Widget ──────────────────────────────────────────────

/// A widget that fades in and slides up with a staggered delay.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final double slideOffset;

  const _FadeSlideIn({
    required this.child,
    this.delayMs = 0,
    this.slideOffset = 20,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      // Total duration = full animation window; the delay is faked by
      // keeping the value clamped at 0 for [delayMs] milliseconds.
      duration: Duration(milliseconds: 500 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Map the [0, 1] range over the full duration, offset by delay
        final progress = delayMs > 0
            ? ((value * (500 + delayMs) - delayMs) / 500).clamp(0.0, 1.0)
            : value;
        final opacity = progress;
        final translateY = slideOffset * (1 - progress);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─── Support Button Widget ─────────────────────────────────────────

class _SupportButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SupportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.08),
        highlightColor: color.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
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
            Icon(Icons.verified, color: AppColors.success, size: 20),
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
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing:
          trailing ??
          (onTap != null
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
          theme.setThemeMode(index == 0 ? ThemeMode.light : ThemeMode.dark);
        },
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textSecondary,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.light_mode, size: 14),
                const SizedBox(width: 2),
                Text(
                  context.watch<LocalizationProvider>().t(
                    'settings_theme_light',
                  ),
                ),
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
                Text(
                  context.watch<LocalizationProvider>().t(
                    'settings_theme_dark',
                  ),
                ),
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

// ─── PIN Setup Dialog ────────────────────────────────────────────

class _PinSetupDialog extends StatefulWidget {
  final AuthProvider auth;
  final LocalizationProvider local;

  const _PinSetupDialog({required this.auth, required this.local});

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _showRemoveOption = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final hasPin = await widget.auth.hasPinCode();
    if (mounted) {
      setState(() => _showRemoveOption = hasPin);
    }
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 6) {
      _showError('PIN-код должен быть 6 цифр');
      return;
    }
    if (pin != confirm) {
      _showError('PIN-коды не совпадают');
      return;
    }

    setState(() => _saving = true);
    await widget.auth.setPinCode(pin);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN-код установлен'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  Future<void> _removePin() async {
    await widget.auth.removePinCode();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN-код удалён'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.pin_outlined, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            widget.local.t('settings_pin_code'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Новый PIN-код',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Подтвердите PIN-код',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_showRemoveOption)
          TextButton(
            onPressed: _saving ? null : _removePin,
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Удалить PIN'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _savePin,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();

    // Build the list of languages
    final languages = [
      ('ru', 'RU'),
      ('ky', 'KG'),
      ('en', 'EN'),
      ('uz', "O'Z"),
      ('uz_Cyrl', 'ЎЗ'),
    ];

    // Find current locale index
    int currentIndex = languages.indexWhere((lang) => lang.$1 == local.locale);
    if (currentIndex < 0) currentIndex = 0;

    return PopupMenuButton<String>(
      onSelected: (locale) => local.setLocale(locale),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => languages.map((lang) {
        final code = lang.$1;
        final label = lang.$2;
        final isSelected = code == local.locale;
        return PopupMenuItem<String>(
          value: code,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languages[currentIndex].$2,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
