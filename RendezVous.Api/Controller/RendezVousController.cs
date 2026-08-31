using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Api.Services;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] // FIX: was [AllowAnonymous] — every action below now requires a valid JWT
public class RendezVousController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly RendezVousService _rendezVousService;
    private readonly IWebHostEnvironment _env;

    public RendezVousController(
        ApplicationDbContext context,
        RendezVousService rendezVousService,
        IWebHostEnvironment env)
    {
        _context = context;
        _rendezVousService = rendezVousService;
        _env = env;
    }

    // Resolves the current user's ID from the JWT.
    // The DB-lookup fallback only ever runs in Development, so a missing/invalid
    // token can never grant access in staging or production.
    private async Task<Guid?> GetUserIdAsync(string roleFilter = "")
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                       ?? User.FindFirst("sub")?.Value;

        if (Guid.TryParse(userIdClaim, out Guid userId))
        {
            return userId;
        }

        if (!_env.IsDevelopment())
        {
            // No fallback outside Development — an unauthenticated caller gets nothing.
            return null;
        }

        // --- DEV-ONLY TEST FALLBACK ---
        var query = _context.Users.AsQueryable();
        if (!string.IsNullOrEmpty(roleFilter))
        {
            query = query.Where(u => u.Role.ToLower() == roleFilter.ToLower());
        }

        var fallbackUser = await query.FirstOrDefaultAsync();
        return fallbackUser?.Id;
    }

    // GET: api/RendezVous (Admin only)
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IEnumerable<RendezVousEntity>>> GetAll()
    {
        return await _context.Appointments
            .Include(r => r.Client)
            .Include(r => r.Prestataire)
            .ToListAsync();
    }

    // GET: api/RendezVous/my-bookings
    [HttpGet("my-bookings")]
    public async Task<ActionResult<IEnumerable<RendezVousResponseDto>>> GetMyBookings()
    {
        var userId = await GetUserIdAsync();
        if (userId == null) return Unauthorized();

        var list = await _context.Appointments
            .Include(r => r.Client).ThenInclude(c => c.User)
            .Include(r => r.Prestataire).ThenInclude(p => p.User)
            .Include(r => r.Creneau)
            .Where(r => r.Client.UserId == userId || r.Prestataire.UserId == userId)
            .ToListAsync();

        var appointmentIds = list.Select(r => r.Id).ToList();
        var reviewedIds = await _context.Avis
            .Where(a => a.AppointmentId != null && appointmentIds.Contains(a.AppointmentId.Value))
            .Select(a => a.AppointmentId!.Value)
            .ToListAsync();

        var result = list.Select(r => new RendezVousResponseDto
        {
            Id = r.Id,
            PrestataireId = r.PrestataireId,
            Status = r.Status,
            Notes = r.Notes,
            SelectedTags = string.IsNullOrEmpty(r.SelectedTag)
            ? new List<string>()
            : r.SelectedTag.Split('|').ToList(),
            StartTime = r.Creneau?.StartTime,
            EndTime = r.Creneau?.EndTime,
            ClientName = r.Client?.User?.FullName,
            PrestataireName = r.Prestataire?.User?.FullName,
            HasReview = reviewedIds.Contains(r.Id)
        });

        return Ok(result);
    }

    // POST: api/RendezVous (Client creates a new booking)
    [HttpPost]
    [Authorize(Roles = "Client")]
    public async Task<ActionResult<RendezVousEntity>> Create([FromBody] CreateRendezVousDto dto)
    {
        var userId = await GetUserIdAsync("Client");
        if (userId == null) return Unauthorized("No Client user resolved.");

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return BadRequest("Client profile not found in database.");

        
        var (success, message, createdRendezVous) =
            await _rendezVousService.CreateRendezVousAsync(client.Id, dto);

        if (!success)
            return BadRequest(new { message });

        return CreatedAtAction(nameof(GetById), new { id = createdRendezVous!.Id }, createdRendezVous);
    }

    // POST: api/RendezVous/confirm/{id}
    [HttpPost("confirm/{id:guid}")]
    [Authorize(Roles = "Prestataire")]
    public async Task<IActionResult> Confirm(Guid id)
    {
        var userId = await GetUserIdAsync("Prestataire");
        if (userId == null) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return NotFound(new { message = "Provider profile not found for this user." });

        var result = await _rendezVousService.ConfirmBookingAsync(id, prestataire.Id);
        if (!result.Success)
            return BadRequest(new { message = result.Message });

        return Ok(new { message = result.Message });
    }

    // POST: api/RendezVous/deny/{id}
    [HttpPost("deny/{id:guid}")]
    [Authorize(Roles = "Prestataire")]
    public async Task<IActionResult> Deny(Guid id)
    {
        var userId = await GetUserIdAsync("Prestataire");
        if (userId == null) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return NotFound(new { message = "Provider profile not found for this user." });

        var result = await _rendezVousService.DenyBookingAsync(id, prestataire.Id);
        if (!result.Success)
            return BadRequest(new { message = result.Message });

        return Ok(new { message = result.Message });
    }
    // POST: api/RendezVous/complete/{id}
    [HttpPost("complete/{id:guid}")]
    [Authorize(Roles = "Prestataire")]
    public async Task<IActionResult> Complete(Guid id)
    {
        var userId = await GetUserIdAsync("Prestataire");
        if (userId == null) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return NotFound(new { message = "Provider profile not found for this user." });

        var result = await _rendezVousService.CompleteBookingAsync(id, prestataire.Id);
        if (!result.Success)
            return BadRequest(new { message = result.Message });

        return Ok(new { message = result.Message });
    }
    // POST: api/RendezVous/reschedule/{id}
    [HttpPost("reschedule/{id:guid}")]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Reschedule(Guid id, [FromBody] RescheduleRendezVousDto dto)
    {
        var userId = await GetUserIdAsync("Client");
        if (userId == null) return Unauthorized();

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return BadRequest("Client profile not found.");

        var result = await _rendezVousService.RescheduleAsync(id, client.Id, dto.NewCreneauId);
        if (!result.Success)
            return BadRequest(new { message = result.Message });

        return Ok(new { message = result.Message });
    }
    // POST: api/RendezVous/cancel/{id}
    [HttpPost("cancel/{id:guid}")]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> Cancel(Guid id)
    {
        var userId = await GetUserIdAsync("Client");
        if (userId == null) return Unauthorized();

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return BadRequest("Client profile not found.");

        var result = await _rendezVousService.CancelAsync(id, client.Id);
        if (!result.Success)
            return BadRequest(new { message = result.Message });

        return Ok(new { message = result.Message });
    }
    // GET: api/RendezVous/{id}
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<RendezVousEntity>> GetById(Guid id)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Client)
            .Include(r => r.Prestataire)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (rendezVous == null) return NotFound();

        return rendezVous;
    }
}