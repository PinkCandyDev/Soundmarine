import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class CacheEntry {
  final String trackId;
  final String quality;
  final String filePath;
  final int fileSizeBytes;
  final String contentType;
  final DateTime cachedAt;
  final DateTime lastPlayedAt;

  CacheEntry({
    required this.trackId,
    required this.quality,
    required this.filePath,
    required this.fileSizeBytes,
    required this.contentType,
    required this.cachedAt,
    required this.lastPlayedAt,
  });

  CacheEntry copyWith({DateTime? lastPlayedAt}) => CacheEntry(
    trackId: trackId,
    quality: quality,
    filePath: filePath,
    fileSizeBytes: fileSizeBytes,
    contentType: contentType,
    cachedAt: cachedAt,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
  );

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'quality': quality,
    'filePath': filePath,
    'fileSizeBytes': fileSizeBytes,
    'contentType': contentType,
    'cachedAt': cachedAt.toIso8601String(),
    'lastPlayedAt': lastPlayedAt.toIso8601String(),
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    trackId: json['trackId'],
    quality: json['quality'] ?? 'unknown',
    filePath: json['filePath'],
    fileSizeBytes: json['fileSizeBytes'],
    contentType: json['contentType'] ?? 'audio/mpeg',
    cachedAt: DateTime.parse(json['cachedAt']),
    lastPlayedAt: DateTime.parse(json['lastPlayedAt']),
  );
}

class AudioProxyServer {
  static const int _port = 8888;
  static const int port = 8888;
  static const String _metaKey = 'proxy_cache_meta';
  static const String _limitBytesKey = 'proxy_cache_limit_bytes';
  static const String _replaceOldestKey = 'proxy_cache_replace_oldest';
  static const String _qualityKey = 'qualityMode';
  static const String _defaultQuality = '320';
  static const int _defaultLimitBytes = 20 * 1024 * 1024 * 1024;

  static AudioProxyServer? _instance;
  static AudioProxyServer get instance {
    _instance ??= AudioProxyServer._();
    return _instance!;
  }
  AudioProxyServer._();

  HttpServer? _server;
  SharedPreferences? _prefs;
  Map<String, CacheEntry> _entries = {};
  String? _cacheDir;
  bool _replaceOldest = true;

  bool get isRunning => _server != null;

  String get currentQuality => _prefs?.getString(_qualityKey) ?? _defaultQuality;
  
  String trackUrl(String trackId) {
    return 'http://localhost:$_port/track/$trackId?quality=$currentQuality';
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _replaceOldest = _prefs?.getBool(_replaceOldestKey) ?? true;
    await _loadMetadata();
    await _initCacheDir();
    await _startServer();
  }

