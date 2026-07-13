using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Soundmarine.lib.Repository;
using Soundmarine.lib.Model;

namespace Soundmarine.server.Controllers;
[Authorize]
[ApiController]
[Route("api/playlists")]
public class PlaylistList : BaseController
{
    private readonly PlaylistRepository _playlistRepository;
    private readonly TrackListRepository _trackListRepository;
    private readonly TrackRepository _trackRepository;
    private readonly ArtistRepository _artistRepository;

    public PlaylistList(
        PlaylistRepository playlistRepository,
        TrackListRepository trackListRepository,
        TrackRepository trackRepository,
        ArtistRepository artistRepository)
    {
        _playlistRepository = playlistRepository;
        _trackListRepository = trackListRepository;
        _trackRepository = trackRepository;
        _artistRepository = artistRepository;
    }

    // GET /api/playlists
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        string userId = GetUserId();
        List<Playlist> playlists = await _playlistRepository.GetPlaylistsByOwnerId(userId);
        return Ok(playlists);
    }
    
    [HttpGet("{id}/tracks")]
    public async Task<IActionResult> GetTracksByPlaylistId(string id)
    {
        string userId = GetUserId();
        bool owns = await _playlistRepository.DoesUserOwnPlaylist(userId, id);
        if (!owns)
            return Forbid();

        List<TrackDto> trackDtos = new List<TrackDto>();
        List<TrackList> trackLists = await _trackListRepository.GetTrackListById(id);
        foreach (TrackList trackList in trackLists)
        {
            Track track = await _trackRepository.GetByTrackId(trackList.TrackId);
            string? artistName = await _artistRepository.GetNameById(track.ArtistId);
            trackDtos.Add(new TrackDto(
                track.Id,
                track.Title,
                trackList.TrackNumber,
                track.AlbumId ?? null,
                track.ArtistId ?? null,
                artistName ?? null,
                track.Duration,
                trackList.DateAdded?? null
            ));
        }
        return Ok(trackDtos);
    }

    [HttpPost]
    public async Task<IActionResult> CreatePlaylist([FromBody] PlaylistCreateRequest createRequest)
    {
        string userId = GetUserId();
        DateTime now = DateTime.UtcNow;
        string formatted = now.ToString("o");
        await _playlistRepository.CreatePlaylist(new Playlist(Guid.NewGuid().ToString(), userId, createRequest.name, 0,formatted,
            "Playlist"));
        return Created();
    } 
    
    
    [HttpPost("{id}/track/{trackId}")]
    public async Task<IActionResult> AddToPlaylist(string id, string trackId)
    {
        string userId = GetUserId();
        if (await _playlistRepository.DoesUserOwnPlaylist(userId, id))
        {
            DateTime now = DateTime.UtcNow;
            string formatted = now.ToString("o");
            await _trackListRepository.AddTrackToPlaylist(id, trackId, formatted);
            return Ok();
        }
        return NotFound("Playlist not found");
    }

    [HttpDelete("{id}/track/{trackId}")]
    public async Task<IActionResult> RemoveFromPlaylist(string id, string trackId)
    {
        string userId = GetUserId();
        if (await _playlistRepository.DoesUserOwnPlaylist(userId, id))
        {
            await _trackListRepository.RemoveTrackFromPlaylist(id, trackId);
            return Ok();
        }
        return NotFound("Playlist not found");
    }
    
    public class PlaylistCreateRequest
    {
        public string name { get; set; } = string.Empty;
    }
}