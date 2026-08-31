using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using RendezVous.Data.Entities;

namespace RendezVous.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Categorie> Categories { get; set; }
    public DbSet<PasswordResetRequest> PasswordResetRequests { get; set; }
    public DbSet<Client> Clients { get; set; }
    public DbSet<Prestataire> Prestataires { get; set; }
    public DbSet<PrestataireSubcategory> PrestataireSubcategories { get; set; }
    public DbSet<Subcategory> Subcategories { get; set; }
    public DbSet<RendezVousEntity> Appointments { get; set; }
    public DbSet<Creneau> Creneaux { get; set; }
    public DbSet<Avis> Avis { get; set; }
    public DbSet<Paiement> Paiements { get; set; }
    public DbSet<Notification> Notifications { get; set; }

    public DbSet<CreneauTag> CreneauTags { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Clé composite pour la table de jonction Prestataire <-> Subcategory
        modelBuilder.Entity<PrestataireSubcategory>()
            .HasKey(ps => new { ps.PrestataireId, ps.SubcategoryId });

        // Un prestataire garde sa fiche même si sa catégorie est supprimée
        // par l'Admin — SetNull plutôt que Cascade, pour ne rien détruire.
        modelBuilder.Entity<Prestataire>()
            .HasOne(p => p.Categorie)
            .WithMany(c => c.Prestataires)
            .HasForeignKey(p => p.CategorieId)
            .OnDelete(DeleteBehavior.SetNull);

        // Précision décimale explicite (recommandé avec Npgsql)
        modelBuilder.Entity<Paiement>()
            .Property(p => p.Amount)
            .HasColumnType("decimal(18,2)");

        modelBuilder.Entity<Prestataire>()
            .Property(p => p.RatingAvg)
            .HasColumnType("decimal(3,2)");
        modelBuilder.Entity<Creneau>()
            .Property(c => c.RowVersion)
            .IsRowVersion();
        modelBuilder.Entity<CreneauTag>()
            .HasOne(t => t.Creneau)
            .WithMany(c => c.Tags)
            .HasForeignKey(t => t.CreneauId)
            .OnDelete(DeleteBehavior.Cascade);
        var utcConverter = new ValueConverter<DateTime, DateTime>(
        v => v.Kind == DateTimeKind.Utc ? v : DateTime.SpecifyKind(v, DateTimeKind.Utc),
        v => DateTime.SpecifyKind(v, DateTimeKind.Utc));

        var nullableUtcConverter = new ValueConverter<DateTime?, DateTime?>(
            v => v.HasValue
                ? (v.Value.Kind == DateTimeKind.Utc ? v.Value : DateTime.SpecifyKind(v.Value, DateTimeKind.Utc))
                : v,
            v => v.HasValue ? DateTime.SpecifyKind(v.Value, DateTimeKind.Utc) : v);

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            foreach (var property in entityType.GetProperties())
            {
                if (property.ClrType == typeof(DateTime))
                {
                    property.SetValueConverter(utcConverter);
                }
                else if (property.ClrType == typeof(DateTime?))
                {
                    property.SetValueConverter(nullableUtcConverter);
                }
            }
        }
    }

}