using RendezVous.Data.Entities;

public class Categorie
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Subcategory> Subcategories { get; set; } = new List<Subcategory>();
    public ICollection<Prestataire> Prestataires { get; set; } = new List<Prestataire>();
}