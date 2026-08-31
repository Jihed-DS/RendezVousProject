namespace RendezVous.Data.Entities;

public class Creneau
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PrestataireId { get; set; }
    public Prestataire Prestataire { get; set; } = null!;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public bool IsAvailable { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte[] RowVersion { get; set; } = Array.Empty<byte>();
    public ICollection<CreneauTag> Tags { get; set; } = new List<CreneauTag>();
}