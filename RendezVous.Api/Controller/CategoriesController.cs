using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CategoriesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CategoriesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Categorie>>> GetCategories()
    {
        var categories = await _context.Categories.ToListAsync();
        return Ok(categories);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Categorie>> Create([FromBody] CreateCategorieDto dto)
    {
        var exists = await _context.Categories.AnyAsync(c => c.Name == dto.Name);
        if (exists)
            return Conflict("Une catégorie avec ce nom existe déjà.");

        var categorie = new Categorie
        {
            Name = dto.Name,
            Description = dto.Description,
            IconUrl = dto.IconUrl
        };

        _context.Categories.Add(categorie);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetCategories), new { id = categorie.Id }, categorie);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCategorieDto dto)
    {
        var existing = await _context.Categories.FindAsync(id);
        if (existing == null) return NotFound();

        var nameTaken = await _context.Categories.AnyAsync(c => c.Name == dto.Name && c.Id != id);
        if (nameTaken)
            return Conflict("Une autre catégorie porte déjà ce nom.");

        existing.Name = dto.Name;
        existing.Description = dto.Description;
        existing.IconUrl = dto.IconUrl;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var categorie = await _context.Categories.FindAsync(id);
        if (categorie == null) return NotFound();

        var inUse = await _context.Prestataires.AnyAsync(p => p.CategorieId == id);
        if (inUse)
            return BadRequest("Impossible de supprimer : des prestataires utilisent encore cette catégorie.");

        _context.Categories.Remove(categorie);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}