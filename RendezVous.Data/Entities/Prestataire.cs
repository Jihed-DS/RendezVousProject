using RendezVous.Data.Entities;

public class Prestataire
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string? Bio { get; set; }
    public string? PhotoUrl { get; set; }
    public decimal RatingAvg { get; set; } = 0.0m;
    public string? City { get; set; }
    public int TotalReviews { get; set; } = 0;
    // Une seule catégorie principale par prestataire — nullable tant qu'il
    // ne l'a pas encore choisie après inscription.
    public Guid? CategorieId { get; set; }
    public Categorie? Categorie { get; set; }

    public ICollection<PrestataireSubcategory> Subcategories { get; set; } = new List<PrestataireSubcategory>();
}