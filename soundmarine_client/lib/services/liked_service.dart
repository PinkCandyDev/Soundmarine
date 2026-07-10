import 'package:flutter/material.dart';
import 'api_service.dart';
import '../models/track_list.dart';

class LikedService {
  LikedService._();
  static final LikedService instance = LikedService._();

  Set<String> _likedTrackIds = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    try {
      List<TrackList> tracks = await ApiService.getLikedTracks();
      _likedTrackIds = tracks.map((TrackList t) => t.trackId).toSet();
      _loaded = true;
    } catch (e) {
      debugPrint('LikedService load error: $e');
    }
  }

  bool isLiked(String trackId) {
    return _likedTrackIds.contains(trackId);
  }

  Future<void> toggle(String trackId, VoidCallback onChanged) async {
    bool wasLiked = _likedTrackIds.contains(trackId);
    if (wasLiked) {
      _likedTrackIds.remove(trackId);
    } else {
      _likedTrackIds.add(trackId);
    }
    onChanged();

    try {
      if (wasLiked) {
        await ApiService.unlikeTrack(trackId);
      } else {
        await ApiService.likeTrack(trackId);
      }
    } catch (e) {
      // Rollback
      if (wasLiked) {
        _likedTrackIds.add(trackId);
      } else {
        _likedTrackIds.remove(trackId);
      }
      onChanged();
      debugPrint('LikedService toggle error: $e');
    }
  }

  void reload() {
    _loaded = false;
    load();
  }
} 