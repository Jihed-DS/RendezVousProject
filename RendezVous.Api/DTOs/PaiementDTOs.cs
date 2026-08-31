namespace RendezVous.Api.DTOs;

public class CreatePaiementDto
{
    public Guid AppointmentId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TND";
    public string? PaymentMethod { get; set; }
}

public class UpdatePaiementDto
{
    public string Status { get; set; } = "pending";
    public string? TransactionId { get; set; }
}