using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Soundmarine.server.Controllers;

[Authorize]
[ApiController]
[Route("api/covers")]
public class CoversController : BaseController 
{
    [HttpGet("{coverId}")]
    public IActionResult GetCover(string coverId)
    {
        string path = $"/covers/{coverId}.webp";
        if (!System.IO.File.Exists(path))
            return NotFound();

        return PhysicalFile(path, "image/webp");
    }
}