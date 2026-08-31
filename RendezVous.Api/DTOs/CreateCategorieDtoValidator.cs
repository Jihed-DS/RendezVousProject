using FluentValidation;

namespace RendezVous.Api.DTOs;

public class CreateCategorieDtoValidator : AbstractValidator<CreateCategorieDto>
{
    public CreateCategorieDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpdateCategorieDtoValidator : AbstractValidator<UpdateCategorieDto>
{
    public UpdateCategorieDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}