using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using RendezVous.Data;
using RendezVous.Data.Entities;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BCrypt.Net;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthController(ApplicationDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    // POST: api/Auth/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto model)
    {
        if (await _context.Users.AnyAsync(u => u.Email == model.Email))
            return BadRequest("Email already exists.");

        if (model.Role == "Prestataire" && model.CategorieId == null)
            return BadRequest("Un prestataire doit choisir une catégorie.");

        if (model.Role == "Prestataire")
        {
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == model.CategorieId);
            if (!categoryExists)
                return BadRequest($"Category with ID '{model.CategorieId}' does not exist.");
        }

        var user = new User
        {
            Email = model.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(model.Password),
            Role = model.Role,
            FullName = model.FullName,
            Phone = model.Phone,
            ApprovalStatus = "pending" // en attente de validation Admin
        };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        if (model.Role == "Client")
        {
            _context.Clients.Add(new Client { UserId = user.Id });
        }
        else if (model.Role == "Prestataire")
        {
            _context.Prestataires.Add(new Prestataire
            {
                UserId = user.Id,
                CategorieId = model.CategorieId!.Value
            });
        }
        await _context.SaveChangesAsync();

        return Ok(new { message = "Inscription reçue. Ton compte sera activé après validation par l'administrateur." });
    }

    // POST: api/Auth/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto model)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == model.Email);
        if (user == null || !BCrypt.Net.BCrypt.Verify(model.Password, user.PasswordHash))
            return Unauthorized("Invalid email or password.");

        if (user.ApprovalStatus == "pending")
            return StatusCode(403, new { message = "Ton compte est en attente de validation par l'administrateur." });

        if (user.ApprovalStatus == "rejected")
            return StatusCode(403, new { message = "Ton compte a été refusé par l'administrateur." });

        var token = GenerateJwtToken(user);
        return Ok(new
        {
            token = token,
            user = new
            {
                user.Id,
                user.Email,
                user.FullName,
                user.Role
            }
        });
    }

    // POST: api/Auth/forgot-password
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);

        // Réponse identique que l'email existe ou non — évite l'énumération de comptes.
        if (user == null)
            return Ok(new { message = "Si ce compte existe, une demande a été transmise à l'administrateur." });

        var alreadyPending = await _context.PasswordResetRequests
            .AnyAsync(r => r.UserId == user.Id && r.Status == "pending");

        if (!alreadyPending)
        {
            _context.PasswordResetRequests.Add(new PasswordResetRequest { UserId = user.Id });
            await _context.SaveChangesAsync();
        }

        return Ok(new { message = "Si ce compte existe, une demande a été transmise à l'administrateur." });
    }

    private string GenerateJwtToken(User user)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("FullName", user.FullName ?? "")
        };
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var durationMinutes = double.TryParse(_configuration["Jwt:DurationInMinutes"], out var parsed) ? parsed : 30;

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(durationMinutes),
            signingCredentials: creds
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// DTOs
public class RegisterDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public Guid? CategorieId { get; set; } // requis uniquement si Role == "Prestataire"
}

public class LoginDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class ForgotPasswordDto
{
    public string Email { get; set; } = string.Empty;
}