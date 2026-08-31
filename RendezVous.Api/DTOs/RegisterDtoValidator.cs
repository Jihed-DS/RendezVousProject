using FluentValidation;
using RendezVous.Api.Controllers;

namespace RendezVous.Api.DTOs;

public class RegisterDtoValidator : AbstractValidator<RegisterDto>
{
    public RegisterDtoValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty().MinimumLength(6);
        RuleFor(x => x.Role).NotEmpty().Must(r => r == "Client" || r == "Prestataire")
            .WithMessage("Role must be Client or Prestataire.");

        RuleFor(x => x.CategorieId)
            .NotNull()
            .When(x => x.Role == "Prestataire")
            .WithMessage("Un prestataire doit choisir une catégorie.");
    }
}