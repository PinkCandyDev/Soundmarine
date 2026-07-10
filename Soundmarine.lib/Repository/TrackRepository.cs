using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class TrackRepository
{
    private readonly string _connectionString;

    public TrackRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task SaveAllAsync(List<Track> tracks)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        foreach (Track track in tracks)
        {
            await using NpgsqlCommand cmd = new NpgsqlCommand(@"
                INSERT INTO tracks (id, filepath, title, trackNumber, albumId, artistId, duration)
                VALUES (@id, @filepath, @title, @trackNumber, @albumId, @artistId, @duration)
                ON CONFLICT (id) DO NOTHING", conn);
            cmd.Parameters.AddWithValue("id", track.Id);
            cmd.Parameters.AddWithValue("filepath", track.Filepath);
            cmd.Parameters.AddWithValue("title", track.Title);
            cmd.Parameters.AddWithValue("trackNumber", track.TrackNumber);
            cmd.Parameters.AddWithValue("albumId", track.AlbumId ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("artistId", track.ArtistId ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("duration", track.Duration);

            await cmd.ExecuteNonQueryAsync();
        }
    }
    
    public async Task<string?> GetIdByFilepath(string filepath)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id FROM tracks WHERE filepath = @filepath LIMIT 1", conn);
        cmd.Parameters.AddWithValue("filepath", filepath);

        object? result = await cmd.ExecuteScalarAsync();
        return result as string;
    }

    public async Task<List<Track>> GetAllTracksByAlbumId(string albumId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id, filepath, title, trackNumber, albumId, artistId, duration FROM tracks WHERE albumId = @albumId", conn);
        cmd.Parameters.AddWithValue("albumId", albumId);

        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();
        List<Track> tracks = new List<Track>();
        while (await reader.ReadAsync())
        {
            tracks.Add(new Track
            (
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt32(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.GetInt32(6)
            ));
        }

        return tracks;
    }
    
    public async Task<Track> GetByTrackId(string id)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id, filepath, title, trackNumber, albumId, artistId, duration FROM tracks WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);

        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new Track(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt32(3),
                reader.IsDBNull(4) ? null : reader.GetString(4),
                reader.IsDBNull(5) ? null : reader.GetString(5),
                reader.GetInt32(6)
            );
        }

        return null;
    }
    
    public async Task<string?> GetFilepathById(string id)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT filepath FROM tracks WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);

        object? result = await cmd.ExecuteScalarAsync();
        return result as string;
    }
}