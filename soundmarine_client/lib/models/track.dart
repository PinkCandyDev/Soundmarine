class Track {
  final String id;
  final String title;
  final int trackNumber;
  final String? albumId;
  final String? artistId;
  final String artistName;
  final int duration;
  final String? dateAdded;

  Track({
    required this.id,
    required this.title,
    required this.trackNumber,
    this.albumId,
    this.artistId,
    required this.artistName,
    required this.duration,
    this.dateAdded,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      trackNumber: json['trackNumber'],
      albumId: json['albumId'],
      artistId: json['artistId'],
      artistName: json['artistName'],
      duration: json['duration'],
      dateAdded: json['dateAdded'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'trackNumber': trackNumber,
    'albumId': albumId,
    'artistId': artistId,
    'artistName': artistName,
    'duration': duration,
    'dateAdded': dateAdded,
  };
}