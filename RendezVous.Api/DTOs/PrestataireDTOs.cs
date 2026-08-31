namespace RendezVous.Api.DTOs;


public class CreatePrestataireDto
{
    public string? Bio { get; set; }
    public string? PhotoUrl { get; set; }
    public Guid CategorieId { get; set; }
    public string? City { get; set; }
}

public class UpdatePrestataireDto
{
    public string? Bio { get; set; }
    public string? PhotoUrl { get; set; }
    public string? City { get; set; }
}