using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class TrackListRepository
{
    private readonly string _connectionString;

    public TrackListRepository(string connectionString)
    {
        _connectionString = connectionString;
    }
    
    public async Task<List<TrackList>> GetTrackListById(string playlistId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT playlistId, trackNumber, trackId, dateAdded FROM playlist_tracks WHERE playlistId = @playlistId", conn);
        cmd.Parameters.AddWithValue("playlistId", playlistId);

        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();
        List<TrackList> trackList = new List<TrackList>();
        while (await reader.ReadAsync())
        {
            trackList.Add(new TrackList(
                reader.GetString(0),
                reader.GetInt32(1),
                reader.GetString(2),
                reader.GetString(3)
            ));
        }
        return trackList;
    }
    
    public async Task AddTrackToPlaylist(string playlistId, string trackId, string dateAdded)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlTransaction transaction = await conn.BeginTransactionAsync();
        try
        {
            //I will move it later >_<
            await using NpgsqlCommand incrementCmd = new NpgsqlCommand(@"
            UPDATE playlists SET trackCount = trackCount + 1
            WHERE id = @playlistId
            RETURNING trackCount", conn, transaction);
            incrementCmd.Parameters.AddWithValue("@playlistId", playlistId);
            int newTrackNumber = (int)(await incrementCmd.ExecuteScalarAsync())!;

            await using NpgsqlCommand insertCmd = new NpgsqlCommand(@"
            INSERT INTO playlist_tracks (playlistId, trackNumber, trackId, dateAdded)
            VALUES (@playlistId, @trackNumber, @trackId, @dateAdded)
            ON CONFLICT (playlistId, trackId) DO NOTHING", conn, transaction);
            insertCmd.Parameters.AddWithValue("@playlistId", playlistId);
            insertCmd.Parameters.AddWithValue("@trackNumber", newTrackNumber);
            insertCmd.Parameters.AddWithValue("@trackId", trackId);
            insertCmd.Parameters.AddWithValue("@dateAdded", dateAdded);
            await insertCmd.ExecuteNonQueryAsync();

            await transaction.CommitAsync();
        }
        catch (Exception e)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
    
    public async Task RemoveTrackFromPlaylist(string playlistId, string trackId)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(@"
        DELETE FROM playlist_tracks
        WHERE playlistId = @playlistId AND trackId = @trackId", conn);
        cmd.Parameters.AddWithValue("@playlistId", playlistId);
        cmd.Parameters.AddWithValue("@trackId", trackId);
        await cmd.ExecuteNonQueryAsync();
    }
    
}