import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../di/service_locator.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckAuthUseCase _checkAuthUseCase;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  static const String _bioUsernameKey = 'biometric_username';
  static const String _bioPasswordKey = 'biometric_password';
  static const String _bioEnabledKey = 'biometric_enabled';

  AuthProvider()
    : _loginUseCase = sl<LoginUseCase>(),
      _logoutUseCase = sl<LogoutUseCase>(),
      _getCurrentUserUseCase = sl<GetCurrentUserUseCase>(),
      _checkAuthUseCase = sl<CheckAuthUseCase>(),
      _secureStorage = sl<FlutterSecureStorage>(),
      _localAuth = LocalAuthentication();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasSavedCredentials = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasSavedCredentials => _hasSavedCredentials;

  /// Check if biometric auth is available on this device
  Future<void> checkBiometricAvailability() async {
    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      _hasSavedCredentials =
          await _secureStorage.read(key: _bioUsernameKey) != null;
      notifyListeners();
    } catch (e) {
      _biometricAvailable = false;
    }
  }

  /// Load biometric setting from SharedPreferences
  Future<void> loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool(_bioEnabledKey) ?? false;
    notifyListeners();
  }

  /// Enable or disable biometric login
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioEnabledKey, enabled);

    if (!enabled) {
      // Clear saved credentials when disabling biometric
      await _secureStorage.delete(key: _bioUsernameKey);
      await _secureStorage.delete(key: _bioPasswordKey);
      _hasSavedCredentials = false;
    }
    notifyListeners();
  }

  /// Save credentials for biometric login
  Future<void> _saveBiometricCredentials({
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: _bioUsernameKey, value: username);
    await _secureStorage.write(key: _bioPasswordKey, value: password);
    _hasSavedCredentials = true;
  }

  /// Clear saved biometric credentials (used on logout/settings toggle)
  @visibleForTesting
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _bioUsernameKey);
    await _secureStorage.delete(key: _bioPasswordKey);
    _hasSavedCredentials = false;
  }

  /// Authenticate with biometric (Face ID / Touch ID) and login
  Future<bool> loginWithBiometric({String? localizedReason}) async {
    try {
      // Check if biometric is available
      if (!_biometricAvailable) {
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      // Check if we have saved credentials
      final savedUsername = await _secureStorage.read(key: _bioUsernameKey);
      final savedPassword = await _secureStorage.read(key: _bioPasswordKey);

      if (savedUsername == null || savedPassword == null) {
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      // Authenticate with biometric
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason ?? 'Authenticate to sign in',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        _errorMessage = null; // user cancelled or failed - show localized string on screen
        notifyListeners();
        return false;
      }

      // Login with saved credentials
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final result = await _loginUseCase(
        username: savedUsername,
        password: savedPassword,
      );

      return result.fold(
        (failure) {
          _status = AuthStatus.unauthenticated;
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (user) {
          _user = user;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> login({
    required String username,
    required String password,
    bool saveForBiometric = false,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _loginUseCase(username: username, password: password);

    result.fold(
      (failure) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (user) async {
        _user = user;
        _status = AuthStatus.authenticated;

        // Save credentials for biometric login if enabled
        if (saveForBiometric && _biometricAvailable) {
          try {
            await _saveBiometricCredentials(
              username: username,
              password: password,
            );
            if (!_biometricEnabled) {
              await setBiometricEnabled(true);
            }
          } catch (e) {
            debugPrint('Failed to save biometric credentials: $e');
          }
        }

        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _logoutUseCase();

    // Clear biometric credentials on logout
    try {
      await clearBiometricCredentials();
    } catch (_) {}

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _checkAuthUseCase();

    result.fold(
      (failure) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      },
      (isAuthenticated) async {
        if (isAuthenticated) {
          final userResult = await _getCurrentUserUseCase();
          userResult.fold(
            (failure) {
              _status = AuthStatus.unauthenticated;
            },
            (user) {
              _user = user;
              _status = AuthStatus.authenticated;
            },
          );
        } else {
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
