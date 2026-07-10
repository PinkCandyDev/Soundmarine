import 'package:flutter/material.dart';
import '../../models/track.dart';
import '../../services/audio_player_service.dart';
import '../../services/audio_proxy_server.dart';
import 'track_row.dart';

class TrackList extends StatelessWidget {
  final List<Track> tracks;
  final bool playlist;
  final String? token;
  final bool isOffline;

  const TrackList({
    super.key,
    required this.tracks,
    required this.playlist,
    this.token,
    this.isOffline = false,
  });

  List<Track> _sorted() {
    final sorted = [...tracks];
    sorted.sort((a, b) {
      // Tracks without numbers sort to the end
      if (a.trackNumber <= 0 && b.trackNumber <= 0) return a.title.compareTo(b.title);
      if (a.trackNumber <= 0) return 1;
      if (b.trackNumber <= 0) return -1;
      // Albums sort ascending, playlists sort descending
      return playlist
          ? b.trackNumber.compareTo(a.trackNumber)
          : a.trackNumber.compareTo(b.trackNumber);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedTracks = _sorted();
    return SliverFixedExtentList(
      itemExtent: 76,
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = sortedTracks[index];
          final cached = AudioProxyServer.instance.isCached(track.id);
          final dim = isOffline && !cached;

          return TrackRow(
            track: track,
            token: token,
            dimmed: dim,
            onTap: () {
              final queue = sortedTracks
                  .map((t) => QueueTrack(
                        trackId: t.id,
                        title: t.title,
                        albumId: t.albumId,
                        artistName: t.artistName,
                      ))
                  .toList();
              AudioPlayerService.setQueue(queue, index);
            },
          );
        },
        childCount: sortedTracks.length,
      ),
    );
  }
}