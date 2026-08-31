namespace RendezVous.Api.DTOs;

public class CreateRendezVousDto
{
    public Guid CreneauId { get; set; }
    public string? Notes { get; set; }   
    public List<string>? SelectedTags { get; set; }
}