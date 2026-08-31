using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Services;

public class RendezVousService
{
    private readonly ApplicationDbContext _context;

    public RendezVousService(ApplicationDbContext context)
    {
        _context = context;
    }

    // 1. Create a new booking (notifies the Prestataire)
    public async Task<(bool Success, string Message, RendezVousEntity? CreatedRendezVous)> CreateRendezVousAsync(Guid clientId, CreateRendezVousDto dto)
    {
        var creneau = await _context.Creneaux
            .Include(c => c.Prestataire)
                .ThenInclude(p => p.User) // We need the Prestataire's User details to get their UserId for notifications
            .FirstOrDefaultAsync(c => c.Id == dto.CreneauId);

        if (creneau == null)
            return (false, "The selected time slot does not exist.", null);

        if (!creneau.IsAvailable)
            return (false, "This time slot is no longer available.", null);

        if (creneau.StartTime <= DateTime.UtcNow)
            return (false, "You cannot book a time slot in the past.", null);

        bool hasOverlap = await _context.Appointments
            .AnyAsync(r =>
                r.PrestataireId == creneau.PrestataireId &&
                r.Status == "confirmed" &&
                r.Creneau != null &&
                r.Creneau.StartTime < creneau.EndTime &&
                r.Creneau.EndTime > creneau.StartTime
            );

        if (hasOverlap)
            return (false, "The Prestataire already has a confirmed booking at this time.", null);

        var rendezVous = new RendezVousEntity
        {
            Id = Guid.NewGuid(),
            ClientId = clientId, // Passed securely from the controller
            PrestataireId = creneau.PrestataireId,
            CreneauId = dto.CreneauId,
            Notes = dto.Notes,
            SelectedTag = dto.SelectedTags != null && dto.SelectedTags.Count > 0
                ? string.Join("|", dto.SelectedTags)
                : null,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(rendezVous);
        creneau.IsAvailable = false;

                try
        {
            await _context.SaveChangesAsync();
                    }
                catch (DbUpdateConcurrencyException)
        {
                        // Un autre client a réservé ce créneau entre la lecture et l'écriture.
                        return (false, "Ce créneau vient d'être réservé par quelqu'un d'autre. Merci de choisir un autre horaire.", null);
                    }

        // Send Notification to Prestataire (using their UserId)
        if (creneau.Prestataire?.UserId != null)
        {
            var clientUser = await _context.Clients
                .Include(c => c.User)
                .Where(c => c.Id == clientId)
                .Select(c => c.User.FullName)
                .FirstOrDefaultAsync();

            string clientName = clientUser ?? "A client";
            string formattedTime = creneau.StartTime.ToLocalTime().ToString("dd/MM/yyyy HH:mm");

            await CreateNotificationAsync(
                creneau.Prestataire.UserId,
                "New Booking Request",
                $"{clientName} has requested an appointment on {formattedTime}.",
                "BookingRequest"
            );
        }

        return (true, "Booking request sent. Waiting for Prestataire confirmation.", rendezVous);
    }

    // 2. Prestataire confirms the booking (notifies the Client)
    public async Task<(bool Success, string Message)> ConfirmBookingAsync(Guid rendezVousId, Guid prestataireId)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Client) // Need Client to find their UserId
            .Include(r => r.Creneau)
            .Include(r => r.Prestataire).ThenInclude(p => p.User)
            .FirstOrDefaultAsync(r => r.Id == rendezVousId && r.PrestataireId == prestataireId);

        if (rendezVous == null)
            return (false, "Booking not found or you are not the owner.");

        if (rendezVous.Status != "pending")
            return (false, "Booking is not in pending status.");

