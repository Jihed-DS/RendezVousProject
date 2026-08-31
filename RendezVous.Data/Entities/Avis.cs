using RendezVous.Data.Entities;

public class Avis
{
    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public Client Client { get; set; } = null!;

    public Guid PrestataireId { get; set; }
    public Prestataire Prestataire { get; set; } = null!;

    public Guid? AppointmentId { get; set; }
    public RendezVousEntity? Appointment { get; set; }

    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}