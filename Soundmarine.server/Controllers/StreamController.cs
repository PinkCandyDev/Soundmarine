using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Soundmarine.lib.Repository;
using System.Diagnostics;
using System.Text.Json;

namespace Soundmarine.server.Controllers;

[Authorize]
[ApiController]
[Route("api/tracks")]
public class StreamController : BaseController
{
    private readonly TrackRepository _trackRepository;

    public StreamController(TrackRepository trackRepository)
    {
        _trackRepository = trackRepository;
    }

    private static readonly SemaphoreSlim _transcodeLimiter = new(4, 4);
    
    private static readonly HashSet<string> _nonStreamableExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".m4a", ".mp4", ".m4b", ".mov"
    };

    private record SourceInfo(string CodecName, int? BitrateKbps, int? SampleRate, int? BitsPerSample);

    [HttpGet("{trackId}/stream")]
    public async Task<IActionResult> Stream(string trackId, [FromQuery] string quality = "original")
    {
        string? filepath = await _trackRepository.GetFilepathById(trackId);
        if (filepath == null)
            return NotFound();

        string fullPath = $"/music{filepath}";
        if (!System.IO.File.Exists(fullPath))
            return NotFound();

        string extension = Path.GetExtension(fullPath);
        bool isStreamable = !_nonStreamableExtensions.Contains(extension);

        string OriginalContentType() => extension.ToLowerInvariant() switch
        {
            ".flac" => "audio/flac",
            ".mp3" => "audio/mpeg",
            ".ogg" => "audio/ogg",
            ".m4a" or ".mp4" or ".m4b" => "audio/mp4",
            _ => "audio/wav"
        };
        
        async Task<IActionResult> ServeOriginalOrRemux()
        {
            if (isStreamable)
                return PhysicalFile(fullPath, OriginalContentType(), enableRangeProcessing: true);

            
            
            var remuxArgs = new[]
            {
                "-c:a", "copy",
                "-f", "mp4",
                "-movflags", "frag_keyframe+empty_moov+default_base_moof",
                "pipe:1"
            };

            await _transcodeLimiter.WaitAsync(HttpContext.RequestAborted);
            try
            {
                return await TranscodeAndStream(fullPath, remuxArgs, "audio/mp4");
            }
            finally
            {
                _transcodeLimiter.Release();
            }
        }

        if (quality == "original")
            return await ServeOriginalOrRemux();

        (string[] ffmpegArgs, string contentType) = quality switch
        {
            "flac24" => (new[] { "-c:a", "flac", "-sample_fmt", "s32", "-ar", "48000", "-f", "flac", "pipe:1" }, "audio/flac"),
            "flac16" => (new[] { "-c:a", "flac", "-sample_fmt", "s16", "-ar", "44100", "-f", "flac", "pipe:1" }, "audio/flac"),
            "320"    => (new[] { "-c:a", "libmp3lame", "-b:a", "320k", "-f", "mp3", "pipe:1" }, "audio/mpeg"),
            "160"    => (new[] { "-c:a", "libopus", "-b:a", "160k", "-vbr", "on", "-f", "ogg", "pipe:1" }, "audio/ogg"),
            "96"     => (new[] { "-c:a", "libopus", "-b:a", "96k", "-vbr", "on", "-f", "ogg", "pipe:1" }, "audio/ogg"),
            "24"     => (new[] { "-c:a", "libopus", "-b:a", "24k", "-vbr", "on", "-application", "audio", "-f", "ogg", "pipe:1" }, "audio/ogg"),
            _ => (Array.Empty<string>(), null!)
        };

        if (ffmpegArgs.Length == 0)
            return BadRequest($"Unknown quality: {{quality}}. Available: original, flac24, flac16, 320, 160, 96, 24");

        var source = await ProbeSource(fullPath);
        if (source == null)
            return StatusCode(500, "Failed to read the metadata of the source file.");
        
        if (!ShouldTranscode(quality, source))
            return await ServeOriginalOrRemux();

        await _transcodeLimiter.WaitAsync(HttpContext.RequestAborted);
        try
        {
            return await TranscodeAndStream(fullPath, ffmpegArgs, contentType);
        }
        finally
        {
            _transcodeLimiter.Release();
        }
    }

    private static int EstimateSourceBitrateKbps(SourceInfo s)
    {
        bool isLossless = s.CodecName is "flac" or "alac" or "pcm_s16le" or "pcm_s24le" or "pcm_s32le" or "wav";

        if (!isLossless)
            return s.BitrateKbps ?? 320;

        int sampleRate = s.SampleRate ?? 44100;
        int bits = s.BitsPerSample ?? 16;
        return sampleRate * bits * 2 / 1000;
    }

    private static int TargetBitrateKbps(string quality) => quality switch
    {
        "24" => 24,
        "96" => 96,
        "160" => 160,
        "320" => 320,
        _ => 320
    };

    private static bool ShouldTranscode(string quality, SourceInfo source)
    {
        switch (quality)
        {
            case "320":
            case "160":
            case "96":
            case "24":
                return EstimateSourceBitrateKbps(source) > TargetBitrateKbps(quality);

            case "flac16":
            {
                bool isLossless = source.CodecName is "flac" or "alac" or "pcm_s16le" or "pcm_s24le" or "pcm_s32le";
                int sampleRate = source.SampleRate ?? 44100;
                int bitDepth = source.BitsPerSample ?? 16;
                return isLossless && (sampleRate > 44100 || bitDepth > 16);
            }

            case "flac24":
            {
                bool isLossless = source.CodecName is "flac" or "alac" or "pcm_s16le" or "pcm_s24le" or "pcm_s32le";
                int sampleRate = source.SampleRate ?? 44100;
                int bitDepth = source.BitsPerSample ?? 16;
                return isLossless && (sampleRate > 48000 || bitDepth > 24);
            }

            default:
                return false;
        }
    }

    private async Task<SourceInfo?> ProbeSource(string fullPath)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "ffprobe",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        psi.ArgumentList.Add("-v"); psi.ArgumentList.Add("error");
        psi.ArgumentList.Add("-select_streams"); psi.ArgumentList.Add("a:0");
        psi.ArgumentList.Add("-show_entries"); psi.ArgumentList.Add("stream=codec_name,sample_rate,bits_per_raw_sample,bit_rate");
        psi.ArgumentList.Add("-show_entries"); psi.ArgumentList.Add("format=bit_rate");
        psi.ArgumentList.Add("-of"); psi.ArgumentList.Add("json");
        psi.ArgumentList.Add(fullPath);

        using var process = Process.Start(psi);
        if (process == null) return null;

        string json = await process.StandardOutput.ReadToEndAsync();
        await process.WaitForExitAsync();
        if (process.ExitCode != 0) return null;

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            var streams = root.GetProperty("streams");
            if (streams.GetArrayLength() == 0) return null;
            var stream = streams[0];

            string codec = stream.TryGetProperty("codec_name", out var cn) ? cn.GetString() ?? "" : "";

            int? sampleRate = stream.TryGetProperty("sample_rate", out var sr) && sr.ValueKind == JsonValueKind.String
                && int.TryParse(sr.GetString(), out var srVal) ? srVal : null;

            int? bitsPerSample = stream.TryGetProperty("bits_per_raw_sample", out var bps) && bps.ValueKind == JsonValueKind.String
                && int.TryParse(bps.GetString(), out var bpsVal) ? bpsVal : null;

            int? streamBitrate = stream.TryGetProperty("bit_rate", out var br) && br.ValueKind == JsonValueKind.String
                && int.TryParse(br.GetString(), out var brVal) ? brVal / 1000 : null;

            int? formatBitrate = null;
            if (root.TryGetProperty("format", out var format)
                && format.TryGetProperty("bit_rate", out var fbr)
                && fbr.ValueKind == JsonValueKind.String
                && int.TryParse(fbr.GetString(), out var fbrVal))
            {
                formatBitrate = fbrVal / 1000;
            }

            int? bitrate = streamBitrate ?? formatBitrate;

            return new SourceInfo(codec, bitrate, sampleRate, bitsPerSample);
        }
        catch
        {
            return null;
        }
    }

    private async Task<IActionResult> TranscodeAndStream(string fullPath, string[] ffmpegArgs, string contentType)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "ffmpeg",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        psi.ArgumentList.Add("-hide_banner");
        psi.ArgumentList.Add("-loglevel"); psi.ArgumentList.Add("error");
        psi.ArgumentList.Add("-nostdin");
        psi.ArgumentList.Add("-i"); psi.ArgumentList.Add(fullPath);
        psi.ArgumentList.Add("-map"); psi.ArgumentList.Add("0:a:0");
        foreach (var arg in ffmpegArgs)
            psi.ArgumentList.Add(arg);

        var process = new Process { StartInfo = psi, EnableRaisingEvents = true };
        var cancellationToken = HttpContext.RequestAborted;

        try
        {
            process.Start();
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Couldn't launch ffmpeg: {ex.Message}");
        }

        _ = Task.Run(async () =>
        {
            try
            {
                string errors = await process.StandardError.ReadToEndAsync(cancellationToken);
                if (!string.IsNullOrWhiteSpace(errors))
                    Console.Error.WriteLine($"[ffmpeg] {errors}");
            }
            catch { }
        }, cancellationToken);

        Response.ContentType = contentType;
        Response.Headers.CacheControl = "no-cache";

        try
        {
            await process.StandardOutput.BaseStream.CopyToAsync(Response.Body, 81920, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            
        }
        finally
        {
            if (!process.HasExited)
            {
                try { process.Kill(entireProcessTree: true); }
                catch { }
            }
            process.Dispose();
        }

        return new EmptyResult();
    }
}