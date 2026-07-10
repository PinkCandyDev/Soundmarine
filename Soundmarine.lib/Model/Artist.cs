namespace Soundmarine.lib.Model;

public class Artist
{
    public string Id { get; set; }
    public string ArtistName { get; set; }

    public Artist(string id, string artistName)
    {
        Id = id;
        ArtistName = artistName;
    }
}