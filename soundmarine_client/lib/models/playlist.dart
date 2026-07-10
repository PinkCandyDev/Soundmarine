class Playlist {
  final String id;
  final String ownerId;
  final String title;
  final String createdAt;
  final String playlistType;

  Playlist({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.createdAt,
    required this.playlistType,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      ownerId: json['ownerId'],
      title: json['title'],
      createdAt: json['createdAt'],
      playlistType: json['playlistType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'createdAt': createdAt,
    'playlistType': playlistType,
  };
}