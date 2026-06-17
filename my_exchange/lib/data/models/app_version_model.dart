import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/app_version.dart';

part 'app_version_model.g.dart';

@JsonSerializable()
class AppVersionModel extends AppVersion {
  const AppVersionModel({
    required super.version,
    @JsonKey(name: 'build_number', defaultValue: 0) required super.buildNumber,
    @JsonKey(name: 'is_required', defaultValue: false) required super.isRequired,
    @JsonKey(name: 'update_url') required super.updateUrl,
    required super.changelog,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionModelToJson(this);

  AppVersion toEntity() => AppVersion(
    version: version,
    buildNumber: buildNumber,
    isRequired: isRequired,
    updateUrl: updateUrl,
    changelog: changelog,
  );
}
