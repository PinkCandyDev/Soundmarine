import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'api_service.dart';
import 'audio_proxy_server.dart';

class QueueTrack {
  final String trackId;
  final String title;
  final String? albumId;
  String? artistName;

  QueueTrack({required this.trackId, required this.title, required this.albumId, this.artistName});
}

class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();
  static final List<QueueTrack> _queue = [];
  static int _currentIndex = -1;

  static bool hasEverPlayed = false;
  static String? currentTrackTitle;
  static String? currentTrackId;
  static String? currentAlbumId;

  static AudioPlayer get player => _player;
  static List<QueueTrack> get queue => _queue;
  static int get currentIndex => _currentIndex;

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      _initialized = true;
      _player.currentIndexStream.listen((int? index) {
        if (index != null && index >= 0 && index < _queue.length) {
          _currentIndex = index;
          currentTrackId = _queue[index].trackId;
          currentTrackTitle = _queue[index].title;
          currentAlbumId = _queue[index].albumId;
        }
      });
    }
  }

  static AudioSource _buildSource(QueueTrack track) {
    return AudioSource.uri(
      Uri.parse(AudioProxyServer.instance.trackUrl(track.trackId)),
      tag: MediaItem(
        id: track.trackId,
        title: track.title,
        artist: track.artistName ?? 'Unknown Artist',
        artUri: Uri.parse('${ApiService.baseUrl}/api/covers/${track.albumId}'),
      ),
    );
  }

  static Future<void> setQueue(List<QueueTrack> tracks, int startIndex) async {
    await ensureInitialized();
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex;
    currentTrackTitle = _queue[startIndex].title;
    currentTrackId = _queue[startIndex].trackId;
    currentAlbumId = _queue[startIndex].albumId;

    final sources = tracks.map(_buildSource).toList();
    await _player.setAudioSources(sources, initialIndex: startIndex, preload: true);
    hasEverPlayed = true;
    await _player.play();
  }

  static Future<void> playTrack(String trackId, String title, String albumId) async {
    await setQueue(
      [QueueTrack(trackId: trackId, title: title, albumId: albumId)],
      0,
    );
  }

  static Future<void> addToQueue(QueueTrack track) async {
    _queue.add(track);
  }

  static Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex > index) _currentIndex--;
    }
  }

  static Future<void> skipToNext() async => await _player.seekToNext();
  static Future<void> skipToPrevious() async => await _player.seekToPrevious();

  static bool get hasNext => _player.hasNext;
  static bool get hasPrevious => _player.hasPrevious;

  static Future<void> pause() async => await _player.pause();
  static Future<void> resume() async => await _player.play();
  static Future<void> stop() async => await _player.stop();
}