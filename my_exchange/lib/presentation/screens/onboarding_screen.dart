import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    _completeOnboarding();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await context.read<AuthProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = context.watch<LocalizationProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? colors.surface : Colors.white;

    return Scaffold(
      body: Container(
        color: surface,
        child: SafeArea(
          child: Column(
            children: [
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildWelcomePage(colors, local, isDark),
                    _buildOperationsPage(colors, local, isDark),
                    _buildSetupPage(colors, local, isDark),
                  ],
                ),
              ),

              
              _buildPageIndicator(colors),
              const SizedBox(height: 32),

              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        local.t('onboarding_skip'),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const Spacer(),

                    
                    FloatingActionButton(
                      heroTag: null,
                      onPressed: _currentPage == 2
                          ? _completeOnboarding
                          : _onNext,
                      backgroundColor: AppColors.primary,
                      elevation: 4,
                      child: _currentPage == 2
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(
    ColorScheme colors,
    LocalizationProvider local,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.currency_exchange,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          
          Text(
            local.t('onboarding_welcome_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          
          Text(
            local.t('onboarding_welcome_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildOperationsPage(
    ColorScheme colors,
    LocalizationProvider local,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.buyColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 64,
              color: AppColors.buyColor,
            ),
          ),
          const SizedBox(height: 48),

          
          Text(
            local.t('onboarding_operations_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          
          Text(
            local.t('onboarding_operations_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FeatureBadge(
                icon: Icons.add_card_rounded,
                color: AppColors.buyColor,
                isDark: isDark,
              ),
              const SizedBox(width: 32),
              _FeatureBadge(
                icon: Icons.account_balance_rounded,
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 32),
              _FeatureBadge(
                icon: Icons.trending_up_rounded,
                color: Colors.orange,
                isDark: isDark,
              ),
            ],
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildSetupPage(
    ColorScheme colors,
    LocalizationProvider local,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.secondaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          
          Text(
            local.t('onboarding_analytics_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            local.t('onboarding_analytics_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 40),

          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        local.t('settings_language'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _OnboardingLanguageSwitcher(),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        local.t('settings_theme'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _OnboardingThemeSwitcher(),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : colors.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _FeatureBadge({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }
}

class _OnboardingLanguageSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final local = context.watch<LocalizationProvider>();

    final languages = [
      ('ru', 'RU'),
      ('ky', 'KG'),
      ('en', 'EN'),
      ('uz', "O'Z"),
      ('uz_Cyrl', 'ЎЗ'),
    ];

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
                const Icon(Icons.check, size: 16, color: AppColors.primary),
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
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _OnboardingThemeSwitcher extends StatefulWidget {
  @override
  State<_OnboardingThemeSwitcher> createState() =>
      _OnboardingThemeSwitcherState();
}

class _OnboardingThemeSwitcherState extends State<_OnboardingThemeSwitcher> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SizedBox(
      width: 120,
      height: 36,
      child: ToggleButtons(
        isSelected: [theme.isLight, theme.isDark],
        onPressed: (index) {
          theme.setThemeMode(index == 0 ? ThemeMode.light : ThemeMode.dark);
        },
        borderRadius: BorderRadius.circular(10),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
        selectedColor: Colors.white,
        fillColor: AppColors.primary,
        color: AppColors.textSecondary,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.light_mode, size: 16),
                const SizedBox(width: 4),
                Text(
                  context.watch<LocalizationProvider>().t(
                    'settings_theme_light',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dark_mode, size: 16),
                const SizedBox(width: 4),
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
