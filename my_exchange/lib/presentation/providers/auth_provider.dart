import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../di/service_locator.dart';
import '../../domain/usecases/auth_usecases.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CheckAuthUseCase _checkAuthUseCase;

  AuthProvider()
    : _loginUseCase = sl<LoginUseCase>(),
      _logoutUseCase = sl<LogoutUseCase>(),
      _getCurrentUserUseCase = sl<GetCurrentUserUseCase>(),
      _checkAuthUseCase = sl<CheckAuthUseCase>();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

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
      (user) {
        _user = user;
        _status = AuthStatus.authenticated;
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
