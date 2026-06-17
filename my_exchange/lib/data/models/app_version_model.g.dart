// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVersionModel _$AppVersionModelFromJson(Map<String, dynamic> json) =>
    AppVersionModel(
      version: json['version'] as String,
      buildNumber: (json['build_number'] as num?)?.toInt() ?? 0,
      isRequired: json['is_required'] as bool? ?? false,
      updateUrl: json['update_url'] as String?,
      changelog: json['changelog'] as String?,
    );

Map<String, dynamic> _$AppVersionModelToJson(AppVersionModel instance) =>
    <String, dynamic>{
      'version': instance.version,
      'build_number': instance.buildNumber,
      'is_required': instance.isRequired,
      'update_url': instance.updateUrl,
      'changelog': instance.changelog,
    };
