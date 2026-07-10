namespace Soundmarine.lib.Model;

public class AlbumDto
{
    public string Id { get; set; }
    public string Title { get; set; }
    public string ArtistId { get; set; }
    public string? ArtistName { get; set; }

    public AlbumDto(string id, string title, string artistId, string artistName)
    {
        Id = id;
        Title = title;
        ArtistId = artistId;
        ArtistName = artistName;
    }
}