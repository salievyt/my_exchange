import 'package:equatable/equatable.dart';

/// Types of in-app notifications
enum AppNotificationType {
  update,
  news,
  newFeature,
  maintenance,
  info,
  banner;

  String get apiValue {
    switch (this) {
      case AppNotificationType.update: return 'update';
      case AppNotificationType.news: return 'news';
      case AppNotificationType.newFeature: return 'new_feature';
      case AppNotificationType.maintenance: return 'maintenance';
      case AppNotificationType.info: return 'info';
      case AppNotificationType.banner: return 'banner';
    }
  }

  static AppNotificationType fromApi(String value) {
    switch (value) {
      case 'update': return AppNotificationType.update;
      case 'news': return AppNotificationType.news;
      case 'new_feature': return AppNotificationType.newFeature;
      case 'maintenance': return AppNotificationType.maintenance;
      case 'info': return AppNotificationType.info;
      case 'banner': return AppNotificationType.banner;
      default: return AppNotificationType.info;
    }
  }
}

/// Display formats for notifications
enum NotificationDisplayFormat {
  fullScreen,
  modal,
  bottomSheet,
  banner,
  card;

  String get apiValue {
    switch (this) {
      case NotificationDisplayFormat.fullScreen: return 'full_screen';
      case NotificationDisplayFormat.modal: return 'modal';
      case NotificationDisplayFormat.bottomSheet: return 'bottom_sheet';
      case NotificationDisplayFormat.banner: return 'banner';
      case NotificationDisplayFormat.card: return 'card';
    }
  }

  static NotificationDisplayFormat fromApi(String value) {
    switch (value) {
      case 'full_screen': return NotificationDisplayFormat.fullScreen;
      case 'modal': return NotificationDisplayFormat.modal;
      case 'bottom_sheet': return NotificationDisplayFormat.bottomSheet;
      case 'banner': return NotificationDisplayFormat.banner;
      case 'card': return NotificationDisplayFormat.card;
      default: return NotificationDisplayFormat.modal;
    }
  }
}

/// Entity representing an in-app notification from the server
class AppNotification extends Equatable {
  final int id;
  final String title;
  final String description;
  final AppNotificationType type;
  final NotificationDisplayFormat displayFormat;
  final String? appVersion;
  final String? minVersion;
  final String? latestVersion;
  final bool forceUpdate;
  final String? imageUrl;
  final String? buttonUrl;
  final String? buttonText;
  final List<String> changelog;
  final DateTime publishAt;
  final DateTime? expiresAt;
  final String status;
  final String platform;
  final String? targetAudience;
  final int priority;
  final bool isActive;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    this.description = '',
    this.type = AppNotificationType.info,
    this.displayFormat = NotificationDisplayFormat.modal,
    this.appVersion,
    this.minVersion,
    this.latestVersion,
    this.forceUpdate = false,
    this.imageUrl,
    this.buttonUrl,
    this.buttonText,
    this.changelog = const [],
    required this.publishAt,
    this.expiresAt,
    this.status = 'published',
    this.platform = 'all',
    this.targetAudience,
    this.priority = 0,
    this.isActive = true,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id, title, description, type, displayFormat, appVersion,
    minVersion, latestVersion, forceUpdate, imageUrl, buttonUrl,
    buttonText, changelog, publishAt, expiresAt, status, platform,
    targetAudience, priority, isActive, isRead,
  ];

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      type: type,
      displayFormat: displayFormat,
      appVersion: appVersion,
      minVersion: minVersion,
      latestVersion: latestVersion,
      forceUpdate: forceUpdate,
      imageUrl: imageUrl,
      buttonUrl: buttonUrl,
      buttonText: buttonText,
      changelog: changelog,
      publishAt: publishAt,
      expiresAt: expiresAt,
      status: status,
      platform: platform,
      targetAudience: targetAudience,
      priority: priority,
      isActive: isActive,
      isRead: isRead ?? this.isRead,
    );
  }
}
