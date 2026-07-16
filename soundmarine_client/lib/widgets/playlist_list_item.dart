import 'package:flutter/material.dart';
import '../models/playlist.dart';
import 'common/app_image.dart';

/// A list row for a [Playlist] with a coloured thumbnail, title and type label.
class PlaylistListItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final int refreshNonce;

  const PlaylistListItem({
    super.key,
    required this.playlist,
    required this.onTap,
    this.refreshNonce = 0,
  });

  String get _coverUrl {
    final base = playlist.coverUrl;
    final separator = playlist.coverUpdatedAt != null ? '&' : '?';
    return '$base${separator}v=$refreshNonce';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildThumbnail(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _buildSubtitle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (playlist.playlistType == 'Liked') {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F77BE), Color(0xFF265E8B)],
          ),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 30),
      );
    }

    return SizedBox(
      width: 70,
      height: 70,
      child: AppImage(
        key: ValueKey('pl_${playlist.id}_$refreshNonce'),
        imageUrl: _coverUrl,
        fit: BoxFit.cover,
        borderRadius: 4,
        placeholderIcon: Icons.music_note,
      ),
    );
  }

  Widget _buildSubtitle() {
    final typeLabel = playlist.playlistType == 'Liked' ? 'Liked Songs' : 'Playlist';
    return Text(
      typeLabel,
      style: TextStyle(color: Colors.grey[400], fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
