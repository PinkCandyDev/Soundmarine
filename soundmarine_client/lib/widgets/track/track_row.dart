import 'package:flutter/material.dart';
import 'package:soundmarine_client/widgets/track/track_options_sheet.dart';
import '../../models/track.dart';
import '../../services/api_service.dart';
import '../../services/liked_service.dart';
import '../common/app_image.dart';

/// A single row in a track listing.
class TrackRow extends StatelessWidget {
  final Track track;
  final String? token;
  final bool dimmed;
  final VoidCallback onTap;

  const TrackRow({
    super.key,
    required this.track,
    this.token,
    this.dimmed = false,
    required this.onTap,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppImage(
                imageUrl: '${ApiService.baseUrl}/api/covers/${track.albumId}',
                width: 60,
                height: 60,
                memCacheWidth: 300,
                memCacheHeight: 300,
                borderRadius: 6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDuration(track.duration),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              _LikeButton(trackId: track.id),
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.grey[500]),
                onPressed: () => showTrackOptionsSheet(context, track),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A toggle like/unlike button that stays in sync with [LikedService].
class _LikeButton extends StatefulWidget {
  final String trackId;

  const _LikeButton({required this.trackId});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  @override
  Widget build(BuildContext context) {
    final liked = LikedService.instance.isLiked(widget.trackId);

    return IconButton(
      icon: Icon(
        liked ? Icons.favorite : Icons.favorite_border,
        color: liked ? Colors.blue : Colors.grey[500],
        size: 22,
      ),
      onPressed: () {
        LikedService.instance.toggle(widget.trackId, () {
          if (mounted) setState(() {});
        });
      },
    );
  }
}
