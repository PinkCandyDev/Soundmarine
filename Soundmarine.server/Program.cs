using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using AspNetCoreRateLimit;
using DotNetEnv;
using Soundmarine.lib.Database;
using Soundmarine.lib.Library;
using Soundmarine.lib.Model;
using Soundmarine.lib.Repository;

namespace Soundmarine.server;

public class Program
{
    public static string ConnectionString;
    private static string JwtKey;

    public static async Task Main(string[] args)
    {
        Env.Load();
        
        string host = "soundmarine-postgress";
        string db = Environment.GetEnvironmentVariable("POSTGRES_DB");
        string dbuser = Environment.GetEnvironmentVariable("POSTGRES_USER");
        string pass = Environment.GetEnvironmentVariable("POSTGRES_PASSWORD");
        
        String defuser= Environment.GetEnvironmentVariable("DEF_USER");
        String defpass = Environment.GetEnvironmentVariable("DEF_PASS");
        
        ConnectionString = "Host=" + host + ";Database=" + db + ";Username=" + dbuser + ";Password=" + pass;
        
        JwtKey = Environment.GetEnvironmentVariable("JWT_KEY");
        
        WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
        builder.Services.AddControllers();

        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JwtKey)),
                    ValidateIssuer = false,
                    ValidateAudience = false,
                };
            });

        builder.Services.AddAuthorization();
        builder.Services.AddMemoryCache();
        
        builder.Services.Configure<IpRateLimitOptions>(options =>
        {
            options.GeneralRules = new List<RateLimitRule>
            {
                new RateLimitRule
                {
                    Endpoint = "POST:/api/auth/login",
                    Limit = 5,
                    Period = "1m"
                }
            };
        });
        builder.Services.AddInMemoryRateLimiting();
        builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();
        
        builder.Services.AddScoped<TrackRepository>(_ => new TrackRepository(ConnectionString));
        builder.Services.AddScoped<AlbumRepository>(_ => new AlbumRepository(ConnectionString));
        builder.Services.AddScoped<PlaylistRepository>(_ => new PlaylistRepository(ConnectionString));
        builder.Services.AddScoped<TrackListRepository>(_ => new TrackListRepository(ConnectionString));
        builder.Services.AddScoped<ArtistRepository>(_ => new ArtistRepository(ConnectionString));
        builder.Services.AddScoped<UserRepository>(_ => new UserRepository(ConnectionString));
        
        WebApplication app = builder.Build();
        app.Urls.Add("http://*:3230");
        app.UseIpRateLimiting();
        app.UseAuthentication();
        app.UseAuthorization();
        app.MapControllers();

        DatabaseInitializer initializer = new DatabaseInitializer(ConnectionString);
        await initializer.InitializeAsync();
        Console.WriteLine("Db ready");
        
        RescanLib rescanLib = new RescanLib(ConnectionString);
        List<Track> tracks = await rescanLib.ScanMusicAsync();
        TrackRepository repo = new TrackRepository(ConnectionString);
        await repo.SaveAllAsync(tracks);
        Console.WriteLine($"Saved {tracks.Count} tracks");
        
        UserRepository userRepo = new UserRepository(ConnectionString);
        PlaylistRepository playlistRepo = new PlaylistRepository(ConnectionString);
        User? existing = await userRepo.GetByUsername(defuser);
        if (existing == null)
        {
            string hashed = BCrypt.Net.BCrypt.HashPassword(defpass);
            await userRepo.AddUser(new User(Guid.NewGuid().ToString(), defuser, hashed));
            User user = await userRepo.GetByUsername(defuser);
            string userId = user.Id;
            DateTime now = DateTime.UtcNow;
            string formatted = now.ToString("o");
            await playlistRepo.CreatePlaylist(new Playlist(Guid.NewGuid().ToString(), userId, "Liked", 0,formatted,
                "Liked", false));
            Console.WriteLine("Default user saved");
        }

        await app.RunAsync();
    }
}