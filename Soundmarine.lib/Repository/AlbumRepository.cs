using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class AlbumRepository
{
    private readonly string _connectionString;

    public AlbumRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task AddAlbum(Album album)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await using NpgsqlCommand cmd = new NpgsqlCommand(@"
            INSERT INTO albums (id,  title, artistId)
            VALUES (@id, @title, @artistId)
            ON CONFLICT (id) DO NOTHING", conn);

        cmd.Parameters.AddWithValue("id", album.Id);
        cmd.Parameters.AddWithValue("title", album.Title);
        cmd.Parameters.AddWithValue("artistId", album.ArtistId);

        await cmd.ExecuteNonQueryAsync();
    }
    
    public async Task<string?> GetIdByTitle(string title)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id FROM albums WHERE title = @title LIMIT 1", conn);
        cmd.Parameters.AddWithValue("title", title);

        object? result = await cmd.ExecuteScalarAsync();
        return result as string;
    }
    
    public async Task<List<Album>> GetAllAsync()
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id, title, artistId FROM albums", conn);
        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();

        List<Album> albums = new List<Album>();
        while (await reader.ReadAsync())
        {
            albums.Add(new Album(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2)
            ));
        }
        return albums;
    }
}