namespace Soundmarine.lib.Model;

public class User
{
    public string Id { get; set; }
    public string Username { get; set; }
    public string Password { get; set; }

    public User(string id, string username, string password)
    {
        Id = id;
        Username = username;
        Password = password;
    }
}