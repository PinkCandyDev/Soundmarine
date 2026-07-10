using Npgsql;
namespace Soundmarine.lib.Database;

public class DatabaseInitializer
{
    private readonly string _connectionString;

    public DatabaseInitializer(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task InitializeAsync()
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand tracksTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS tracks (
                id VARCHAR PRIMARY KEY,
                filepath VARCHAR NOT NULL,
                title VARCHAR NOT NULL,
                trackNumber INT NOT NULL,
                albumId VARCHAR,
                artistId VARCHAR,
                duration INT NOT NULL
            )", conn);
        await tracksTable.ExecuteNonQueryAsync();

        await using NpgsqlCommand albumsTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS albums (
                id VARCHAR PRIMARY KEY,
                title VARCHAR NOT NULL,
                artistId VARCHAR
            )", conn);
        await albumsTable.ExecuteNonQueryAsync();

        await using NpgsqlCommand artistsTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS artists (
                id VARCHAR PRIMARY KEY,
                artistName VARCHAR NOT NULL
            )", conn);
        await artistsTable.ExecuteNonQueryAsync();
        
        await using NpgsqlCommand usersTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS users (
                id VARCHAR PRIMARY KEY,
                username VARCHAR NOT NULL UNIQUE,
                password VARCHAR NOT NULL
            )", conn);
        await usersTable.ExecuteNonQueryAsync();
        
        await using NpgsqlCommand playlistsTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS playlists (
                id VARCHAR PRIMARY KEY,
                ownerId VARCHAR NOT NULL,
                title VARCHAR NOT NULL,
                trackCount INT NOT NULL,
                createdAt VARCHAR NOT NULL,
                playlistType VARCHAR NOT NULL
            )", conn);
        await playlistsTable.ExecuteNonQueryAsync();
        
        await using NpgsqlCommand playlists_tracksTable = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS playlist_tracks (
                playlistId VARCHAR NOT NULL,
                trackId VARCHAR NOT NULL,
                trackNumber INT NOT NULL,
                dateAdded VARCHAR NOT NULL,
                PRIMARY KEY (playlistId, trackId)
            )", conn);

        await playlists_tracksTable.ExecuteNonQueryAsync();
    }
}