class TrackList {
  final String playlistId;
  final int trackNumber;
  final String trackId;
  final String dateAdded;

  TrackList({
    required this.playlistId,
    required this.trackNumber,
    required this.trackId,
    required this.dateAdded,
  });

  factory TrackList.fromJson(Map<String, dynamic> json) {
    return TrackList(
      playlistId: json['playlistId'],
      trackNumber: json['trackNumber'],
      trackId: json['trackId'],
      dateAdded: json['dateAdded'],
    );
  }
}