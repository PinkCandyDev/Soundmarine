using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Soundmarine.lib.Repository;
using Soundmarine.lib.Model;

namespace Soundmarine.server.Controllers;
[Authorize]
[ApiController]
[Route("api/liked")]
public class LikedController : BaseController
{
    private readonly PlaylistRepository _playlistRepository;
    private readonly TrackListRepository _trackListRepository;

    public LikedController(PlaylistRepository playlistRepository, TrackListRepository trackListRepository)
    {
        _playlistRepository = playlistRepository;
        _trackListRepository = trackListRepository;
    }


    [HttpGet]
    public async Task<IActionResult> GetTracksByPlaylistId()
    {
        string userId = GetUserId();
        string? playlistId = await _playlistRepository.GetPlaylistIdByTypeAndOwner("Liked", userId);
        if (playlistId != null)
        {
            List<TrackList> trackLists = await _trackListRepository.GetTrackListById(playlistId);
            return Ok(trackLists);
        }

        return Forbid();
    }
    
    [HttpPost("{trackId}")]
    public async Task<IActionResult> LikeTrack(string trackId)
    {
        string userId = GetUserId();
        string? playlistId = await _playlistRepository.GetPlaylistIdByTypeAndOwner("Liked", userId);
        if (playlistId != null)
        {
            DateTime now = DateTime.UtcNow;
            string formatted = now.ToString("o");
            await _trackListRepository.AddTrackToPlaylist(playlistId, trackId, formatted);
            return Ok();
        }
        return NotFound("Liked playlist not found");
    }

    [HttpDelete("{trackId}")]
    public async Task<IActionResult> UnlikeTrack(string trackId)
    {
        string userId = GetUserId();
        string? playlistId = await _playlistRepository.GetPlaylistIdByTypeAndOwner("Liked", userId);
        if (playlistId != null)
        {
            await _trackListRepository.RemoveTrackFromPlaylist(playlistId, trackId);
            return Ok();
        }
        return NotFound("Liked playlist not found");
    }
}