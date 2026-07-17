import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../di/service_locator.dart';

/// Simple news item data class from server
class NewsItem {
  final int id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String? linkUrl;
  final String? linkText;
  final int priority;
  final DateTime publishedAt;

  const NewsItem({
    required this.id,
    required this.title,
    this.summary = '',
    this.imageUrl,
    this.linkUrl,
    this.linkText,
    this.priority = 0,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    imageUrl: json['image_url'] as String?,
    linkUrl: json['link_url'] as String?,
    linkText: json['link_text'] as String?,
    priority: json['priority'] as int? ?? 0,
    publishedAt: json['published_at'] != null
        ? DateTime.parse(json['published_at'] as String)
        : DateTime.now(),
  );
}

/// Provider for scrollable news banner on main screen.
class NewsProvider extends ChangeNotifier {
  final DioClient _dioClient;

  NewsProvider() : _dioClient = sl<DioClient>();

  List<NewsItem> _news = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;

  List<NewsItem> get news => _news;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  int get newsCount => _news.length;
  bool get hasNews => _news.isNotEmpty;

  /// Fetch active news from the server
  Future<void> loadNews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get(
        '${ApiEndpoints.notifications}news/',
      );
      final data = response.data as Map<String, dynamic>;
      final newsList = data['news'] as List<dynamic>? ?? [];
      _news = newsList
          .map((json) => NewsItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _hasLoaded = true;
      _errorMessage = null;
    } on DioException catch (e) {
      debugPrint('[News] load ERROR: ${e.response?.statusCode}');
      _errorMessage = 'Ошибка загрузки новостей';
    } catch (e) {
      debugPrint('[News] load ERROR: $e');
      _errorMessage = 'Ошибка загрузки новостей';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
