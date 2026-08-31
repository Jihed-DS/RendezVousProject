using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;
using System.Data;
namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public UserController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET: api/User → Only Admin
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var users = await _context.Users.ToListAsync();
            return Ok(users.Select(u => new
            {
            u.Id, u.Email, u.FullName, u.Role, u.Phone,
u.ApprovalStatus, u.CreatedAt
        // PasswordHash volontairement exclu — ne doit jamais quitter le serveur.
   }));
        }

// GET: api/User/pending
[HttpGet("pending")]
[Authorize(Roles = "Admin")]
public async Task<IActionResult> GetPending()
{
    var users = await _context.Users
        .Where(u => u.ApprovalStatus == "pending")
        .OrderBy(u => u.CreatedAt)
        .ToListAsync();

    return Ok(users.Select(u => new
    {
        u.Id, u.Email, u.FullName, u.Role, u.Phone, u.CreatedAt
    }));
}

// POST: api/User/{id}/approve
 [HttpPost("{id:guid}/approve")]
 [Authorize(Roles = "Admin")]
public async Task<IActionResult> Approve(Guid id)
{
    var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();
        if (user.ApprovalStatus != "pending") return BadRequest("Ce compte a déjà été traité.");
    
    user.ApprovalStatus = "approved";
    await _context.SaveChangesAsync();
        return Ok(new { message = "Compte approuvé." });
    }

// POST: api/User/{id}/reject
 [HttpPost("{id:guid}/reject")]
 [Authorize(Roles = "Admin")]
public async Task<IActionResult> Reject(Guid id)
{
    var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();
        if (user.ApprovalStatus != "pending") return BadRequest("Ce compte a déjà été traité.");
    
    user.ApprovalStatus = "rejected";
    await _context.SaveChangesAsync();
        return Ok(new { message = "Compte refusé." });
}
    [HttpGet("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<User>> GetById(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();
        return user;
    }
    // POST: api/User → Only Admin
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<User>> Create(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
    }

    // PUT: api/User/5 → Only Admin
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, User user)
    {
        if (id != user.Id) return BadRequest();

        _context.Entry(user).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!_context.Users.Any(e => e.Id == id))
                return NotFound();
            else
                throw;
        }

        return NoContent();
    }

    // DELETE: api/User/5 → Only Admin
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound();

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}