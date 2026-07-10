using TagLib.Id3v2;

namespace Soundmarine.lib.Model;

public class Playlist
{
    public string Id { get; set; }
    public string OwnerId { get; set; }
    public string Title { get; set; }
    public int TrackCount { get; set; }
    public string CreatedAt { get; set; }
    public string PlaylistType { get; set; }
    
    public Playlist(string id, string ownerId, string title, int trackCount, string createdAt, string playlistType)
    {
        Id = id;
        OwnerId = ownerId;
        Title = title;
        TrackCount = trackCount;
        CreatedAt = createdAt;
        PlaylistType = playlistType;
    }
}