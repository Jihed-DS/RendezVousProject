using FluentValidation;

namespace RendezVous.Api.DTOs;

public class RescheduleRendezVousDtoValidator : AbstractValidator<RescheduleRendezVousDto>
{
    public RescheduleRendezVousDtoValidator()
    {
        RuleFor(x => x.NewCreneauId).NotEmpty();
    }
}