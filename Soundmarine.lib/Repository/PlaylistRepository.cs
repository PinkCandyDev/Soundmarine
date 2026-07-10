using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class PlaylistRepository
{
    private readonly string _connectionString;

    public PlaylistRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task CreatePlaylist(Playlist playlist)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(@"
            INSERT INTO playlists (id, ownerId, title, trackCount, createdAt, playlistType)
            VALUES (@id, @ownerId, @title, @trackCount, @createdAt, @playlistType)
            ON CONFLICT (id) DO NOTHING", conn);

        cmd.Parameters.AddWithValue("id", playlist.Id);
        cmd.Parameters.AddWithValue("ownerId", playlist.OwnerId);
        cmd.Parameters.AddWithValue("title", playlist.Title);
        cmd.Parameters.AddWithValue("trackCount", playlist.TrackCount);
        cmd.Parameters.AddWithValue("createdAt", playlist.CreatedAt);
        cmd.Parameters.AddWithValue("playlistType", playlist.PlaylistType);
        await cmd.ExecuteNonQueryAsync();
    }
    
    public async Task<List<Playlist>> GetPlaylistsByOwnerId(string ownerId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id, ownerId, title, trackCount, createdAt, playlistType FROM playlists WHERE ownerId = @ownerId", conn);
        cmd.Parameters.AddWithValue("ownerId", ownerId);

        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();
        List<Playlist> playlists = new List<Playlist>();
        while (await reader.ReadAsync())
        {
            playlists.Add(new Playlist(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt32(3),
                reader.GetString(4),
                reader.GetString(5)
            ));
        }
        return playlists;
    }

    public async Task<bool> DoesUserOwnPlaylist(string ownerId, string playlistId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT EXISTS(SELECT 1 FROM playlists WHERE ownerId = @ownerId AND id = @playlistId)",
            conn);

        cmd.Parameters.AddWithValue("ownerId", ownerId);
        cmd.Parameters.AddWithValue("playlistId", playlistId);

        object? result = await cmd.ExecuteScalarAsync();

        return result != null && (bool)result;
    }
    
    public async Task<string?> GetPlaylistIdByTypeAndOwner(string playlistType, string userId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id FROM playlists WHERE playlistType = @playlistType AND ownerId = @userId LIMIT 1",
            conn);

        cmd.Parameters.AddWithValue("playlistType", playlistType);
        cmd.Parameters.AddWithValue("userId", userId);

        object? result = await cmd.ExecuteScalarAsync();

        return result?.ToString();
    }
    
    
    
}