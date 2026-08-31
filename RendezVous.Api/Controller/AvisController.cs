using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AvisController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AvisController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpPost]
    [Authorize(Roles = "Client")]
    public async Task<IActionResult> CreateReview([FromBody] CreateAvisDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                       ?? User.FindFirst("sub")?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var client = await _context.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null) return BadRequest("Client profile not found.");

        var hasValidAppointment = await _context.Appointments.AnyAsync(a =>
            a.Id == dto.AppointmentId &&
            a.ClientId == client.Id &&
            a.PrestataireId == dto.PrestataireId &&
            a.Status == "completed");

        if (!hasValidAppointment)
            return BadRequest("You can only review services you have booked and completed.");

        var alreadyReviewed = await _context.Avis
            .AnyAsync(a => a.AppointmentId == dto.AppointmentId);
        if (alreadyReviewed)
            return BadRequest("You have already reviewed this appointment.");

        var avis = new Avis
        {
            ClientId = client.Id,
            PrestataireId = dto.PrestataireId,
            AppointmentId = dto.AppointmentId,
            Rating = dto.Rating,
            Comment = dto.Comment,
            CreatedAt = DateTime.UtcNow
        };

        _context.Avis.Add(avis);
        await _context.SaveChangesAsync();

        await UpdatePrestataireRatingAsync(dto.PrestataireId);
        return Ok(avis);
    }
    // GET: api/Avis/summary/{prestataireId}
    [HttpGet("summary/{prestataireId:guid}")]
    public async Task<ActionResult<AvisSummaryDto>> GetSummary(Guid prestataireId)
    {
        var ratings = await _context.Avis
            .Where(a => a.PrestataireId == prestataireId)
            .Select(a => a.Rating)
            .ToListAsync();

        var distribution = Enumerable.Range(1, 5)
            .ToDictionary(star => star, star => ratings.Count(r => r == star));

        return Ok(new AvisSummaryDto
        {
            AverageRating = ratings.Count > 0 ? ratings.Average() : 0,
            TotalReviews = ratings.Count,
            DistributionByStar = distribution
        });
    }
    // GET: api/Avis/my-reviews (Prestataire — lecture seule de ses propres avis)
    [HttpGet("my-reviews")]
    [Authorize(Roles = "Prestataire")]
    public async Task<ActionResult<IEnumerable<AvisResponseDto>>> GetMyReviews()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null) return NotFound("Prestataire profile not found.");

        var list = await _context.Avis
            .Include(a => a.Client).ThenInclude(c => c.User)
            .Where(a => a.PrestataireId == prestataire.Id)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync();

        return Ok(list.Select(a => new AvisResponseDto
        {
            Id = a.Id,
            Rating = a.Rating,
            Comment = a.Comment,
            CreatedAt = a.CreatedAt,
            ClientName = a.Client?.User?.FullName
        }));
    }

    // GET: api/Avis/prestataire/{prestataireId} (public — historique visible sur une fiche)
    [HttpGet("prestataire/{prestataireId:guid}")]
    public async Task<ActionResult<IEnumerable<AvisResponseDto>>> GetByPrestataire(Guid prestataireId)
    {
        var list = await _context.Avis
            .Include(a => a.Client).ThenInclude(c => c.User)
            .Where(a => a.PrestataireId == prestataireId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync();

        return Ok(list.Select(a => new AvisResponseDto
        {
            Id = a.Id,
            Rating = a.Rating,
            Comment = a.Comment,
            CreatedAt = a.CreatedAt,
            ClientName = a.Client?.User?.FullName
        }));
    }
    private async Task UpdatePrestataireRatingAsync(Guid prestataireId)
    {
        var prestataire = await _context.Prestataires.FindAsync(prestataireId);
        if (prestataire != null)
        {
            var ratings = await _context.Avis
                .Where(a => a.PrestataireId == prestataireId)
                .Select(a => a.Rating)
                .ToListAsync();

            if (ratings.Any())
            {
                prestataire.TotalReviews = ratings.Count;
                prestataire.RatingAvg = (decimal)ratings.Average();
                await _context.SaveChangesAsync();
            }
        }
    }
}