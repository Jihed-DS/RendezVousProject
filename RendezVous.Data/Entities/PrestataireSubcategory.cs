namespace RendezVous.Data.Entities;

public class PrestataireSubcategory
{
    public Guid PrestataireId { get; set; }
    public Prestataire Prestataire { get; set; } = null!;

    public Guid SubcategoryId { get; set; }
    public Subcategory Subcategory { get; set; } = null!;
}