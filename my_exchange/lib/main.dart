import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/localization_provider.dart';
import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/currency_provider.dart';
import 'presentation/providers/operation_provider.dart';
import 'presentation/providers/cash_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/update_notification_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/reports_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await initDependencies();

  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}


/// Parse a custom locale string into a [Locale] object.
Locale _parseLocale(String code) {
  if (code == 'uz_Cyrl') {
    return const Locale.fromSubtags(
      languageCode: 'uz',
      scriptCode: 'Cyrl',
      countryCode: 'UZ',
    );
  }
  return Locale(code);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider()..loadCurrencies(),
        ),
        ChangeNotifierProvider(create: (_) => OperationProvider()),
        ChangeNotifierProvider(create: (_) => CashProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => UpdateNotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: Consumer2<LocalizationProvider, ThemeProvider>(
        builder: (context, local, themeProvider, child) {
          return MaterialApp(
            title: 'My Exchange',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('ky', 'KG'),
              Locale('en', 'US'),
              Locale('uz', 'UZ'),
              Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl', countryCode: 'UZ'),
            ],
            locale: _parseLocale(local.locale),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const SplashScreen();
        }

        
        if (authProvider.status == AuthStatus.unauthenticated) {
          return const LoginScreen();
        }

        
        if (authProvider.isLocked) {
          return const LockScreen();
        }

        
        return const MainScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.currency_exchange,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'My Exchange',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
