using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Soundmarine.lib.Repository;
using Soundmarine.lib.Model;

namespace Soundmarine.server.Controllers;
[Authorize]
[ApiController]
[Route("api/artist")]
public class ArtistController : BaseController
{
    private readonly ArtistRepository _artistRepository;

    public ArtistController(ArtistRepository artistRepository)
    {
        _artistRepository = artistRepository;
    }

    // GET /api/albums/{id}/tracks
    [HttpGet("{id}")]
    public async Task<IActionResult> GetNameById(string id)
    {
        string artistName = await _artistRepository.GetNameById(id);

        if (artistName == null)
        {
            return NotFound($"No artist found with ID {id}");
        }

        return Ok(artistName);
    }
}