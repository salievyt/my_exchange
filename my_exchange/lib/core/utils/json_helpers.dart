/// Sentinel date for missing timestamp fields from the server.
/// Used instead of DateTime.now() to avoid showing incorrect "just now" times.
final DateTime missingDate = DateTime(2000, 1, 1);

/// Safely parse a [value] as [int], handling String, null, and num types.
int jsonInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Safely parse a [value] as [double], handling String, null, and num types.
double jsonDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Safely parse a [value] as [DateTime], returning [missingDate] on null.
DateTime jsonDateTime(dynamic value) {
  if (value == null) return missingDate;
  if (value is String) return DateTime.tryParse(value) ?? missingDate;
  return missingDate;
}
