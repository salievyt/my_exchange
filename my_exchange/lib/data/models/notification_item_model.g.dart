// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItemModel _$NotificationItemModelFromJson(
  Map<String, dynamic> json,
) => NotificationItemModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  notificationType: json['notification_type'] as String? ?? 'info',
  displayFormat: json['display_format'] as String? ?? 'modal',
  appVersion: json['app_version'] as String?,
  minVersion: json['min_version'] as String?,
  latestVersion: json['latest_version'] as String?,
  forceUpdate: json['force_update'] as bool? ?? false,
  imageUrl: json['image_url'] as String?,
  buttonUrl: json['button_url'] as String?,
  buttonText: json['button_text'] as String?,
  changelog:
      (json['changelog'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  publishAt: DateTime.parse(json['publish_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  status: json['status'] as String? ?? 'published',
  platform: json['platform'] as String? ?? 'all',
  targetAudience: json['target_audience'] as String?,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationItemModelToJson(
  NotificationItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'notification_type': instance.notificationType,
  'display_format': instance.displayFormat,
  'app_version': instance.appVersion,
  'min_version': instance.minVersion,
  'latest_version': instance.latestVersion,
  'force_update': instance.forceUpdate,
  'image_url': instance.imageUrl,
  'button_url': instance.buttonUrl,
  'button_text': instance.buttonText,
  'changelog': instance.changelog,
  'publish_at': instance.publishAt.toIso8601String(),
  'expires_at': instance.expiresAt?.toIso8601String(),
  'status': instance.status,
  'platform': instance.platform,
  'target_audience': instance.targetAudience,
  'priority': instance.priority,
  'is_active': instance.isActive,
};
