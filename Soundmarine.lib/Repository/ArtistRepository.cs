using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class ArtistRepository
{
    private readonly string _connectionString;

    public ArtistRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task AddArtist(Artist artist)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(@"
            INSERT INTO artists (id, artistName)
            VALUES (@id, @artistName)
            ON CONFLICT (id) DO NOTHING", conn);

        cmd.Parameters.AddWithValue("id",  artist.Id);
        cmd.Parameters.AddWithValue("artistName", artist.ArtistName);

        await cmd.ExecuteNonQueryAsync();
    }
    
    public async Task<string?> GetIdByTitle(string artistName)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id FROM artists WHERE artistName = @artistName LIMIT 1", conn);
        cmd.Parameters.AddWithValue("artistName", artistName);

        object? result = await cmd.ExecuteScalarAsync();
        return result as string;
    }
    public async Task<string?> GetNameById(string id)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT artistName FROM artists WHERE id = @id LIMIT 1", conn);
        cmd.Parameters.AddWithValue("id", id);

        object? result = await cmd.ExecuteScalarAsync();
        return result as string;
    }
}