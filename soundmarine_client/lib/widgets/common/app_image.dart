import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double borderRadius;
  final PlaceholderWidgetBuilder? placeholderOverride;
  final IconData placeholderIcon;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius = 0,
    this.placeholderOverride,
    this.placeholderIcon = Icons.album,
  });

  @override
  Widget build(BuildContext context) {
    final httpHeaders = <String, String>{
      if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: httpHeaders,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fit: fit,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: placeholderOverride ??
            (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    color: Colors.grey[800],
    child: Icon(placeholderIcon, color: Colors.grey[600], size: 24),
  );
}

/// A full-size album/playlist cover with rounded corners and optional shimmer.
class AppCoverImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final bool useShimmer;

  const AppCoverImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 16,
    this.fallbackIcon = Icons.album,
    this.fallbackIconSize = 80,
    this.useShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final httpHeaders = <String, String>{
      if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
    };

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: httpHeaders,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (useShimmer) {
      return Stack(
        children: [
          Positioned.fill(
            child: _ShimmerBox(),
          ),
          Center(
            child: Icon(fallbackIcon, color: Colors.grey[600], size: fallbackIconSize),
          ),
        ],
      );
    }
    return Container(
      color: Colors.grey[800],
      child: Icon(fallbackIcon, color: Colors.grey[600], size: fallbackIconSize),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import shimmer lazily to avoid hard dependency if removed
    return Container(color: Colors.grey[850]);
  }
}
