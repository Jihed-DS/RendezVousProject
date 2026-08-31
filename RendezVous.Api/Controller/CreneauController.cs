using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;
using System.Security.Claims;
namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CreneauController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CreneauController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: api/Creneau
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CreneauResponseDto>>> GetAll()
    {
        var list = await _context.Creneaux
            .Include(c => c.Prestataire).ThenInclude(p => p.User)
            .Include(c => c.Tags)
            .ToListAsync();

        var result = list.Select(c => new CreneauResponseDto
        {
            Id = c.Id,
            StartTime = c.StartTime,
            EndTime = c.EndTime,
            IsAvailable = c.IsAvailable,
            PrestataireName = c.Prestataire?.User?.FullName,
            Tags = c.Tags.Select(t => t.Label).ToList()
        }).ToList();

        return Ok(result);
    }

    // GET: api/Creneau/my-slots
    [HttpGet("my-slots")]
    [Authorize(Roles = "Prestataire")]
    public async Task<ActionResult<IEnumerable<CreneauResponseDto>>> GetMySlots()
    {
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var list = await _context.Creneaux
            .Include(c => c.Prestataire).ThenInclude(p => p.User)
            .Include(c => c.Tags)
            .Where(c => c.Prestataire.UserId == userId)
            .ToListAsync();
        var creneauIds = list.Select(c => c.Id).ToList();
        var appointmentStatusByCreneau = await _context.Appointments
                .Where(a => a.CreneauId != null && creneauIds.Contains(a.CreneauId.Value))
                .ToDictionaryAsync(a => a.CreneauId!.Value, a => a.Status);

        var result = list.Select(c => new CreneauResponseDto
        {
            Id = c.Id,
            StartTime = c.StartTime,
            EndTime = c.EndTime,
            IsAvailable = c.IsAvailable,
            PrestataireName = c.Prestataire?.User?.FullName,
            AppointmentStatus = appointmentStatusByCreneau.TryGetValue(c.Id, out var status) ? status : null,
            Tags = c.Tags.Select(t => t.Label).ToList()
        }).ToList();

        return Ok(result);
    }

    // POST: api/Creneau
    [HttpPost]
    [Authorize(Roles = "Prestataire")]
    public async Task<ActionResult<Creneau>> Create([FromBody] CreateCreneauDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return BadRequest("No Prestataire profile found for this account.");

        var creneau = new Creneau
        {
            PrestataireId = prestataire.Id,
            StartTime = dto.StartTime,
            EndTime = dto.EndTime,
            IsAvailable = true
        };

        if (dto.Tags != null)
        {
            creneau.Tags = dto.Tags
                .Where(t => !string.IsNullOrWhiteSpace(t))
                .Select(t => new CreneauTag { Label = t.Trim() })
                .ToList();
        }

        _context.Creneaux.Add(creneau);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = creneau.Id }, creneau);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Prestataire")]
    

    [HttpDelete("{id}")]
    [Authorize(Roles = "Prestataire")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var creneau = await _context.Creneaux
            .Include(c => c.Prestataire)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (creneau == null) return NotFound();

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();
        if (creneau.Prestataire.UserId != userId) return Forbid();
        var isPast = creneau.EndTime <= DateTime.UtcNow;
        var linkedAppointment = await _context.Appointments.FirstOrDefaultAsync(a => a.CreneauId == id);
        if (!isPast && !creneau.IsAvailable)
            return BadRequest("Ce créneau est réservé — impossible de le supprimer.");
        if (linkedAppointment != null && (linkedAppointment.Status == "pending" || linkedAppointment.Status == "confirmed"))
                    return BadRequest("Un rendez-vous actif est lié à ce créneau.");
        
            if (linkedAppointment != null && linkedAppointment.Status == "completed")
                    return BadRequest("Impossible de supprimer un créneau lié à un rendez-vous terminé (historique).");
        _context.Creneaux.Remove(creneau);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CreneauResponseDto>> GetById(Guid id)
    {
        var c = await _context.Creneaux
            .Include(x => x.Prestataire).ThenInclude(p => p.User)
            .Include(c => c.Tags)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (c == null) return NotFound();

        var dto = new CreneauResponseDto
        {
            Id = c.Id,
            StartTime = c.StartTime,
            EndTime = c.EndTime,
            IsAvailable = c.IsAvailable,
            PrestataireName = c.Prestataire?.User?.FullName,
            Tags = c.Tags.Select(t => t.Label).ToList()
        };

        return Ok(dto);
    }
    // POST: api/Creneau/bulk
    // Génère plusieurs créneaux consécutifs de durée fixe dans une plage horaire donnée.
    // Ex: Date=2026-08-01, StartHour=7, EndHour=11, SlotDurationMinutes=60
    //     -> crée 4 créneaux : 7h-8h, 8h-9h, 9h-10h, 10h-11h.
    [HttpPost("bulk")]
    [Authorize(Roles = "Prestataire")]
    public async Task<ActionResult<IEnumerable<Creneau>>> CreateBulk([FromBody] BulkCreateCreneauDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return BadRequest("No Prestataire profile found for this account.");

        var dayStart = DateTime.SpecifyKind(dto.Date.Date, DateTimeKind.Utc)
            .AddHours(dto.StartHour).AddMinutes(dto.StartMinute);
        var dayEnd = DateTime.SpecifyKind(dto.Date.Date, DateTimeKind.Utc)
            .AddHours(dto.EndHour).AddMinutes(dto.EndMinute);

        if (dayStart <= DateTime.UtcNow)
            return BadRequest("Impossible de créer des créneaux dans le passé.");

        var slotDuration = TimeSpan.FromMinutes(dto.SlotDurationMinutes);
        var newCreneaux = new List<Creneau>();

        var cursor = dayStart;
        while (cursor + slotDuration <= dayEnd)
        {
            var creneau = new Creneau
            {
                PrestataireId = prestataire.Id,
                StartTime = cursor,
                EndTime = cursor + slotDuration,
                IsAvailable = true
            };

            if (dto.Tags != null)
            {
                creneau.Tags = dto.Tags
                    .Where(t => !string.IsNullOrWhiteSpace(t))
                    .Select(t => new CreneauTag { Label = t.Trim() })
                    .ToList();
            }

            newCreneaux.Add(creneau);
            cursor += slotDuration;
        }

        if (newCreneaux.Count == 0)
            return BadRequest("La plage horaire est trop courte pour générer au moins un créneau.");

        // Vérifie qu'aucun créneau généré ne chevauche un créneau existant du même prestataire.
        foreach (var c in newCreneaux)
        {
            bool overlap = await _context.Creneaux.AnyAsync(existing =>
                existing.PrestataireId == prestataire.Id &&
                existing.StartTime < c.EndTime &&
                existing.EndTime > c.StartTime);

            if (overlap)
                return BadRequest($"Le créneau {c.StartTime:HH:mm}-{c.EndTime:HH:mm} chevauche un créneau existant.");
        }

        _context.Creneaux.AddRange(newCreneaux);
        await _context.SaveChangesAsync();

        return Ok(newCreneaux);
    }
    // GET: api/Creneau/by-prestataire/{prestataireId}
    // Public — ne montre que les créneaux disponibles et futurs (vue Client pour réserver).
    [HttpGet("by-prestataire/{prestataireId:guid}")]
    public async Task<ActionResult<IEnumerable<CreneauResponseDto>>> GetByPrestataire(Guid prestataireId)
    {
        var now = DateTime.UtcNow;

        var list = await _context.Creneaux
            .Include(c => c.Prestataire).ThenInclude(p => p.User)
            .Include(c => c.Tags)
            .Where(c => c.PrestataireId == prestataireId && c.IsAvailable && c.StartTime > now)
            .OrderBy(c => c.StartTime)
            .ToListAsync();

        var result = list.Select(c => new CreneauResponseDto
        {
            Id = c.Id,
            StartTime = c.StartTime,
            EndTime = c.EndTime,
            IsAvailable = c.IsAvailable,
            PrestataireId = c.PrestataireId,
            PrestataireName = c.Prestataire?.User?.FullName,
            Tags = c.Tags.Select(t => t.Label).ToList()
        }).ToList();

        return Ok(result);
    }
}