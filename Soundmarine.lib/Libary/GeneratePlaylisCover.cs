using Soundmarine.lib.Model;
using Soundmarine.lib.Repository;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace Soundmarine.lib.Library;

public class GeneratePlaylisCover
{
    private readonly string _connectionString;

    public GeneratePlaylisCover(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task GenerateCover(string playlistId)
    {
        TrackListRepository trackListRepository = new TrackListRepository(_connectionString);
        TrackRepository trackRepository = new TrackRepository(_connectionString);

        List<TrackList> trackList = await trackListRepository.GetTrackListById(playlistId);
        List<string> ids = new List<string>();
        string output = $"/covers/{playlistId}.webp";

        if (trackList.Count < 4)
        {
            Track track = await trackRepository.GetByTrackId(trackList[0].TrackId);
            File.Copy($"/covers/{track.AlbumId}.webp", output, true);
        }
        else if (trackList.Count == 4)
        {
            for (int i = 0; i < trackList.Count; i++)
            {
                Track track = await trackRepository.GetByTrackId(trackList[i].TrackId);
                ids.Add(track.AlbumId);
            }

            using Image<Rgba32> canvas = new(1000, 1000);

            Point[] positions =
            {
                new(0, 0),
                new(500, 0),
                new(0, 500),
                new(500, 500)
            };

            for (int i = 0; i < 4; i++)
            {
                using Image image = Image.Load($"/covers/{ids[i]}.webp");

                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Size = new Size(500, 500),
                    Mode = ResizeMode.Crop
                }));

                canvas.Mutate(x => x.DrawImage(image, positions[i], 1f));
            }

            canvas.SaveAsWebp(output);
        }
    }
}