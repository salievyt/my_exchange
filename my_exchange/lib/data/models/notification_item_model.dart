import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/app_notification.dart';

part 'notification_item_model.g.dart';

@JsonSerializable()
class NotificationItemModel {
  final int id;
  final String title;
  final String description;
  
  @JsonKey(name: 'notification_type')
  final String notificationType;
  
  @JsonKey(name: 'display_format')
  final String displayFormat;
  
  @JsonKey(name: 'app_version')
  final String? appVersion;
  
  @JsonKey(name: 'min_version')
  final String? minVersion;
  
  @JsonKey(name: 'latest_version')
  final String? latestVersion;
  
  @JsonKey(name: 'force_update', defaultValue: false)
  final bool forceUpdate;
  
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  @JsonKey(name: 'button_url')
  final String? buttonUrl;
  
  @JsonKey(name: 'button_text')
  final String? buttonText;
  
  final List<String> changelog;
  
  @JsonKey(name: 'publish_at')
  final DateTime publishAt;
  
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  
  final String status;
  final String platform;
  
  @JsonKey(name: 'target_audience')
  final String? targetAudience;

  final int priority;

  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;

  const NotificationItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.notificationType = 'info',
    this.displayFormat = 'modal',
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
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationItemModelToJson(this);

  AppNotification toEntity({bool isRead = false}) => AppNotification(
    id: id,
    title: title,
    description: description,
    type: AppNotificationType.fromApi(notificationType),
    displayFormat: NotificationDisplayFormat.fromApi(displayFormat),
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
    isRead: isRead,
  );
}
