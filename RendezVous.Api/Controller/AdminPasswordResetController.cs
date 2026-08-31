using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminPasswordResetController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AdminPasswordResetController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var requests = await _context.PasswordResetRequests
            .Include(r => r.User)
            .Where(r => r.Status == "pending")
            .OrderBy(r => r.CreatedAt)
            .ToListAsync();

        return Ok(requests.Select(r => new
        {
            r.Id,
            r.CreatedAt,
            UserEmail = r.User.Email,
            UserFullName = r.User.FullName,
            UserRole = r.User.Role
        }));
    }

    public class ResolvePasswordResetDto
    {
        public string NewPassword { get; set; } = string.Empty;
    }

    [HttpPost("{id:guid}/resolve")]
    public async Task<IActionResult> Resolve(Guid id, [FromBody] ResolvePasswordResetDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.NewPassword) || dto.NewPassword.Length < 6)
            return BadRequest("Le nouveau mot de passe doit contenir au moins 6 caractères.");

        var request = await _context.PasswordResetRequests
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (request == null) return NotFound();
        if (request.Status != "pending") return BadRequest("Cette demande a déjà été traitée.");

        request.User.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        request.Status = "resolved";
        request.ResolvedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Mot de passe réinitialisé." });
    }
}