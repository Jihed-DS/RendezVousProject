using FluentValidation;
using RendezVous.Api.DTOs;

namespace RendezVous.Api.DTOs;

public class CreateAvisDtoValidator : AbstractValidator<CreateAvisDto>
{
    public CreateAvisDtoValidator()
    {
        RuleFor(x => x.PrestataireId).NotEmpty();
        RuleFor(x => x.AppointmentId).NotEmpty();
        RuleFor(x => x.Rating)
            .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5");
    }
}