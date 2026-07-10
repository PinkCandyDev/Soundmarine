using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace Soundmarine.server.Controllers;

public class BaseController : ControllerBase
{
    protected string GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)!.Value;
    protected string GetUsername() => User.Identity!.Name!;
}