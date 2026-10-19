import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      content = _buildPlaceholder();
    } else {
      String effectiveUrl = cleanUrl;
      if (kIsWeb &&
          (cleanUrl.contains('googleusercontent.com') ||
           cleanUrl.contains('ytimg.com') ||
           cleanUrl.contains('ggpht.com'))) {
        if (!cleanUrl.contains('api/image-proxy')) {
          effectiveUrl = '${ApiConfig.imageProxyUrl}?url=${Uri.encodeComponent(cleanUrl)}';
        }
      }

      content = Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.bgSurface,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Gracefully handle 429, timeouts, and network issues without showing raw error text
          return _buildPlaceholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        gradient: LinearGradient(
          colors: [
            AppColors.bgSurface,
            AppColors.primary.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: AppColors.primary,
          size: (width != null && width! < 45) ? 20 : 26,
        ),
      ),
    );
  }
}
