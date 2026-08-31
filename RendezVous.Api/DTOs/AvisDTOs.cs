namespace RendezVous.Api.DTOs;

public class CreateAvisDto
{
    public Guid PrestataireId { get; set; }
    public Guid AppointmentId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}

public class UpdateAvisDto
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
}