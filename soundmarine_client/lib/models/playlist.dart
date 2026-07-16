import '../services/api_service.dart';

class Playlist {
  final String id;
  final String ownerId;
  final String title;
  final String createdAt;
  final String playlistType;
  final String? coverUpdatedAt;

  Playlist({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
    required this.playlistType,
    this.coverUpdatedAt,
  });

  String get coverUrl =>
      '${ApiService.baseUrl}/api/covers/$id${coverUpdatedAt != null ? '?t=${Uri.encodeQueryComponent(coverUpdatedAt!)}' : ''}';

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      ownerId: json['ownerId'],
      title: json['title'],
      createdAt: json['createdAt'],
      playlistType: json['playlistType'],
      coverUpdatedAt: json['coverUpdatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'createdAt': createdAt,
    'playlistType': playlistType,
    if (coverUpdatedAt != null) 'coverUpdatedAt': coverUpdatedAt,
  };
}