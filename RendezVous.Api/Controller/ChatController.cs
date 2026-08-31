using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using System.IO;
using System.Security.Claims;
using System.Text;
using System.Text.Json;

namespace RendezVous.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _config;
    private readonly ApplicationDbContext _context;

    public ChatController(IHttpClientFactory httpClientFactory, IConfiguration config, ApplicationDbContext context)
    {
        _httpClientFactory = httpClientFactory;
        _config = config;
        _context = context;
    }

    [HttpPost("message")]
    public async Task<ActionResult<ChatReplyDto>> SendMessage([FromBody] SendChatDto dto)
    {
        if (dto.Messages.Count == 0)
            return BadRequest("Aucun message fourni.");

        if (dto.Messages.Count > 20)
            return BadRequest("Historique de conversation trop long.");

        var role = User.FindFirst(ClaimTypes.Role)?.Value ?? "Client";
        var fullName = User.FindFirst("FullName")?.Value;

        var systemPrompt = await BuildSystemPromptAsync(role, fullName);

        var apiKey = _config["Gemini:ApiKey"];
        var model = _config["Gemini:Model"] ?? "gemini-2.5-flash";

        if (string.IsNullOrEmpty(apiKey))
            return StatusCode(500, "Clé API non configurée côté serveur.");

        // Gemini utilise "user" et "model" comme rôles (pas "assistant").
        var contents = dto.Messages.Select(m => new
        {
            role = m.Role == "assistant" ? "model" : "user",
            parts = new[] { new { text = m.Content } }
        });

        var requestBody = new
        {
            contents,
            systemInstruction = new
            {
                parts = new[] { new { text = systemPrompt } }
            },
            generationConfig = new
            {
                maxOutputTokens = 1024,
                thinkingConfig = new { thinkingLevel = "low" }
            }
        };

        var client = _httpClientFactory.CreateClient("Gemini");
        var url = $"v1beta/models/{model}:generateContent";

        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-goog-api-key", apiKey);

        HttpResponseMessage response;
        try
        {
            response = await client.SendAsync(request);
        }
        catch (Exception)
        {
            return StatusCode(502, "Impossible de contacter le service de chat pour le moment.");
        }

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            return StatusCode(502, $"Erreur du service de chat: {errorBody}");
        }

        var responseBody = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseBody);

        var parts = doc.RootElement
                    .GetProperty("candidates")[0]
                    .GetProperty("content")
                    .GetProperty("parts");
        
        var replyText = string.Concat(
        parts.EnumerateArray()
                        .Where(p => p.TryGetProperty("text", out _))
                        .Select(p => p.GetProperty("text").GetString())
                );
        var finishReason = doc.RootElement
            .GetProperty("candidates")[0]
            .TryGetProperty("finishReason", out var fr) ? fr.GetString() : null;
        
                if (finishReason == "MAX_TOKENS")
                    {
            replyText += "\n\n[Réponse tronquée — pose une question plus courte ou reformule.]";
                    }

        return Ok(new ChatReplyDto { Reply = replyText });
    }

    private async Task<string> BuildSystemPromptAsync(string role, string? fullName)
    {
        var categoriesCount = await _context.Categories.CountAsync();
        var greeting = fullName != null ? $"L'utilisateur s'appelle {fullName}." : "";

        var baseIntro = $"""
            Tu es l'assistant intégré de RendezVous, une application tunisienne de prise de
            rendez-vous en ligne. Elle couvre {categoriesCount} secteurs (coiffure, santé,
            consulting, sport, éducation, photographie, juridique...). Les Clients cherchent
            des Prestataires par catégorie et localisation, consultent leurs avis, et réservent
            des créneaux horaires. Les Prestataires gèrent leurs disponibilités (créneaux, avec
            des sous-catégories libres qu'ils définissent eux-mêmes) et confirment ou refusent
            les demandes de rendez-vous. {greeting}

            Réponds toujours en français, de façon concise (2-4 phrases sauf si on te demande
            plus de détails), amicale et directement utile. Ne réponds qu'aux questions liées
            à l'application ou à des questions générales simples — si la question sort
            largement de ce cadre, réoriente poliment vers l'app.
            """;

        var roleContext = role switch
        {
            "Client" => """
                Cet utilisateur est un CLIENT. Il peut : parcourir les prestataires par catégorie,
                filtrer par ville et note minimum, consulter les avis, réserver un créneau
                disponible (avec une sous-catégorie optionnelle), suivre le statut de ses
                rendez-vous (en attente/confirmé/terminé/refusé), et laisser un avis une fois
                le service terminé.
                """,
            "Prestataire" => """
                Cet utilisateur est un PRESTATAIRE. Il peut : créer des créneaux (un par un ou
                en lot sur une plage horaire), y attacher des sous-catégories libres, confirmer
                ou refuser les demandes de rendez-vous reçues, marquer un rendez-vous confirmé
                comme terminé, et consulter les avis reçus (lecture seule).
                """,
            "Admin" => """
                Cet utilisateur est un ADMIN. Il peut : créer/modifier/supprimer les catégories
                principales de l'application, et consulter en lecture seule la liste des
                prestataires et des clients.
                """,
            _ => ""
        };

        return $"{baseIntro}\n\n{roleContext}";
    }
}