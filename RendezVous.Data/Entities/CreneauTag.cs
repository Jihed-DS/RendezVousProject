using RendezVous.Data.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

public class CreneauTag
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CreneauId { get; set; }
    public Creneau Creneau { get; set; } = null!;
    public string Label { get; set; } = string.Empty;
}