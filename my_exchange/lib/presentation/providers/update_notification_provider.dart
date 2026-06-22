import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../di/service_locator.dart';
import '../../domain/entities/app_version.dart';

class UpdateNotificationProvider extends ChangeNotifier {
  final NotificationRemoteDataSource _dataSource;

  UpdateNotificationProvider()
      : _dataSource = sl<NotificationRemoteDataSource>();

  AppVersion? _pendingUpdate;
  bool _isChecking = false;

  AppVersion? get pendingUpdate => _pendingUpdate;
  bool get isChecking => _isChecking;
  bool get hasUpdate => _pendingUpdate != null;

  /// Check for app updates from the backend.
  Future<void> checkForUpdate() async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      
      String platform;
      try {
        
        platform = defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
      } catch (_) {
        platform = 'android';
      }

      final currentVersion = AppConstants.appVersion;
      final buildNumber = 1; 

      final result = await _dataSource.checkAppVersion(
        platform: platform,
        currentVersion: currentVersion,
        buildNumber: buildNumber,
      );

      _pendingUpdate = result;
    } catch (_) {
      
      _pendingUpdate = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Dismiss the pending update notification.
  void dismiss() {
    _pendingUpdate = null;
    notifyListeners();
  }
}
