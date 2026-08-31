using FluentValidation;

namespace RendezVous.Api.DTOs;

public class BulkCreateCreneauDtoValidator : AbstractValidator<BulkCreateCreneauDto>
{
    public BulkCreateCreneauDtoValidator()
    {
        RuleFor(x => x.Date).NotEmpty();

        RuleFor(x => x.StartHour).InclusiveBetween(0, 23);
        RuleFor(x => x.EndHour).InclusiveBetween(0, 24);
        RuleFor(x => x.StartMinute).InclusiveBetween(0, 59);
        RuleFor(x => x.EndMinute).InclusiveBetween(0, 59);

        RuleFor(x => x.SlotDurationMinutes)
            .GreaterThan(0).WithMessage("La durée d'un créneau doit être positive.")
            .LessThanOrEqualTo(480).WithMessage("Un créneau ne peut pas dépasser 8h.");

        RuleFor(x => x)
            .Must(x =>
            {
                var start = new TimeSpan(x.StartHour, x.StartMinute, 0);
                var end = new TimeSpan(x.EndHour, x.EndMinute, 0);
                return end > start;
            })
            .WithMessage("L'heure de fin doit être après l'heure de début.");

        RuleForEach(x => x.Tags)
            .NotEmpty().MaximumLength(30);

        RuleFor(x => x.Tags)
            .Must(tags => tags == null || tags.Count <= 10)
            .WithMessage("Maximum 10 tags.");
    }
}