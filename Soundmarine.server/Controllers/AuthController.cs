using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Soundmarine.lib.Model;
using Soundmarine.lib.Repository;
using BCrypt.Net;

namespace Soundmarine.server.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private static string JwtKey => Environment.GetEnvironmentVariable("JWT_KEY") ?? "SuperTajnyKluczDoJWTKtoryMusiBycDlugi123!";

    private readonly UserRepository _userRepository;

    public AuthController(UserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    // [HttpPost("register")]
    // public async Task<IActionResult> Register([FromBody] AuthRequest request)
    // {
    //     User? existing = await _userRepository.GetByUsername(request.Username);
    //     if (existing != null)
    //         return BadRequest("User already exists");
    //
    //     string hashedPassword = BCrypt.Net.BCrypt.HashPassword(request.Password);
    //     User user = new User(Guid.NewGuid().ToString(), request.Username, hashedPassword);
    //     await _userRepository.AddUser(user);
    //
    //     return Ok("Registered");
    // }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] AuthRequest request)
    {
        User? user = await _userRepository.GetByUsername(request.Username);
        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.Password))
            return Unauthorized("Invalid username or password");

        string token = GenerateToken(user);
        return Ok(new { token });
    }

    private string GenerateToken(User user)
    {
        JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();
        byte[] key = Encoding.UTF8.GetBytes(JwtKey);

        SecurityTokenDescriptor descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.Username),
            }),
            Expires = DateTime.UtcNow.AddDays(7),
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key),
                SecurityAlgorithms.HmacSha256Signature
            ),
        };

        SecurityToken token = handler.CreateToken(descriptor);
        return handler.WriteToken(token);
    }
}

public class AuthRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}