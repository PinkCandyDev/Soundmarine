using Npgsql;
using Soundmarine.lib.Model;

namespace Soundmarine.lib.Repository;

public class UserRepository
{
    private readonly string _connectionString;

    public UserRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task AddUser(User user)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(@"
            INSERT INTO users (id, username, password)
            VALUES (@id, @username, @password)", conn);

        cmd.Parameters.AddWithValue("id", user.Id);
        cmd.Parameters.AddWithValue("username", user.Username);
        cmd.Parameters.AddWithValue("password", user.Password);

        await cmd.ExecuteNonQueryAsync();
    }

    public async Task<User?> GetByUsername(string username)
    {
        await using NpgsqlConnection conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();

        await using NpgsqlCommand cmd = new NpgsqlCommand(
            "SELECT id, username, password FROM users WHERE username = @username", conn);
        cmd.Parameters.AddWithValue("username", username);

        await using NpgsqlDataReader reader = await cmd.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new User(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2)
            );
        }
        return null;
    }
}