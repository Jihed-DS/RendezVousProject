namespace RendezVous.Api.DTOs;

public class CategoryDemandDto
{
    public string CategoryName { get; set; } = string.Empty;
    public int BookingCount { get; set; }
}

public class TrendingPrestataireDto
{
    public Guid Id { get; set; }
    public string? FullName { get; set; }
    public string? CategoryName { get; set; }
    public string? PhotoUrl { get; set; }
    public int BookingCount { get; set; }
    public decimal RatingAvg { get; set; }
}

public class AdminDashboardDto
{
    public int TotalClients { get; set; }
    public int TotalPrestataires { get; set; }
    public int TotalCategories { get; set; }
    public int TotalRendezVous { get; set; }
    public int RendezVousThisWeek { get; set; }
    public int PendingRendezVousCount { get; set; }
    public List<CategoryDemandDto> TopCategories { get; set; } = new();
    public List<TrendingPrestataireDto> TrendingPrestataires { get; set; } = new();
    public List<TrendingPrestataireDto> TopRatedPrestataires { get; set; } = new();
}