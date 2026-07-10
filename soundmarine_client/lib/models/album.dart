class Album {
  final String id;
  final String title;
  final String? artistId;
  final String? artistName;

  Album({required this.id, required this.title, this.artistId, this.artistName});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['title'],
      artistId: json['artistId'],
      artistName: json['artistName'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistId': artistId,
    'artistName': artistName,
  };
}