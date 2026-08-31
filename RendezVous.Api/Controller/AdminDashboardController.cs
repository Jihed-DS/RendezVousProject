using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminDashboardController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AdminDashboardController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<AdminDashboardDto>> GetDashboard()
    {
        var now = DateTime.UtcNow;
        var weekAgo = now.AddDays(-7);

        var totalClients = await _context.Clients.CountAsync();
        var totalPrestataires = await _context.Prestataires.CountAsync();
        var totalCategories = await _context.Categories.CountAsync();
        var totalRendezVous = await _context.Appointments.CountAsync();
        var rendezVousThisWeek = await _context.Appointments.CountAsync(r => r.CreatedAt >= weekAgo);
        var pendingCount = await _context.Appointments.CountAsync(r => r.Status == "pending");

        // Catégories les plus demandées (nombre total de rendez-vous)
        var topCategories = await _context.Appointments
            .Include(r => r.Prestataire).ThenInclude(p => p.Categorie)
            .Where(r => r.Prestataire.Categorie != null)
            .GroupBy(r => r.Prestataire.Categorie!.Name)
            .Select(g => new CategoryDemandDto
            {
                CategoryName = g.Key,
                BookingCount = g.Count()
            })
            .OrderByDescending(c => c.BookingCount)
            .Take(5)
            .ToListAsync();

                // Prestataires "tendance" : groupement par PrestataireId (scalaire),
                // puis récupération séparée des détails — évite le piège EF Core où
                // les Include ne suivent pas correctement à travers un GroupBy sur entité.
        var trendingCounts = await _context.Appointments
                    .GroupBy(r => r.PrestataireId)
                    .Select(g => new { PrestataireId = g.Key, BookingCount = g.Count() })
                    .OrderByDescending(g => g.BookingCount)
                    .Take(5)
                    .ToListAsync();
        
        var trendingIds = trendingCounts.Select(t => t.PrestataireId).ToList();
        var trendingDetails = await _context.Prestataires
                    .Include(p => p.User)
                    .Include(p => p.Categorie)
                    .Where(p => trendingIds.Contains(p.Id))
                    .ToListAsync();
        
        var trending = trendingCounts.Select(t =>
                {
            var p = trendingDetails.First(x => x.Id == t.PrestataireId);
                        return new TrendingPrestataireDto
                        {
                Id = p.Id,
                FullName = p.User?.FullName,
                CategoryName = p.Categorie?.Name,
                PhotoUrl = p.PhotoUrl,
                BookingCount = t.BookingCount,
                RatingAvg = p.RatingAvg
            }
            ;
                    }).ToList();

        // Meilleurs notés (au moins 1 avis)
        var topRated = await _context.Prestataires
            .Include(p => p.User)
            .Include(p => p.Categorie)
            .Where(p => p.TotalReviews > 0)
            .OrderByDescending(p => p.RatingAvg)
            .ThenByDescending(p => p.TotalReviews)
            .Take(5)
            .Select(p => new TrendingPrestataireDto
            {
                Id = p.Id,
                FullName = p.User != null ? p.User.FullName : null,
                CategoryName = p.Categorie != null ? p.Categorie.Name : null,
                PhotoUrl = p.PhotoUrl,
                BookingCount = 0,
                RatingAvg = p.RatingAvg
            })
            .ToListAsync();

        return Ok(new AdminDashboardDto
        {
            TotalClients = totalClients,
            TotalPrestataires = totalPrestataires,
            TotalCategories = totalCategories,
            TotalRendezVous = totalRendezVous,
            RendezVousThisWeek = rendezVousThisWeek,
            PendingRendezVousCount = pendingCount,
            TopCategories = topCategories,
            TrendingPrestataires = trending,
            TopRatedPrestataires = topRated
        });
    }
}