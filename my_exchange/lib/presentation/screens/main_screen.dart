import 'package:flutter/material.dart';
import 'package:my_exchange/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_provider.dart';
import '../../features/operations/screens/operations_screen.dart';
import '../../features/cash/screens/cash_screen.dart';
import '../../features/currencies/screens/currencies_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../providers/update_notification_provider.dart';
import '../providers/notification_center_provider.dart';
import '../providers/news_provider.dart';
import '../screens/settings_screen.dart';
import '../widgets/update_notification_dialog.dart';
import '../widgets/news_banner_carousel.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;

  static const List<Widget> _screens = [
    OperationsScreen(),
    CashScreen(),
    CurrenciesScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
      _checkNotifications();
      _loadNews();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      
      context.read<AuthProvider>().lockApp();
    }
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _checkForUpdate() {
    final updateProvider = context.read<UpdateNotificationProvider>();
    updateProvider.addListener(_onUpdateChecked);
    updateProvider.checkForUpdate();
  }

  void _checkNotifications() {
    context.read<NotificationCenterProvider>().loadNotifications();
  }

  void _loadNews() {
    context.read<NewsProvider>().loadNews();
  }

  void _onUpdateChecked() {
    if (!mounted) return;
    final updateProvider = context.read<UpdateNotificationProvider>();
    updateProvider.removeListener(_onUpdateChecked);

    final update = updateProvider.pendingUpdate;
    if (update != null) {
      showDialog(
        context: context,
        barrierDismissible: !update.isRequired,
        builder: (context) => UpdateNotificationDialog(
          version: update.version,
          isRequired: update.isRequired,
          updateUrl: update.updateUrl,
          changelog: update.changelog,
        ),
      ).then((_) {
        if (mounted && !update.isRequired) {
          updateProvider.dismiss();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          
          Consumer<NewsProvider>(
            builder: (context, newsProvider, _) {
              if (!newsProvider.hasNews) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: NewsBannerCarousel(news: newsProvider.news),
              );
            },
          ),
          Expanded(              child: RepaintBoundary(
                child: Stack(
                  children: List.generate(_screens.length, (index) {
                    final isSelected = _currentIndex == index;
                    final isSlidingRight = index > _previousIndex;
                    final slideX = isSelected
                        ? 0.0
                        : (isSlidingRight ? 0.15 : -0.15);
                    return RepaintBoundary(
                      child: AnimatedSlide(
                        offset: Offset(slideX, 0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: IgnorePointer(
                            ignoring: !isSelected,
                            child: _screens[index],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      bottomNavigationBar: Consumer<LocalizationProvider>(
        builder: (context, local, child) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            indicatorColor: Colors.blue,
            onDestinationSelected: _onTabChanged,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.swap_horiz_outlined),
                selectedIcon: const Icon(Icons.swap_horiz, color: Colors.white,),
                label: local.t('nav_operations'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_outlined),
                selectedIcon: const Icon(Icons.account_balance, color: Colors.white,),
                label: local.t('nav_cash'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.currency_exchange_outlined),
                selectedIcon: const Icon(Icons.currency_exchange, color: Colors.white,),
                label: local.t('nav_currencies'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.analytics_outlined),
                selectedIcon: const Icon(Icons.analytics, color: Colors.white,),
                label: local.t('nav_analytics'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person, color: Colors.white,),
                label: local.t('nav_settings'),
              ),
            ],
          );
        },
      ),
    );
  }
}
