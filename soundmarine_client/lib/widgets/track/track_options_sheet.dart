import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../screens/list_screen.dart';
import '../../widgets/common/app_image.dart';
import '../../widgets/common/page_slide_transition.dart';
import '../../widgets/player_bar.dart';

Future<void> showTrackOptionsSheet(BuildContext context, Track track) {
  final previousConfig = PlayerBar.config.value;
  PlayerBar.config.value = const PlayerBarConfig(extraOffset: 80);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => TrackOptionsSheet(track: track, previousConfig: previousConfig),
  );
}

class TrackOptionsSheet extends StatefulWidget {
  final Track track;
  final PlayerBarConfig previousConfig;
  const TrackOptionsSheet({super.key, required this.track, required this.previousConfig});

  @override
  State<TrackOptionsSheet> createState() => _TrackOptionsSheetState();
}

class _TrackOptionsSheetState extends State<TrackOptionsSheet> {
  bool _showingPlaylists = false;
  Animation<double>? _routeAnim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnim != null) return;
    _routeAnim = ModalRoute.of(context)?.animation;
    _routeAnim?.addStatusListener(_onAnim);
  }

  void _onAnim(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      PlayerBar.config.value = widget.previousConfig;
    }
  }

  @override
  void dispose() {
    _routeAnim?.removeStatusListener(_onAnim);
    super.dispose();
  }

  void _goToAlbum() {
    final albumId = widget.track.albumId;
    if (albumId == null) return;
    Navigator.of(context).pop();
    _navigateToAlbum(albumId);
  }

  Future<void> _navigateToAlbum(String albumId) async {
    String albumTitle = widget.track.title;
    String artistName = widget.track.artistName;

    final cachedAlbums = await CacheService.getList('albums');
    if (cachedAlbums != null) {
      final idx = cachedAlbums.indexWhere((j) => j['id'] == albumId);
      if (idx >= 0) {
        albumTitle = cachedAlbums[idx]['title'] ?? albumTitle;
        artistName = cachedAlbums[idx]['artistName'] ?? artistName;
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      PageSlideTransition(
        child: ListScreen(
          cover: AppCoverImage(
            imageUrl: '${ApiService.baseUrl}/api/covers/$albumId',
            fallbackIcon: Icons.album,
            fallbackIconSize: 80,
          ),
          title: albumTitle,
          subtitle: artistName,
          cacheKey: 'album_tracks_$albumId',
          fetcher: () => ApiService.getAlbumTracks(albumId),
          playlistSort: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
        child: _showingPlaylists
            ? _PlaylistPicker(
          key: const ValueKey('playlists'),
          track: widget.track,
          onBack: () {
            setState(() => _showingPlaylists = false);
            PlayerBar.config.value = const PlayerBarConfig(extraOffset: 80);
          },
        )
            : _MainOptions(
          key: const ValueKey('main'),
          onAddToPlaylist: () => setState(() => _showingPlaylists = true),
          onGoToAlbum: _goToAlbum,
        ),
      ),
    );
  }
}

class _MainOptions extends StatelessWidget {
  final VoidCallback onAddToPlaylist;
  final VoidCallback onGoToAlbum;
  const _MainOptions({
    super.key,
    required this.onAddToPlaylist,
    required this.onGoToAlbum,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        _OptionTile(
          icon: Icons.playlist_add,
          label: 'Add to playlist',
          onTap: onAddToPlaylist,
        ),
        _OptionTile(
          icon: Icons.album,
          label: 'Go to album',
          onTap: onGoToAlbum,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}


class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[300]),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class _PlaylistPicker extends StatefulWidget {
  final Track track;
  final VoidCallback onBack;
  const _PlaylistPicker({
    super.key,
    required this.track,
    required this.onBack,
  });

  @override
  State<_PlaylistPicker> createState() => _PlaylistPickerState();
}

class _PlaylistPickerState extends State<_PlaylistPicker> {
  late Future<List<Playlist>> _future;
  late int _pickerNonce;

  @override
  void initState() {
    super.initState();
    _pickerNonce = DateTime.now().millisecondsSinceEpoch;
    _future = ApiService.getPlaylists().then((playlists) {
      if (mounted) _setOffset(playlists.length);
      return playlists;
    });
  }
  
  double _pickerHeight(int count) {
    const handle = 20.0;   // 8 + 4 + 8
    const header = 56.0;
    const itemH = 56.0;
    const bottom = 8.0;
    return handle + header + (count.clamp(1, 4) * itemH) + bottom;
  }

  void _setOffset(int count) {
    final extra = ((count.clamp(1, 4) - 1).clamp(0, 3)) * 50.0;
    PlayerBar.config.value = PlayerBarConfig(extraOffset: 80 + extra);
  }
  Future<void> _add(Playlist playlist) async {
    try {
      await ApiService.addToPlaylist(playlist.id, widget.track.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to: "${playlist.title}"'),
            backgroundColor: const Color(0xFF001937),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFF001937),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Playlist>>(
      future: _future,
      builder: (context, snapshot) {
        final playlists = snapshot.data ?? [];
        final count = playlists.length;
        final height = _pickerHeight(count);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: _pickerHeight(1),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                    ),
                    const Text(
                      'Add to playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Couldn't load playlists",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              else if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No playlists',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: playlist.playlistType == 'Liked'
                            ? Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1F77BE), Color(0xFF265E8B)],
                            ),
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                        )
                            : SizedBox(
                          width: 44,
                          height: 44,
                          child: AppImage(
                            key: ValueKey('plpicker_${playlist.id}_$_pickerNonce'),
                            imageUrl: '${playlist.coverUrl}${playlist.coverUpdatedAt != null ? '&' : '?'}_=$_pickerNonce',
                            fit: BoxFit.cover,
                            borderRadius: 6,
                            placeholderIcon: Icons.music_note,
                          ),
                        ),
                        title: Text(
                          playlist.title,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _add(playlist),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}