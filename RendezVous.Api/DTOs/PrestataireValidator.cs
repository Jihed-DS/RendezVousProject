using FluentValidation;
using RendezVous.Api.DTOs;

namespace RendezVous.Api.DTOs;

public class CreatePrestataireDtoValidator : AbstractValidator<CreatePrestataireDto>
{
    public CreatePrestataireDtoValidator()
    {
        RuleFor(x => x.Bio)
            .MaximumLength(1000).WithMessage("Bio cannot exceed 1000 characters.");
    }
}