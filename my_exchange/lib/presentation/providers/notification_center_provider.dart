import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/drf_error_helper.dart';
import '../../data/models/notification_item_model.dart';
import '../../di/service_locator.dart';
import '../../domain/entities/app_notification.dart';

/// Provider for In-App Notification & Update Center.
class NotificationCenterProvider extends ChangeNotifier {
  final DioClient _dioClient;

  NotificationCenterProvider() : _dioClient = sl<DioClient>();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChecked = false;

  // Version info from server
  String? _latestVersion;
  String? _latestChangelog;
  String? _minVersion;
  bool _forceUpdate = false;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasChecked => _hasChecked;
  bool get forceUpdate => _forceUpdate;
  String? get latestVersion => _latestVersion;
  String? get minVersion => _minVersion;
  String? get latestChangelog => _latestChangelog;

  /// Active (unread) notifications for display
  List<AppNotification> get activeNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Banner notifications for the main screen
  List<AppNotification> get bannerNotifications =>
      _notifications.where((n) =>
        !n.isRead && n.displayFormat == NotificationDisplayFormat.banner
      ).toList();

  /// Unread notifications for popup (modal, full_screen, bottom_sheet)
  List<AppNotification> get popupNotifications =>
      _notifications.where((n) =>
        !n.isRead && n.displayFormat != NotificationDisplayFormat.banner
          && n.displayFormat != NotificationDisplayFormat.card
      ).toList();

  /// Filter notifications by type
  List<AppNotification> getNotificationsByType(AppNotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  /// Filter notifications by read status
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  /// Fetch notifications from the server
  Future<void> loadNotifications({String platform = 'android'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];
      final currentBuild = AppConstants.appVersion;

      final response = await _dioClient.dio.get(
        ApiEndpoints.appNotifications,
        queryParameters: {
          'platform': platform,
          'current_build': currentBuild,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Parse version info
      final versionInfo = data['version'] as Map<String, dynamic>? ?? {};
      _latestVersion = versionInfo['latest_version'] as String?;
      _latestChangelog = versionInfo['latest_changelog'] as String?;
      _minVersion = versionInfo['min_version'] as String?;
      _forceUpdate = data['force_update'] as bool? ?? false;

      // Parse notifications
      final notificationsList = data['notifications'] as List<dynamic>? ?? [];
      _notifications = notificationsList.map((json) {
        final model = NotificationItemModel.fromJson(json as Map<String, dynamic>);
        final isRead = readIds.contains(model.id.toString());
        return model.toEntity(isRead: isRead);
      }).toList();

      // Sort by priority
      _notifications.sort((a, b) => b.priority.compareTo(a.priority));

      _hasChecked = true;
      _errorMessage = null;
    } on DioException catch (e) {
      debugPrint('[Notifications] load ERROR: ${e.response?.statusCode}: ${e.response?.data}');
      _errorMessage = extractDrfErrorMessage(e, 'Ошибка загрузки уведомлений');
    } catch (e) {
      debugPrint('[Notifications] load UNEXPECTED ERROR: $e');
      _errorMessage = 'Ошибка загрузки уведомлений: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark a notification as read (locally)
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    // Persist to local storage
    await _saveReadIds();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveReadIds();
    }
  }

  /// Track notification interaction (view/click)
  Future<void> trackNotification(int notificationId, {String action = 'view'}) async {
    try {
      await _dioClient.dio.post(
        '${ApiEndpoints.notificationTrack}$notificationId/track/',
        data: {'action': action},
      );
    } catch (e) {
      debugPrint('[Notifications] Track ERROR: $e');
    }
  }

  /// Save read notification IDs to local storage
  Future<void> _saveReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = _notifications
        .where((n) => n.isRead)
        .map((n) => n.id.toString())
        .toList();
    await prefs.setStringList('read_notification_ids', readIds);
    await prefs.setString('last_check_time', DateTime.now().toIso8601String());
  }

  /// Mark update as seen (for update notifications)
  Future<void> markUpdateSeen(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_seen_version', version);
  }

  /// Clear all locally stored data
  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('read_notification_ids');
    await prefs.remove('last_check_time');
    await prefs.remove('last_seen_version');
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: false);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
