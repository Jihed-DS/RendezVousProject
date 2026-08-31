using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PaiementController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public PaiementController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: api/Paiement
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IEnumerable<PaiementResponseDto>>> GetAll()
    {
        var list = await _context.Paiements
            .Include(p => p.Appointment)
                .ThenInclude(a => a.Prestataire)
                    .ThenInclude(pr => pr.User)
            .ToListAsync();

        var result = list.Select(p => new PaiementResponseDto
        {
            Id = p.Id,
            Amount = p.Amount,
            Currency = p.Currency,
            Status = p.Status,
            PaymentMethod = p.PaymentMethod,
            TransactionId = p.TransactionId,
            PaidAt = p.PaidAt,
            AppointmentId = p.AppointmentId,
            PrestataireName = p.Appointment?.Prestataire?.User?.FullName
        }).ToList();

        return Ok(result);
    }

    // GET: api/Paiement/5
    [HttpGet("{id}")]
    [Authorize(Roles = "Admin,Prestataire")]
    public async Task<ActionResult<PaiementResponseDto>> GetById(Guid id)
    {
        var p = await _context.Paiements
            .Include(x => x.Appointment)
                .ThenInclude(a => a.Prestataire)
                    .ThenInclude(pr => pr.User)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (p == null) return NotFound();

        var dto = new PaiementResponseDto
        {
            Id = p.Id,
            Amount = p.Amount,
            Currency = p.Currency,
            Status = p.Status,
            PaymentMethod = p.PaymentMethod,
            TransactionId = p.TransactionId,
            PaidAt = p.PaidAt,
            AppointmentId = p.AppointmentId,
            PrestataireName = p.Appointment?.Prestataire?.User?.FullName
        };

        return Ok(dto);
    }

    // POST: api/Paiement
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Paiement>> Create([FromBody] CreatePaiementDto dto)
    {
        var paiement = new Paiement
        {
            AppointmentId = dto.AppointmentId,
            Amount = dto.Amount,
            Currency = dto.Currency,
            PaymentMethod = dto.PaymentMethod,
            Status = "pending"
        };

        _context.Paiements.Add(paiement);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = paiement.Id }, paiement);
    }

    // PUT: api/Paiement/5
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdatePaiementDto dto)
    {
        var existing = await _context.Paiements.FindAsync(id);
        if (existing == null) return NotFound();

        existing.Status = dto.Status;
        existing.TransactionId = dto.TransactionId;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/Paiement/5
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var paiement = await _context.Paiements.FindAsync(id);
        if (paiement == null) return NotFound();

        _context.Paiements.Remove(paiement);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}