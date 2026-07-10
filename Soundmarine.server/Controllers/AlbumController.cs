using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Soundmarine.lib.Repository;
using Soundmarine.lib.Model;

namespace Soundmarine.server.Controllers;
[Authorize]
[ApiController]
[Route("api/albums")]
public class AlbumController : BaseController
{
    private readonly AlbumRepository _albumRepository;
    private readonly TrackListRepository _trackListRepository;
    private readonly TrackRepository _trackRepository;
    private readonly ArtistRepository _artistRepository;

    public AlbumController(
        AlbumRepository albumRepository,
        TrackListRepository trackListRepository,
        TrackRepository trackRepository,
        ArtistRepository artistRepository)
    {
        _albumRepository = albumRepository;
        _trackListRepository = trackListRepository;
        _trackRepository = trackRepository;
        _artistRepository = artistRepository;
    }

    // GET /api/albums
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        List<Album> albums = await _albumRepository.GetAllAsync();
        List<AlbumDto> albumDtos = new List<AlbumDto>();
        foreach (Album album in albums)
        {
            string? artistName = await _artistRepository.GetNameById(album.ArtistId);
            albumDtos.Add(new AlbumDto(
                album.Id,
                album.Title,
                album.ArtistId,
                artistName
            ));
        }
        return Ok(albumDtos);
    }

    [HttpGet("{id}/tracks")]
    public async Task<IActionResult> GetTracksByAlbumId(string id)
    {
        List<TrackDto> trackDtos = new List<TrackDto>();
        List<Track> tracks = await _trackRepository.GetAllTracksByAlbumId(id);
        foreach (Track track in tracks)
        {
            string? artistName = await _artistRepository.GetNameById(track.ArtistId);
            trackDtos.Add(new TrackDto(
                track.Id,
                track.Title,
                track.TrackNumber,
                track.AlbumId ?? null,
                track.ArtistId ?? null,
                artistName ?? null,
                track.Duration,
                null
            ));
        }
        return Ok(trackDtos);
    }
}