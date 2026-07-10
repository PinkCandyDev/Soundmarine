import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/album.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A grid card for an [Album], showing its cover, title and artist.
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final httpHeaders = <String, String>{
      if (ApiService.token != null) 'Authorization': 'Bearer ${ApiService.token}',
    };

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: '${ApiService.baseUrl}/api/covers/${album.id}',
                httpHeaders: httpHeaders,
                memCacheWidth: 300,
                memCacheHeight: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Stack(
                  children: [
                    Positioned.fill(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[850]!,
                        highlightColor: Colors.grey[800]!,
                        child: Container(color: Colors.grey[800]),
                      ),
                    ),
                    Center(
                      child: Icon(Icons.album, color: Colors.grey[600], size: 100),
                    ),
                  ],
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.album, color: Colors.grey[600], size: 100),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.title,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            album.artistName ?? 'Unknown Artist',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
