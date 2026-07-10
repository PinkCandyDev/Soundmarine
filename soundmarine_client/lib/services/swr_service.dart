import 'cache_service.dart';

class SwrResult<T> {
  final List<T> data;
  final bool isFromCache;
  final bool isUpdated;
  final bool isOffline;

  SwrResult({
    required this.data,
    required this.isFromCache,
    this.isUpdated = false,
    this.isOffline = false,
  });
}

class SwrService {
  static Stream<SwrResult<T>> fetchList<T>({
    required String cacheKey,
    required Future<List<T>> Function() fetcher,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
  }) async* {
    final List<Map<String, dynamic>>? cached = await CacheService.getList(cacheKey);

    if (cached != null) {
      yield SwrResult(
        data: cached.map(fromJson).toList(),
        isFromCache: true,
      );
    }

    try {
      final List<T> freshData = await fetcher();
      final List<Map<String, dynamic>> freshJson = freshData.map(toJson).toList();
      final List<Map<String, dynamic>>? cachedJson = await CacheService.getList(cacheKey);

      final bool changed = _isChanged(freshJson, cachedJson);

      if (changed) {
        await CacheService.setList(cacheKey, freshJson);
      }

      yield SwrResult(
        data: freshData,
        isFromCache: false,
        isUpdated: changed,
      );
    } catch (e) {
      if (cached == null) rethrow;
      yield SwrResult(
        data: cached.map(fromJson).toList(),
        isFromCache: true,
        isOffline: true,
      );
    }
  }

  static bool _isChanged(
      List<Map<String, dynamic>> fresh,
      List<Map<String, dynamic>>? cached,
      ) {
    if (cached == null) return true;
    if (fresh.length != cached.length) return true;

    for (int i = 0; i < fresh.length; i++) {
      if (fresh[i].toString() != cached[i].toString()) return true;
    }

    return false;
  }
}