  Future<void> _initCacheDir() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    _cacheDir = '${dir.path}/audio_cache';
    final Directory cacheDir = Directory(_cacheDir!);
    if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
  }

  Future<void> _startServer() async {
    final Router router = Router();

    router.get('/track/<trackId>', (Request request, String trackId) async {
      final String requestedQuality = request.url.queryParameters['quality'] ?? currentQuality;
      return await _handleTrackRequest(request, trackId, requestedQuality);
    });

    router.get('/cover/<albumId>', (Request request, String albumId) async {
      final http.Response response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/covers/$albumId'),
        headers: {'Authorization': 'Bearer ${ApiService.token}'},
      );
      return Response(
        response.statusCode,
        body: response.bodyBytes,
        headers: {
          'Content-Type': response.headers['content-type'] ?? 'image/jpeg',
        },
      );
    });

    final Handler handler = const Pipeline().addHandler(router.call);
    _server = await shelf_io.serve(handler, 'localhost', _port);
  }

  Future<Response> _handleTrackRequest(Request request, String trackId, String requestedQuality) async {
    final CacheEntry? cached = _getCachedEntry(trackId);

    if (cached != null) {
      await _updateLastPlayed(trackId);
      return await _serveFile(request, cached);
    }
    
    return await _streamAndCache(request, trackId, requestedQuality);
  }

  Future<Response> _serveFile(Request request, CacheEntry entry) async {
    final File file = File(entry.filePath);
    final int fileSize = file.lengthSync();
    final String? rangeHeader = request.headers['range'];

    if (rangeHeader != null) {
      final RegExp rangeRegex = RegExp(r'bytes=(\d*)-(\d*)');
      final RegExpMatch? match = rangeRegex.firstMatch(rangeHeader);

      if (match != null) {
        final int start = match.group(1)!.isEmpty ? 0 : int.parse(match.group(1)!);
        final int end = match.group(2)!.isEmpty ? fileSize - 1 : int.parse(match.group(2)!);
        final int length = end - start + 1;

        return Response(
          206,
          body: file.openRead(start, end + 1),
          headers: {
            'Content-Type': entry.contentType,
            'Content-Length': length.toString(),
            'Content-Range': 'bytes $start-$end/$fileSize',
            'Accept-Ranges': 'bytes',
          },
        );
      }
    }

    return Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': entry.contentType,
        'Content-Length': fileSize.toString(),
        'Accept-Ranges': 'bytes',
      },
    );
  }

  Future<Response> _streamAndCache(Request request, String trackId, String quality) async {
    final String apiUrl = '${ApiService.baseUrl}/api/tracks/$trackId/stream?quality=$quality';
    final String filePath = '$_cacheDir/$trackId.cache';

    final http.StreamedResponse apiResponse = await http.Client().send(
      http.Request('GET', Uri.parse(apiUrl))
        ..headers['Authorization'] = 'Bearer ${ApiService.token}',
    );

    if (apiResponse.statusCode != 200) {
      return Response(apiResponse.statusCode, body: 'API error');
    }

    final String contentType = apiResponse.headers['content-type'] ?? 'audio/mpeg';
    final int? contentLength = apiResponse.contentLength;

    if (contentLength != null) {
      await _enforceLimit(contentLength);
    }

    final File file = File(filePath);
    final IOSink fileSink = file.openWrite();
    int bytesWritten = 0;

    final StreamController<List<int>> controller = StreamController<List<int>>();

    apiResponse.stream.listen(
          (List<int> chunk) {
        fileSink.add(chunk);
        bytesWritten += chunk.length;
        controller.add(chunk);
      },
      onDone: () async {
        await fileSink.close();
        await controller.close();
        if (bytesWritten > 0) {
          _entries[trackId] = CacheEntry(
            trackId: trackId,
            quality: quality,
            filePath: filePath,
            fileSizeBytes: bytesWritten,
            contentType: contentType,
            cachedAt: DateTime.now(),
            lastPlayedAt: DateTime.now(),
          );
          await _saveMetadata();
        }
      },
      onError: (Object error) async {
        await fileSink.close();
        await controller.close();
        if (file.existsSync()) file.deleteSync();
      },
      cancelOnError: true,
    );

    final Map<String, String> headers = {
      'Content-Type': contentType,
      'Accept-Ranges': 'bytes',
    };

    if (contentLength != null) {
      headers['Content-Length'] = contentLength.toString();
    }

    return Response.ok(controller.stream, headers: headers);
  }
  
  bool isCached(String trackId) {
    final CacheEntry? entry = _entries[trackId];
    if (entry == null) return false;
    return File(entry.filePath).existsSync();
  }

  CacheEntry? _getCachedEntry(String trackId) {
    final CacheEntry? entry = _entries[trackId];
    if (entry == null) return null;
    if (!File(entry.filePath).existsSync()) return null;
    return entry;
  }

  int getTotalCacheSize() {
    return _entries.values.fold(0, (int sum, CacheEntry e) => sum + e.fileSizeBytes);
  }

  double getTotalCacheSizeGb() {
    return getTotalCacheSize() / (1024 * 1024 * 1024);
  }

  List<CacheEntry> getAllEntries() {
    return _entries.values.toList();
  }

  Future<int> getCacheLimit() async {
    return _prefs?.getInt(_limitBytesKey) ?? _defaultLimitBytes;
  }

  Future<void> setCacheLimit(int bytes) async {
    await _prefs?.setInt(_limitBytesKey, bytes);
  }

  Future<void> setCacheLimitGb(double gb) async {
    await setCacheLimit((gb * 1024 * 1024 * 1024).round());
  }

  Future<void> setReplaceOldest(bool value) async {
    _replaceOldest = value;
    await _prefs?.setBool(_replaceOldestKey, value);
  }

  Future<void> _enforceLimit(int incomingBytes) async {
    if (!_replaceOldest) return;
    final int limit = await getCacheLimit();
    int total = getTotalCacheSize() + incomingBytes;
    if (total <= limit) return;

    final List<CacheEntry> sorted = _entries.values.toList()
      ..sort((CacheEntry a, CacheEntry b) => a.lastPlayedAt.compareTo(b.lastPlayedAt));

    for (final CacheEntry entry in sorted) {
      if (total <= limit) break;
      await _deleteEntry(entry.trackId);
      total -= entry.fileSizeBytes;
    }
  }

  Future<void> _deleteEntry(String trackId) async {
    final CacheEntry? entry = _entries[trackId];
    if (entry == null) return;
    final File file = File(entry.filePath);
    if (file.existsSync()) file.deleteSync();
    _entries.remove(trackId);
    await _saveMetadata();
  }

  Future<void> deleteTrack(String trackId) => _deleteEntry(trackId);

  Future<void> clearAll() async {
    for (final String trackId in _entries.keys.toList()) {
      await _deleteEntry(trackId);
    }
  }

  Future<void> _updateLastPlayed(String trackId) async {
    final CacheEntry? entry = _entries[trackId];
    if (entry == null) return;
    _entries[trackId] = entry.copyWith(lastPlayedAt: DateTime.now());
    await _saveMetadata();
  }

  Future<void> _loadMetadata() async {
    final String? raw = _prefs?.getString(_metaKey);
    if (raw == null) return;
    final List<dynamic> list = jsonDecode(raw);
    _entries = {
      for (final dynamic e in list)
        e['trackId']: CacheEntry.fromJson(e as Map<String, dynamic>)
    };
  }

  Future<void> _saveMetadata() async {
    await _prefs?.setString(
      _metaKey,
      jsonEncode(_entries.values.map((CacheEntry e) => e.toJson()).toList()),
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}