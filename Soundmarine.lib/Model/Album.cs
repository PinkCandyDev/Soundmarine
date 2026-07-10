namespace Soundmarine.lib.Model;

public class Album
{
    public string Id { get; set; }
    public string Title { get; set; }
    public string ArtistId { get; set; }

    public Album(string id, string title, string artistId)
    {
        Id = id;
        Title = title;
        ArtistId = artistId;
    }
}