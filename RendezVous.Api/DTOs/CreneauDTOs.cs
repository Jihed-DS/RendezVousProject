namespace RendezVous.Api.DTOs;
public class CreateCreneauDto
{
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public List<string>? Tags { get; set; }
}