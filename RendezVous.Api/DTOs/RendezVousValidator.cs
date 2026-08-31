using FluentValidation;
using RendezVous.Data;

namespace RendezVous.Api.DTOs;

public class CreateRendezVousDtoValidator : AbstractValidator<CreateRendezVousDto>
{
    public CreateRendezVousDtoValidator(ApplicationDbContext context)
    {
        RuleFor(x => x.CreneauId).NotEmpty();

        RuleForEach(x => x.SelectedTags).MaximumLength(30);
        RuleFor(x => x.SelectedTags)
                    .Must((dto, tags) =>
                    {
                            if (tags == null || tags.Count == 0) return true;
            var validTags = context.CreneauTags
                                .Where(t => t.CreneauId == dto.CreneauId)
                                .Select(t => t.Label)
                                .ToList();
                            return tags.All(t => validTags.Contains(t));
                        })
            .WithMessage("Une ou plusieurs sous-catégories sélectionnées n'existent pas pour ce créneau.");
    }
}