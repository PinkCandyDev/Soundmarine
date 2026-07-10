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
}