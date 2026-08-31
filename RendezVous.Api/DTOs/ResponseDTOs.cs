namespace RendezVous.Api.DTOs;

// Response DTO for RendezVous (Appointment)
public class RendezVousResponseDto
{
    public Guid Id { get; set; }
    public Guid PrestataireId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public List<string> SelectedTags { get; set; } = new();
    public DateTime? StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public string? ClientName { get; set; }
    public string? PrestataireName { get; set; }
    public bool HasReview { get; set; }
}

// Response DTO for Prestataire
public class PrestataireResponseDto
{
    public Guid Id { get; set; }
    public string? Bio { get; set; }
    public string? PhotoUrl { get; set; }
    public decimal RatingAvg { get; set; }
    public int TotalReviews { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
   public string? CategorieName { get; set; }
    public string? City { get; set; }
    public List<string> Subcategories { get; set; } = new();
}

// Response DTO for Creneau
public class CreneauResponseDto
{
    public Guid Id { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public bool IsAvailable { get; set; }
    public Guid PrestataireId { get; set; }
    public string? PrestataireName { get; set; }

    public string? AppointmentStatus { get; set; }
    public List<string> Tags { get; set; } = new();
}

// Response DTO for Avis
public class AvisResponseDto
{
    public Guid Id { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ClientName { get; set; }
}
public class AvisSummaryDto
{
    public double AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public Dictionary<int, int> DistributionByStar { get; set; } = new(); // clé: 1-5, valeur: nombre d'avis
}
// Response DTO for Paiement
public class PaiementResponseDto
{
    public Guid Id { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TND";
    public string Status { get; set; } = string.Empty;
    public string? PaymentMethod { get; set; }
    public string? TransactionId { get; set; }
    public DateTime? PaidAt { get; set; }

    // Related data
    public Guid AppointmentId { get; set; }
    public string? PrestataireName { get; set; }
}
public class ClientAdminResponseDto
{
    public Guid Id { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public int RendezVousCount { get; set; }
}