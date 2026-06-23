import 'package:dio/dio.dart';

/// Extracts a meaningful error message from a DRF (Django REST Framework) error response.
///
/// DRF returns errors in various formats:
/// - `{"error": "..."}` — custom business logic errors from views
/// - `{"detail": "..."}` — DRF generic errors (e.g. 401, 403, 404)
/// - `{"non_field_errors": ["..."]}` — DRF non-field validation errors
/// - `{"field_name": ["..."]}` — DRF field-level validation errors
String extractDrfErrorMessage(DioException e, String fallback) {
  if (e.response?.data == null) return fallback;
  final data = e.response!.data;

  if (data is Map) {
    // Custom business logic errors from views: {"error": "..."}
    if (data.containsKey('error')) {
      final error = data['error'];
      if (error is List && error.isNotEmpty) {
        return error.first.toString();
      }
      return error.toString();
    }

    // DRF generic errors: {"detail": "..."}
    if (data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        return detail.first.toString();
      }
      return detail.toString();
    }

    // DRF non-field validation errors: {"non_field_errors": ["..."]}
    if (data.containsKey('non_field_errors')) {
      final errors = data['non_field_errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
      return errors.toString();
    }

    // DRF field-level validation errors: {"field_name": ["..."]}
    if (data.isNotEmpty) {
      final firstKey = data.keys.first;
      final firstValue = data[firstKey];
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      if (firstValue is String && firstValue.isNotEmpty) {
        return firstValue;
      }
      return firstValue.toString();
    }
  }

  if (data is List && data.isNotEmpty) {
    return data.join(', ');
  }

  if (data is String && data.trim().isNotEmpty) {
    return data;
  }

  return fallback;
}
