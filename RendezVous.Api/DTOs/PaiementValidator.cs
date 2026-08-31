using FluentValidation;
using RendezVous.Api.DTOs;

namespace RendezVous.Api.DTOs;

public class CreatePaiementDtoValidator : AbstractValidator<CreatePaiementDto>
{
    public CreatePaiementDtoValidator()
    {
        RuleFor(x => x.AppointmentId).NotEmpty();
        RuleFor(x => x.Amount).GreaterThan(0);
    }
}