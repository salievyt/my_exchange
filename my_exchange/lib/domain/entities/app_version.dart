import 'package:equatable/equatable.dart';

/// Entity representing the latest app version info from the backend
class AppVersion extends Equatable {
  final String version;
  final int buildNumber;
  final bool isRequired;
  final String? updateUrl;
  final String? changelog;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.isRequired,
    this.updateUrl,
    this.changelog,
  });

  @override
  List<Object?> get props => [
    version,
    buildNumber,
    isRequired,
    updateUrl,
    changelog,
  ];
}
