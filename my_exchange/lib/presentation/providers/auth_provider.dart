import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
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

  static const String _pinCodeKey = 'app_pin_code';
  static const String _pinEnabledKey = 'app_pin_enabled';

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
  bool _isLocked = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  bool get isLocked => _isLocked;

  // ─── Biometric ────────────────────────────────────────────────

  Future<void> checkBiometricAvailability() async {
    try {
      _biometricAvailable =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      notifyListeners();
    } catch (e) {
      _biometricAvailable = false;
    }
  }

  Future<void> loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('app_biometric_enabled') ?? false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_biometric_enabled', enabled);
    notifyListeners();
  }

  /// Authenticate with biometric (Face ID / Touch ID) for app unlock.
  /// Shows the native OS fingerprint / Face ID system dialog.
  Future<bool> authenticateWithBiometric({String? localizedReason}) async {
    try {
      if (!_biometricAvailable) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason:
            localizedReason ?? 'Authenticate to unlock the app',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
        authMessages: <AuthMessages>[
          const AndroidAuthMessages(
            signInTitle: 'Вход по отпечатку',
            signInHint: 'Приложите палец к сканеру',
            cancelButton: 'Отмена',
          ),
          const IOSAuthMessages(
            cancelButton: 'Отмена',
            localizedFallbackTitle: 'Ввести пароль устройства',
          ),
        ],
      );
      return authenticated;
    } on LocalAuthException catch (e) {
      debugPrint('Biometric auth error (LocalAuthException): $e');
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  // ─── PIN Code ─────────────────────────────────────────────────

  Future<bool> hasPinCode() async {
    final pin = await _secureStorage.read(key: _pinCodeKey);
    return pin != null;
  }

  Future<void> setPinCode(String pin) async {
    await _secureStorage.write(key: _pinCodeKey, value: pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, true);
    notifyListeners();
  }

  Future<bool> verifyPinCode(String pin) async {
    final savedPin = await _secureStorage.read(key: _pinCodeKey);
    return savedPin == pin;
  }

  Future<void> removePinCode() async {
    await _secureStorage.delete(key: _pinCodeKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, false);
    _isLocked = false;
    notifyListeners();
  }

  // ─── App Lock / Unlock ────────────────────────────────────────

  Future<void> lockApp() async {
    if (await hasAnyLockMethod()) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }

  Future<bool> hasAnyLockMethod() async {
    final hasPin = await hasPinCode();
    return hasPin || (_biometricEnabled && _biometricAvailable);
  }

  // ─── Authentication ───────────────────────────────────────────

  Future<void> login({
    required String username,
    required String password,
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

        // Check if PIN or biometric is set up
        _isLocked = false; // Don't lock immediately after login
        await checkBiometricAvailability();
        await loadBiometricSetting();

        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _logoutUseCase();

    _user = null;
    _status = AuthStatus.unauthenticated;
    _isLocked = false;
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

        // After successful auth check, load PIN setting to determine if app should be locked
        if (_status == AuthStatus.authenticated) {
          final prefs = await SharedPreferences.getInstance();
          final hasPin = prefs.getBool(_pinEnabledKey) ?? false;
          await checkBiometricAvailability();
          await loadBiometricSetting();
          if (hasPin) {
            final pin = await _secureStorage.read(key: _pinCodeKey);
            if (pin != null) {
              _isLocked = true;
            }
          } else if (_biometricEnabled && _biometricAvailable) {
            _isLocked = true;
          }
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
