using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RendezVous.Api.DTOs;
using RendezVous.Api.Services;
using RendezVous.Data;
using RendezVous.Data.Entities;
using System.Net;
using System.Numerics;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
namespace RendezVous.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class ClientController : ControllerBase
{
    private readonly ClientService _clientService;
    private readonly ApplicationDbContext _context;
    public ClientController(ClientService clientService, ApplicationDbContext context)
    {
        _clientService = clientService;
        _context = context;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var clients = await _context.Clients
                    .Include(c => c.User)
                    .ToListAsync();
        
        var clientIds = clients.Select(c => c.Id).ToList();
        var countsByClient = await _context.Appointments
                    .Where(a => clientIds.Contains(a.ClientId))
                    .GroupBy(a => a.ClientId)
                    .Select(g => new { ClientId = g.Key, Count = g.Count() })
                    .ToDictionaryAsync(x => x.ClientId, x => x.Count);
        
        var result = clients
                    .Select(c => new ClientAdminResponseDto
                    {
            Id = c.Id,
FullName = c.User?.FullName,
Email = c.User?.Email,
Phone = c.User?.Phone,
Address = c.Address,
RendezVousCount = countsByClient.TryGetValue(c.Id, out var cnt) ? cnt : 0
            })
            .OrderByDescending(c => c.RendezVousCount)
            .ToList();
        
                return Ok(result);
    }
    // POST: api/Client

    [HttpPost]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Create()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                       ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized("User ID claim not found in token.");
        }

        var client = await _clientService.CreateClientAsync(userId);
        if (client == null)
            return Conflict("A Client profile already exists for this account.");

        return CreatedAtAction(nameof(GetById), new { id = client.Id }, client);
    }
    [HttpGet("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var client = await _clientService.GetClientByIdAsync(id);
        if (client == null) return NotFound("Client non trouvé.");
        return Ok(client);
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile()
    {
        // Check both standard JWT claim types for User ID
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                       ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized("User ID claim not found in token.");
        }

        var client = await _clientService.GetClientByUserIdAsync(userId);
        if (client == null) return NotFound("Profil client non trouvé.");

        return Ok(client);
    }
    [HttpPost("me/photo")]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> UploadPhoto(IFormFile photo)
    {
        if (photo == null || photo.Length == 0) return BadRequest("Aucun fichier fourni.");
        if (photo.Length > 5 * 1024 * 1024) return BadRequest("Le fichier dépasse 5 Mo.");

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext)) return BadRequest("Format non supporté.");

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return NotFound("Profil Client introuvable.");

        var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "clients");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(uploadsDir, fileName);
        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await photo.CopyToAsync(stream);
        }

        client.PhotoUrl = $"/uploads/clients/{fileName}";
        await _context.SaveChangesAsync();

        return Ok(new { photoUrl = client.PhotoUrl });
    }

    [HttpGet("me")]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> GetMe()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return NotFound();

        return Ok(new { client.Id, client.PhotoUrl });
    }
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateClientDto dto)
    {
        var updated = await _clientService.UpdateClientAsync(id, dto);
        if (!updated) return NotFound("Client non trouvé.");

        return NoContent();
    }
}