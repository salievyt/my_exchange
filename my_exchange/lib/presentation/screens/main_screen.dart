import 'package:flutter/material.dart';
import 'package:my_exchange/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_provider.dart';
import '../../features/operations/screens/operations_screen.dart';
import '../../features/cash/screens/cash_screen.dart';
import '../../features/currencies/screens/currencies_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../providers/update_notification_provider.dart';
import '../screens/settings_screen.dart';
import '../widgets/update_notification_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OperationsScreen(),
    const CashScreen(),
    const CurrenciesScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay update check to avoid calling notifyListeners during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
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
      // App went to background — lock it
      context.read<AuthProvider>().lockApp();
    }
  }

  void _checkForUpdate() {
    final updateProvider = context.read<UpdateNotificationProvider>();
    updateProvider.addListener(_onUpdateChecked);
    updateProvider.checkForUpdate();
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

      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Consumer<LocalizationProvider>(
        builder: (context, local, child) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            indicatorColor: Colors.blue,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
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
