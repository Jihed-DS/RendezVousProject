namespace RendezVous.Api.DTOs;

public class BulkCreateCreneauDto
{
    public DateTime Date { get; set; }           // le jour (l'heure est ignorée)
    public int StartHour { get; set; }            // ex: 7
    public int StartMinute { get; set; } = 0;
    public int EndHour { get; set; }              // ex: 11
    public int EndMinute { get; set; } = 0;
    public int SlotDurationMinutes { get; set; } = 60;
    public List<string>? Tags { get; set; }        // appliqués à chaque créneau généré
}