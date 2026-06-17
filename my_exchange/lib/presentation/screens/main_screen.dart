import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/operations/screens/operations_screen.dart';
import '../../features/cash/screens/cash_screen.dart';
import '../../features/currencies/screens/currencies_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../providers/update_notification_provider.dart';
import '../widgets/update_notification_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OperationsScreen(),
    const CashScreen(),
    const CurrenciesScreen(),
    const AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay update check to avoid calling notifyListeners during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: Colors.blue,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz, color: Colors.white,),
            label: 'Операции',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: Colors.white,),
            label: 'Касса',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange, color: Colors.white,),
            label: 'Валюты',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: Colors.white,),
            label: 'Аналитика',
          ),
        ],
      ),
    );
  }
}
