using TagLib.Id3v2;

namespace Soundmarine.lib.Model;

public class TrackList
{
    public string PlaylistId { get; set; }
    public int TrackNumber { get; set; }
    public string TrackId { get; set; }
    public string DateAdded { get; set; }

    public TrackList(string playlistId, int trackNumber, string trackId, string dateAdded)
    {
        PlaylistId = playlistId;
        TrackNumber = trackNumber;
        TrackId = trackId;
        DateAdded = dateAdded;
    }
}