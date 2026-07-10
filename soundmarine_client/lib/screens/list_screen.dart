import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../services/swr_service.dart';
import '../widgets/action_buttons_row.dart';
import '../widgets/collection_header.dart';
import '../widgets/track/track_list.dart';
import '../widgets/track/track_list_skeleton.dart';

/// A unified screen that renders a list of tracks for an album or playlist.
class ListScreen extends StatefulWidget {
  final Widget cover;
  final String title;
  final String subtitle;
  final String cacheKey;
  final Future<List<Track>> Function() fetcher;
  final bool playlistSort;

  const ListScreen({
    super.key,
    required this.cover,
    required this.title,
    required this.subtitle,
    required this.cacheKey,
    required this.fetcher,
    this.playlistSort = false,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String? _token;
  Stream<SwrResult<Track>>? _trackStream;

  @override
  void initState() {
    super.initState();
    _loadToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _trackStream = SwrService.fetchList<Track>(
            cacheKey: widget.cacheKey,
            fetcher: widget.fetcher,
            toJson: (Track t) => t.toJson(),
            fromJson: Track.fromJson,
          );
        });
      });
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _token = prefs.getString('token'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StreamBuilder<SwrResult<Track>>(
            stream: _trackStream,
            builder: (context, snapshot) {
              final loading = !snapshot.hasData;
              final tracks = snapshot.data?.data ?? [];

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: CollectionHeader(
                      cover: widget.cover,
                      title: widget.title,
                      subtitle: widget.subtitle,
                      bottomSection: const ActionButtonsRow(),
                    ),
                  ),
                  if (loading)
                    const TrackListSkeleton()
                  else
                    TrackList(
                      tracks: tracks,
                      playlist: widget.playlistSort,
                      token: _token,
                      isOffline: snapshot.data?.isOffline ?? false,
                    ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.blue),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
