using FluentValidation;
using RendezVous.Api.DTOs;

namespace RendezVous.Api.DTOs;

public class CreateCreneauDtoValidator : AbstractValidator<CreateCreneauDto>
{
    public CreateCreneauDtoValidator()
    {
        RuleFor(x => x.StartTime)
         .NotEmpty()
         .GreaterThan(DateTime.UtcNow).WithMessage("You cannot create a time slot in the past.");       
        RuleFor(x => x.StartTime).NotEmpty();
        RuleFor(x => x.EndTime).NotEmpty()
            .GreaterThan(x => x.StartTime).WithMessage("End time must be after start time");
        RuleForEach(x => x.Tags)
        .NotEmpty().WithMessage("A tag cannot be empty.")
        .MaximumLength(30).WithMessage("A tag must be 30 characters or fewer.");
        
        RuleFor(x => x.Tags)
                .Must(tags => tags == null || tags.Count <= 10)
                .WithMessage("Maximum 10 tags per time slot.");
    }
}