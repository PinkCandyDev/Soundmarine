namespace Soundmarine.lib.Model;

public class TrackDto
{
    public string Id { get; set; }
    public string Title { get; set; }
    public int TrackNumber { get; set; }
    public string? AlbumId { get; set; }
    public string? ArtistId { get; set; }
    public string? ArtistName { get; set; }
    public int Duration { get; set; }
    public string? DateAdded { get; set; }

    public TrackDto(string id, string title, int trackNumber, string? albumId, string? artistId, string? artistName, int duration, string? dateAdded)
    {
        Id = id;
        Title = title;
        TrackNumber = trackNumber;
        AlbumId = albumId;
        ArtistId = artistId;
        ArtistName = artistName;
        Duration = duration;
        DateAdded = dateAdded;
    }
}