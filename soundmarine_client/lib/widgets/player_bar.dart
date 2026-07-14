import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../services/api_service.dart';
import 'common/app_image.dart';
import '../services/liked_service.dart';

/// Where the bar sits.
/// - [low] = default position
/// - [lowest] = lowest (almost at the bottom of the screen)
enum PlayerBarPosition { low, lowest }


/// [position] = preset, [extraOffset] = adontional
class PlayerBarConfig {
  final PlayerBarPosition position;
  final double extraOffset;

  const PlayerBarConfig({
    this.position = PlayerBarPosition.low,
    this.extraOffset = 0,
  });
  
  double get totalOffset {
    switch (position) {
      case PlayerBarPosition.low:
        return extraOffset;
      case PlayerBarPosition.lowest:
        return extraOffset - 65;
    }
  }
}

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  static final ValueNotifier<PlayerBarConfig> config =
      ValueNotifier(const PlayerBarConfig());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: AudioPlayerService.player.playerStateStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final state = snapshot.data!;
        final isPlaying = state.playing;
        final hasTrack = AudioPlayerService.player.duration != null ||
            AudioPlayerService.hasEverPlayed;

        if (!hasTrack) return const SizedBox.shrink();

        return _PlayerBarContent(isPlaying: isPlaying);
      },
    );
  }
}

class _PlayerBarContent extends StatelessWidget {
  final bool isPlaying;

  const _PlayerBarContent({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity == null) return;
        if (velocity < -300 && AudioPlayerService.hasNext) {
          AudioPlayerService.skipToNext();
        } else if (velocity > 300 && AudioPlayerService.hasPrevious) {
          AudioPlayerService.skipToPrevious();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF040404),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TrackInfoRow(isPlaying: isPlaying),
            _ProgressBar(),
          ],
        ),
      ),
    );
  }
}

class _TrackInfoRow extends StatelessWidget {
  final bool isPlaying;

  const _TrackInfoRow({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final albumId = AudioPlayerService.currentAlbumId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _AlbumThumbnail(albumId: albumId),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AudioPlayerService.currentTrackTitle ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (AudioPlayerService.currentTrackId != null)
            _PlayerLikeButton(trackId: AudioPlayerService.currentTrackId!),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.blue,
              size: 28,
            ),
            onPressed: () => isPlaying
                ? AudioPlayerService.pause()
                : AudioPlayerService.resume(),
          ),
        ],
      ),
    );
  }
}

class _AlbumThumbnail extends StatelessWidget {
  final String? albumId;

  const _AlbumThumbnail({this.albumId});

  @override
  Widget build(BuildContext context) {
    if (albumId == null) {
      return _placeholder();
    }

    return AppImage(
      imageUrl: '${ApiService.baseUrl}/api/covers/$albumId',
      width: 44,
      height: 44,
      borderRadius: 6,
      placeholderIcon: Icons.music_note,
    );
  }

  Widget _placeholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.music_note, color: Colors.grey[600], size: 20),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: AudioPlayerService.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = AudioPlayerService.player.duration ?? Duration.zero;
        final progress = total.inMilliseconds > 0
            ? position.inMilliseconds / total.inMilliseconds
            : 0.0;

        return LinearProgressIndicator(
          borderRadius: BorderRadius.circular(6),
          value: progress,
          backgroundColor: const Color(0xFF001937),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 2,
        );
      },
    );
  }
}

class _PlayerLikeButton extends StatefulWidget {
  final String trackId;
  const _PlayerLikeButton({required this.trackId});

  @override
  State<_PlayerLikeButton> createState() => _PlayerLikeButtonState();
}

class _PlayerLikeButtonState extends State<_PlayerLikeButton> {
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