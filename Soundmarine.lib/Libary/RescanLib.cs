using Soundmarine.lib.Model;
using Soundmarine.lib.Repository;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.Formats.Webp;

namespace Soundmarine.lib.Library;

public class RescanLib
{
    private readonly string _connectionString;

    public RescanLib(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<List<Track>> ScanMusicAsync()
    {
        List<Track> tracks = new List<Track>();
        ArtistRepository artistRepository = new ArtistRepository(_connectionString);
        AlbumRepository albumRepository = new AlbumRepository(_connectionString);
        TrackRepository trackRepository = new TrackRepository(_connectionString);

        try
        {
            Directory.CreateDirectory("/covers/");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: Cannot create covers directory: {ex.Message}");
        }

        int successCount = 0;
        int errorCount = 0;

        foreach (string path in Directory.GetFiles("/music", "*.*", SearchOption.AllDirectories)
                     .Where(p => p.EndsWith(".mp3") || p.EndsWith(".flac") || p.EndsWith(".wav") || p.EndsWith(".ogg") || p.EndsWith(".m4a")))
        {
            try
            {
                string filePath = path.Replace("/music", "").Replace("\\", "/");
                string? existingId = await trackRepository.GetIdByFilepath(filePath);
                if (existingId != null)
                {
                    continue;
                }
                
                TagLib.File file = TagLib.File.Create(path);
                string artistName = file.Tag.FirstPerformer ?? "Unknown Artist";
                string? artistId = await artistRepository.GetIdByTitle(artistName);
                if (artistId == null)
                {
                    Artist artist = new Artist(Guid.NewGuid().ToString(), artistName);
                    await artistRepository.AddArtist(artist);
                    artistId = artist.Id;
                }
                
                string albumName = file.Tag.Album ?? "Unknown Album";
                string? albumId = await albumRepository.GetIdByTitle(albumName);
                if (albumId == null)
                {
                    Album album = new Album(Guid.NewGuid().ToString(), albumName, artistId);
                    await albumRepository.AddAlbum(album);
                    albumId = album.Id;
                }

                // Handle cover image - wrapped in try-catch so it doesn't skip track
                try
                {
                    if (!File.Exists($"/covers/{albumId}.webp"))
                    {
                        string? folder = Path.GetDirectoryName(path);
                        if (!string.IsNullOrEmpty(folder))
                        {
                            string? coverPath = null;
                            try
                            {
                                coverPath = Directory.GetFiles(folder, "cover.jpg").FirstOrDefault() ?? 
                                           Directory.GetFiles(folder, "cover.png").FirstOrDefault();
                            }
                            catch
                            {
                                
                            }

                            byte[]? imageData = null;
                            if (coverPath != null)
                            {
                                imageData = File.ReadAllBytes(coverPath);
                            }
                            else if (file.Tag.Pictures.Length > 0)
                            {
                                imageData = file.Tag.Pictures[0].Data.Data;
                            }

                            
                            if (imageData != null)
                            {
                                using Image image = Image.Load(imageData);

                                image.Mutate(x => x.Resize(new ResizeOptions
                                {
                                    Size = new Size(1000, 1000),
                                    Mode = ResizeMode.Crop,
                                    Position = AnchorPositionMode.Center
                                }));

                                await image.SaveAsWebpAsync($"/covers/{albumId}.webp");
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Warning: Could not extract cover for album {albumId}: {ex.Message}");
                }

                tracks.Add(new Track(
                    Guid.NewGuid().ToString(),
                    path.Replace("/music", "").Replace("\\", "/"),
                    file.Tag.Title ?? Path.GetFileNameWithoutExtension(path),
                    (int)file.Tag.Track,
                    albumId,
                    artistId,
                    (int)file.Properties.Duration.TotalSeconds
                ));
                
                successCount++;
            }
            catch (Exception ex)
            {
                errorCount++;
                Console.WriteLine($"Error processing file {path}: {ex.Message}");
            }
        }
        
        Console.WriteLine($"Scanned successfully: {successCount}, Errors: {errorCount}");
        return tracks;
    }
}