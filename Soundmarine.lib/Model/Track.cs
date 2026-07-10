namespace Soundmarine.lib.Model;

public class Track
{
    public string Id { get; set; }
    public string Filepath { get; set; }
    public string Title { get; set; }
    public int TrackNumber { get; set; }
    public string? AlbumId { get; set; }
    public string? ArtistId { get; set; }
    public int Duration { get; set; }

    public Track(string id,string filepath, string title, int trackNumber, string? albumId, string? artistId, int duration)
    {
        Id = id;
        Filepath = filepath;
        Title = title;
        TrackNumber = trackNumber;
        AlbumId = albumId;
        ArtistId = artistId;
        Duration = duration;
    }
}