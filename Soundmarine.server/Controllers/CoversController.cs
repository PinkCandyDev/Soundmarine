using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Soundmarine.server.Controllers;

[Authorize]
[ApiController]
[Route("api/covers")]
public class CoversController : BaseController
{
    [HttpGet("{albumId}")]
    public IActionResult GetCover(string albumId)
    {
        string path = $"/covers/{albumId}.webp";
        if (!System.IO.File.Exists(path))
            return NotFound();

        return PhysicalFile(path, "image/webp");
    }
}