import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_service.dart';
import '../services/swr_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/page_slide_transition.dart';
import '../widgets/playlist_list_item.dart';
import 'list_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  Stream<SwrResult<Playlist>> _playlistStream = const Stream.empty();

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  void _startStream() {
    setState(() {
      _playlistStream = SwrService.fetchList<Playlist>(
        cacheKey: 'playlists',
        fetcher: () => ApiService.getPlaylists(),
        toJson: (Playlist p) => p.toJson(),
        fromJson: Playlist.fromJson,
      );
    });
  }

  List<Playlist> _sorted(List<Playlist> playlists) {
    final sorted = [...playlists];
    sorted.sort((a, b) {
      if (a.playlistType == 'Liked') return -1;
      if (b.playlistType == 'Liked') return 1;
      final dateA = DateTime.parse(a.createdAt.replaceFirst(RegExp(r'\.\d+Z$'), 'Z'));
      final dateB = DateTime.parse(b.createdAt.replaceFirst(RegExp(r'\.\d+Z$'), 'Z'));
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<SwrResult<Playlist>>(
      stream: _playlistStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final playlists = _sorted(snapshot.data!.data);

        if (playlists.isEmpty) {
          return Container(
            color: Colors.black,
            child: const EmptyState(
              icon: Icons.queue_music,
              message: 'No playlists yet',
            ),
          );
        }

        return Container(
          color: Colors.black,
          child: RefreshIndicator(
            onRefresh: () async => _startStream(),
            color: Colors.white,
            backgroundColor: Colors.grey[900],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return PlaylistListItem(
                  playlist: playlist,
                  onTap: () => Navigator.push(
                    context,
                    PageSlideTransition(
                      child: ListScreen(
                        cover: playlist.playlistType == 'Liked'
                            ? AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1F77BE), Color(0xFF265E8B)],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 80,
                                    color: Colors.white54,
                                  ),
                                ),
                              )
                            : AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey[800],
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                        title: playlist.title,
                        subtitle: playlist.ownerId,
                        cacheKey: 'playlist_tracks_${playlist.id}',
                        fetcher: () => ApiService.getPlaylistTracks(playlist.id),
                        playlistSort: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}