using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class SubcategoryController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SubcategoryController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: api/Subcategory
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Subcategory>>> GetAll()
    {
        return await _context.Subcategories
            .Include(s => s.Category)
            .ToListAsync();
    }

    // GET: api/Subcategory/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Subcategory>> GetById(Guid id)
    {
        var subcategory = await _context.Subcategories
            .Include(s => s.Category)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (subcategory == null) return NotFound();

        return subcategory;
    }

    // GET: api/Subcategory/by-category/5
    [HttpGet("by-category/{categoryId}")]
    public async Task<ActionResult<IEnumerable<Subcategory>>> GetByCategory(Guid categoryId)
    {
        return await _context.Subcategories
            .Where(s => s.CategoryId == categoryId)
            .ToListAsync();
    }

    // POST: api/Subcategory
    // FIX: now takes CreateSubcategoryDto (already defined + validated via
    // CreateSubcategoryDtoValidator) instead of the raw entity — closes the
    // over-posting hole and enforces the FluentValidation rules automatically.
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Subcategory>> Create([FromBody] CreateSubcategoryDto dto)
    {
        var categoryExists = await _context.Categories.AnyAsync(c => c.Id == dto.CategoryId);
        if (!categoryExists)
            return BadRequest($"Category with ID '{dto.CategoryId}' does not exist.");

        var subcategory = new Subcategory
        {
            Id = Guid.NewGuid(),
            Name = dto.Name,
            Description = dto.Description,
            CategoryId = dto.CategoryId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Subcategories.Add(subcategory);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = subcategory.Id }, subcategory);
    }

    // PUT: api/Subcategory/5
    // FIX: same — uses UpdateSubcategoryDto instead of binding the raw entity.
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateSubcategoryDto dto)
    {
        var existing = await _context.Subcategories.FindAsync(id);
        if (existing == null) return NotFound();

        var categoryExists = await _context.Categories.AnyAsync(c => c.Id == dto.CategoryId);
        if (!categoryExists)
            return BadRequest($"Category with ID '{dto.CategoryId}' does not exist.");

        existing.Name = dto.Name;
        existing.Description = dto.Description;
        existing.CategoryId = dto.CategoryId;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    // DELETE: api/Subcategory/5
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var subcategory = await _context.Subcategories.FindAsync(id);
        if (subcategory == null) return NotFound();

        _context.Subcategories.Remove(subcategory);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}