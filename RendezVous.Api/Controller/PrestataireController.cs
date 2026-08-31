using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;
using Microsoft.AspNetCore.Http;
namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PrestataireController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public PrestataireController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: api/Prestataire
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PrestataireResponseDto>>> GetAll()
    {
        var list = await _context.Prestataires
            .Include(p => p.User)
            .Include(p => p.Categorie)
            .Include(p => p.Subcategories)
                .ThenInclude(ps => ps.Subcategory)
            .ToListAsync();

        var result = list.Select(p => new PrestataireResponseDto
        {
            Id = p.Id,
            Bio = p.Bio,
            PhotoUrl = p.PhotoUrl,
            RatingAvg = p.RatingAvg,
            TotalReviews = p.TotalReviews,
            FullName = p.User?.FullName,
            Email = p.User?.Email,
            CategorieName = p.Categorie?.Name,
            City = p.City,
            Subcategories = p.Subcategories.Select(ps => ps.Subcategory.Name).ToList()
        }).ToList();

        return Ok(result);
    }

    // GET: api/Prestataire/5
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PrestataireResponseDto>> GetById(Guid id)
    {
        var p = await _context.Prestataires
            .Include(x => x.User)
            .Include(x => x.Categorie)
            .Include(x => x.Subcategories)
                .ThenInclude(ps => ps.Subcategory)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (p == null) return NotFound();

        var dto = new PrestataireResponseDto
        {
            Id = p.Id,
            Bio = p.Bio,
            PhotoUrl = p.PhotoUrl,
            RatingAvg = p.RatingAvg,
            TotalReviews = p.TotalReviews,
            FullName = p.User?.FullName,
            Email = p.User?.Email,
            CategorieName = p.Categorie?.Name,
            City = p.City,
            Subcategories = p.Subcategories.Select(ps => ps.Subcategory.Name).ToList()
        };

        return Ok(dto);
    }
    // GET: api/Prestataire/me
    [HttpGet("me")]
    [Authorize(Roles = "Prestataire")]
    public async Task<ActionResult<PrestataireResponseDto>> GetMyProfile()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId)) return Unauthorized();

        var p = await _context.Prestataires
            .Include(x => x.User)
            .Include(x => x.Categorie)
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (p == null) return NotFound();

        return Ok(new PrestataireResponseDto
        {
            Id = p.Id,
            Bio = p.Bio,
            PhotoUrl = p.PhotoUrl,
            RatingAvg = p.RatingAvg,
            TotalReviews = p.TotalReviews,
            FullName = p.User?.FullName,
            Email = p.User?.Email,
            CategorieName = p.Categorie?.Name,
            City = p.City,
            Subcategories = new List<string>()
        });
    }
    // POST: api/Prestataire
    [HttpPost]
    [Authorize(Roles = "Admin,Prestataire")]
    public async Task<ActionResult<Prestataire>> Create([FromBody] CreatePrestataireDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId))
            return Unauthorized();

        var alreadyExists = await _context.Prestataires.AnyAsync(p => p.UserId == userId);
        if (alreadyExists)
            return Conflict("A Prestataire profile already exists for this account.");

        var categoryExists = await _context.Categories.AnyAsync(c => c.Id == dto.CategorieId);
        if (!categoryExists)
            return BadRequest($"Category with ID '{dto.CategorieId}' does not exist.");

        var prestataire = new Prestataire
        {
            UserId = userId,
            Bio = dto.Bio,
            PhotoUrl = dto.PhotoUrl,
            CategorieId = dto.CategorieId,
            City = dto.City
        };

        _context.Prestataires.Add(prestataire);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = prestataire.Id }, prestataire);
    }
    // POST: api/Prestataire/me/photo
    [HttpPost("me/photo")]
    [Authorize(Roles = "Prestataire")]
    public async Task<IActionResult> UploadPhoto(IFormFile photo)
    {
        if (photo == null || photo.Length == 0)
            return BadRequest("Aucun fichier fourni.");

        if (photo.Length > 5 * 1024 * 1024)
            return BadRequest("Le fichier dépasse 5 Mo.");

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(ext))
            return BadRequest("Format non supporté (jpg, jpeg, png, webp uniquement).");

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdClaim, out Guid userId))
            return Unauthorized();

        var prestataire = await _context.Prestataires.FirstOrDefaultAsync(p => p.UserId == userId);
        if (prestataire == null)
            return NotFound("Profil Prestataire introuvable.");

        var uploadsDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "prestataires");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(uploadsDir, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await photo.CopyToAsync(stream);
        }

        prestataire.PhotoUrl = $"/uploads/prestataires/{fileName}";
        await _context.SaveChangesAsync();

        return Ok(new { photoUrl = prestataire.PhotoUrl });
    }
    // PUT: api/Prestataire/5
    // FIX: ownership check conservé (id dans l'URL reste nécessaire ici,
    // car tu modifies un profil existant par son Id — mais on vérifie
    // qu'il t'appartient bien).
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Prestataire")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdatePrestataireDto dto)
    {
        var existing = await _context.Prestataires.FindAsync(id);
        if (existing == null) return NotFound();

        var callerRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var callerUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (callerRole != "Admin" &&
            (!Guid.TryParse(callerUserId, out var callerId) || existing.UserId != callerId))
        {
            return Forbid();
        }

        existing.Bio = dto.Bio;
        existing.PhotoUrl = dto.PhotoUrl;
        existing.City = dto.City;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/Prestataire/5
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var prestataire = await _context.Prestataires.FindAsync(id);
        if (prestataire == null) return NotFound();

        _context.Prestataires.Remove(prestataire);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}