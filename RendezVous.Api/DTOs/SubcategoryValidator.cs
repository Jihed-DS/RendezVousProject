using FluentValidation;

namespace RendezVous.Api.DTOs;

public class CreateSubcategoryDtoValidator : AbstractValidator<CreateSubcategoryDto>
{
    public CreateSubcategoryDtoValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Subcategory name is required.")
            .MaximumLength(100).WithMessage("Subcategory name cannot exceed 100 characters.");

        RuleFor(x => x.CategoryId)
            .NotEmpty().WithMessage("Category ID is required.");
    }
}