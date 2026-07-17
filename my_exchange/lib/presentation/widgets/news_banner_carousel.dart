import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../providers/news_provider.dart';

/// Scrollable news banner carousel for the main screen top.
class NewsBannerCarousel extends StatefulWidget {
  final List<NewsItem> news;

  const NewsBannerCarousel({super.key, required this.news});

  @override
  State<NewsBannerCarousel> createState() => _NewsBannerCarouselState();
}

class _NewsBannerCarouselState extends State<NewsBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openLink(BuildContext context, String url, String title) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } catch (_) {
        // fall through to error handler
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть ссылку: $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getBannerColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.secondary,
      AppColors.warning,
    ];
    return colors[index % colors.length];
  }

  IconData _getBannerIcon(int index) {
    final icons = [
      Icons.campaign_rounded,
      Icons.new_releases_rounded,
      Icons.star_rounded,
      Icons.auto_awesome_rounded,
      Icons.notifications_active_rounded,
    ];
    return icons[index % icons.length];
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.news.any((n) => n.imageUrl != null && n.imageUrl!.isNotEmpty) ? 100 : 76,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.news.length,
            itemBuilder: (context, index) {
              final news = widget.news[index];
              final color = _getBannerColor(index);
              return _BannerCard(
                news: news,
                color: color,
                icon: _getBannerIcon(index),
                isDark: isDark,
                onTap: news.linkUrl != null && news.linkUrl!.isNotEmpty
                    ? () => _openLink(context, news.linkUrl!, news.title)
                    : null,
              );
            },
          ),
        ),
        if (widget.news.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.news.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _getBannerColor(i)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final NewsItem news;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _BannerCard({
    required this.news,
    required this.color,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  bool get _hasImage => news.imageUrl != null && news.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: _hasImage ? _buildImageCard() : _buildIconCard(),
      ),
    );
  }

  /// Card with background image + gradient overlay + text
  Widget _buildImageCard() {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.network(
            news.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => _buildIconCard(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: color.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
        // Gradient overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.25),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ),
        // Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        news.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (news.summary.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            news.summary,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (news.linkUrl != null && news.linkUrl!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Card with icon + text (no image)
  Widget _buildIconCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  news.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (news.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      news.summary,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (news.linkUrl != null && news.linkUrl!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 12, color: color),
            ),
        ],
      ),
    );
  }
}
