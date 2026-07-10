import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/swr_service.dart';
import '../widgets/album_card.dart';
import '../widgets/common/app_image.dart';
import '../widgets/common/page_slide_transition.dart';
import 'list_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  Stream<SwrResult<Album>> _albumStream = const Stream.empty();

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  void _startStream() {
    setState(() {
      _albumStream = SwrService.fetchList<Album>(
        cacheKey: 'albums',
        fetcher: () => ApiService.getAlbums(),
        toJson: (Album a) => a.toJson(),
        fromJson: Album.fromJson,
      );
    });
  }

  Future<void> _onRefresh() async {
    await CacheService.invalidate('albums');
    _startStream();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<SwrResult<Album>>(
      stream: _albumStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _LoadingView();
        }

        if (snapshot.hasError) {
          return const _ErrorView();
        }

        final albums = snapshot.data!.data;

        return Container(
          color: Colors.black,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: Colors.grey[900],
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const columns = 3;
                final totalSpacing = spacing * (columns - 1) + spacing * 2;
                final cellWidth = (constraints.maxWidth - totalSpacing) / columns;

                return GridView.builder(
                  padding: const EdgeInsets.all(spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: cellWidth + 6 + 13 + 11 + 8 + 5,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return AlbumCard(
                      album: album,
                      onTap: () => Navigator.push(
                        context,
                        PageSlideTransition(
                          child: ListScreen(
                            cover: AppCoverImage(
                              imageUrl: '${ApiService.baseUrl}/api/covers/${album.id}',
                              fallbackIcon: Icons.album,
                              fallbackIconSize: 80,
                            ),
                            title: album.title,
                            subtitle: album.artistName ?? 'Unknown Artist',
                            cacheKey: 'album_tracks_${album.id}',
                            fetcher: () => ApiService.getAlbumTracks(album.id),
                            playlistSort: false,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text('Błąd ładowania', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}