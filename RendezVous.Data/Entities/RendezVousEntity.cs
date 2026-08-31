using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace RendezVous.Data.Entities;

[Table("RendezVous")]
public class RendezVousEntity
{

    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public Client Client { get; set; } = null!;

    public Guid PrestataireId { get; set; }
    public Prestataire Prestataire { get; set; } = null!;

    public Guid? CategorieId { get; set; }
    public Categorie? Categorie { get; set; }
    public Guid? SubcategoryId { get; set; }
    public Subcategory? Subcategory { get; set; }
    public Guid? CreneauId { get; set; }
    public Creneau? Creneau { get; set; }

    public string Status { get; set; } = "pending";
    public string? Notes { get; set; }
    public string? SelectedTag { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}