        rendezVous.Status = "confirmed";
        rendezVous.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Send Notification to Client (using their UserId)
        if (rendezVous.Client?.UserId != null)
        {
            string providerName = rendezVous.Prestataire?.User?.FullName ?? "The provider";
            string formattedTime = rendezVous.Creneau != null
                ? rendezVous.Creneau.StartTime.ToLocalTime().ToString("dd/MM/yyyy HH:mm")
                : "the requested time";

            await CreateNotificationAsync(
                rendezVous.Client.UserId,
                "Booking Confirmed!",
                $"{providerName} has confirmed your appointment on {formattedTime}.",
                "BookingConfirmed"
            );
        }

        return (true, "Booking confirmed successfully.");
    }

    // 3. Prestataire denies the booking (notifies the Client)
    public async Task<(bool Success, string Message)> DenyBookingAsync(Guid rendezVousId, Guid prestataireId)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Client) // Need Client to find their UserId
            .Include(r => r.Creneau)
            .Include(r => r.Prestataire).ThenInclude(p => p.User)
            .FirstOrDefaultAsync(r => r.Id == rendezVousId && r.PrestataireId == prestataireId);

        if (rendezVous == null)
            return (false, "Booking not found or you are not the owner.");

        if (rendezVous.Status != "pending")
            return (false, "Booking is not in pending status.");

        rendezVous.Status = "refused";
        rendezVous.UpdatedAt = DateTime.UtcNow;

        // Release the Creneau back to available
        if (rendezVous.Creneau != null)
            rendezVous.Creneau.IsAvailable = true;

        await _context.SaveChangesAsync();

        // Send Notification to Client (using their UserId)
        if (rendezVous.Client?.UserId != null)
        {
            string providerName = rendezVous.Prestataire?.User?.FullName ?? "The provider";
            string formattedTime = rendezVous.Creneau != null
                ? rendezVous.Creneau.StartTime.ToLocalTime().ToString("dd/MM/yyyy HH:mm")
                : "the requested time";

            await CreateNotificationAsync(
                rendezVous.Client.UserId,
                "Booking Declined",
                $"{providerName} was unable to accept your appointment on {formattedTime}.",
                "BookingDeclined"
            );
        }

        return (true, "Booking refused.");
    }
    // 4. Prestataire marque le rendez-vous comme terminé
    public async Task<(bool Success, string Message)> CompleteBookingAsync(Guid rendezVousId, Guid prestataireId)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Creneau)
            .FirstOrDefaultAsync(r => r.Id == rendezVousId && r.PrestataireId == prestataireId);

        if (rendezVous == null)
            return (false, "Booking not found or you are not the owner.");

        if (rendezVous.Status != "confirmed")
            return (false, "Only a confirmed booking can be marked as completed.");
            if (rendezVous.Creneau == null)
                    return (false, "Créneau introuvable.");
        
        var now = DateTime.UtcNow;
            if (now < rendezVous.Creneau.StartTime || now > rendezVous.Creneau.EndTime)
                    return (false, "Vous ne pouvez marquer ce rendez-vous comme terminé que pendant sa plage horaire.");
        
                rendezVous.Status = "completed";
        rendezVous.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return (true, "Booking marked as completed.");
    }
    // Helper method to create and save notifications
    // 5. Le client reprogramme son rendez-vous sur un autre créneau du même prestataire.
    // Repasse le statut à "pending" — le prestataire doit reconfirmer la nouvelle date.
    public async Task<(bool Success, string Message)> RescheduleAsync(Guid rendezVousId, Guid clientId, Guid newCreneauId)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Creneau)
            .Include(r => r.Prestataire).ThenInclude(p => p.User)
            .FirstOrDefaultAsync(r => r.Id == rendezVousId && r.ClientId == clientId);

        if (rendezVous == null)
            return (false, "Rendez-vous introuvable ou vous n'en êtes pas le propriétaire.");

            if (rendezVous.Status != "pending")
                    return (false, "Seul un rendez-vous en attente peut être reprogrammé.");

        var newCreneau = await _context.Creneaux
            .FirstOrDefaultAsync(c => c.Id == newCreneauId);

        if (newCreneau == null)
            return (false, "Le nouveau créneau n'existe pas.");

        if (newCreneau.PrestataireId != rendezVous.PrestataireId)
            return (false, "Le nouveau créneau doit appartenir au même prestataire.");

        if (!newCreneau.IsAvailable)
            return (false, "Ce créneau n'est plus disponible.");

        if (newCreneau.StartTime <= DateTime.UtcNow)
            return (false, "Impossible de reprogrammer sur un créneau déjà passé.");

        bool hasOverlap = await _context.Appointments
            .AnyAsync(r =>
                r.Id != rendezVous.Id &&
                r.PrestataireId == newCreneau.PrestataireId &&
                r.Status == "confirmed" &&
                r.Creneau != null &&
                r.Creneau.StartTime < newCreneau.EndTime &&
                r.Creneau.EndTime > newCreneau.StartTime);

        if (hasOverlap)
            return (false, "Le prestataire a déjà un rendez-vous confirmé sur ce créneau.");

        // Libère l'ancien créneau (sauf s'il est déjà passé — inutile de le réouvrir).
        if (rendezVous.Creneau != null && rendezVous.Creneau.StartTime > DateTime.UtcNow)
            rendezVous.Creneau.IsAvailable = true;

        newCreneau.IsAvailable = false;
        rendezVous.CreneauId = newCreneau.Id;
        rendezVous.Status = "pending";
        rendezVous.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        if (rendezVous.Prestataire?.UserId != null)
        {
            var formattedTime = newCreneau.StartTime.ToLocalTime().ToString("dd/MM/yyyy HH:mm");
            await CreateNotificationAsync(
                rendezVous.Prestataire.UserId,
                "Rendez-vous reprogrammé",
                $"Un client a reprogrammé son rendez-vous au {formattedTime}. Merci de confirmer à nouveau.",
                "BookingRescheduled"
            );
        }

        return (true, "Rendez-vous reprogrammé. En attente de confirmation.");
    }
    // 6. Le client annule son rendez-vous (libère le créneau, notifie le prestataire)
    public async Task<(bool Success, string Message)> CancelAsync(Guid rendezVousId, Guid clientId)
    {
        var rendezVous = await _context.Appointments
            .Include(r => r.Creneau)
            .Include(r => r.Prestataire).ThenInclude(p => p.User)
            .FirstOrDefaultAsync(r => r.Id == rendezVousId && r.ClientId == clientId);

        if (rendezVous == null)
            return (false, "Rendez-vous introuvable ou vous n'en êtes pas le propriétaire.");

        if (rendezVous.Status is not ("pending" or "confirmed"))
            return (false, "Seul un rendez-vous en attente ou confirmé peut être annulé.");

        if (rendezVous.Creneau != null && rendezVous.Creneau.StartTime <= DateTime.UtcNow)
            return (false, "Impossible d'annuler un rendez-vous déjà passé ou en cours.");

        rendezVous.Status = "cancelled";
        rendezVous.UpdatedAt = DateTime.UtcNow;

        if (rendezVous.Creneau != null)
            rendezVous.Creneau.IsAvailable = true;

        await _context.SaveChangesAsync();

        if (rendezVous.Prestataire?.UserId != null)
        {
            var formattedTime = rendezVous.Creneau != null
                ? rendezVous.Creneau.StartTime.ToLocalTime().ToString("dd/MM/yyyy HH:mm")
                : "la date prévue";

            await CreateNotificationAsync(
                rendezVous.Prestataire.UserId,
                "Rendez-vous annulé",
                $"Un client a annulé son rendez-vous du {formattedTime}.",
                "BookingCancelled"
            );
        }

        return (true, "Rendez-vous annulé.");
    }
    private async Task CreateNotificationAsync(Guid userId, string title, string message, string type)
    {
        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = title,
            Message = message,
            Type = type,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
    }
}