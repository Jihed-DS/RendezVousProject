using RendezVous.Data.Entities;

public class Paiement
{
    public Guid Id { get; set; }
    public Guid AppointmentId { get; set; }
    public RendezVousEntity Appointment { get; set; } = null!;

    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TND";
    public string Status { get; set; } = "pending";
    public string? PaymentMethod { get; set; }
    public string? TransactionId { get; set; }
    public DateTime? PaidAt { get; set; }
}