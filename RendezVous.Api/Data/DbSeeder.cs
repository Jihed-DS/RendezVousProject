using Microsoft.EntityFrameworkCore;
using RendezVous.Data;
using RendezVous.Data.Entities;
using System.Numerics;

namespace RendezVous.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        if (await context.Categories.AnyAsync()) return;

        var passwordHash = BCrypt.Net.BCrypt.HashPassword("Test123!");
        var now = DateTime.UtcNow;
        var today = now.Date;
        var rng = new Random(42); // seed fixe : données reproductibles à chaque reset

        // === Admin ===
        var admin = new User
        {
            Email = "admin@rendezvous.local",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("ChangeMeNow!2026"),
            Role = "Admin",
            FullName = "Super Admin"
        };
        await context.Users.AddAsync(admin);

        // === Categories (7 secteurs distincts) ===
        var categoriesData = new (string Name, string Description)[]
        {
            ("Coiffure", "Services de coiffure et soins capillaires"),
            ("Santé", "Consultations bien-être, nutrition et suivi santé"),
            ("Consulting", "Accompagnement professionnel et conseil en entreprise"),
            ("Sport", "Coaching sportif et suivi personnalisé"),
            ("Éducation", "Soutien scolaire et cours particuliers"),
            ("Photographie", "Prestations photo : événements, portraits, produits"),
            ("Juridique", "Consultations juridiques et accompagnement légal"),
        };

        var categories = categoriesData
            .Select(c => new Categorie { Name = c.Name, Description = c.Description })
            .ToList();
        await context.Categories.AddRangeAsync(categories);
        await context.SaveChangesAsync();

        // === Bios par catégorie (variantes cycliques) ===
        var bioTemplates = new Dictionary<string, string[]>
        {
            ["Coiffure"] = new[] {
                "Coiffeur(se) professionnel(le) spécialisé(e) en coupes modernes.",
                "Expert(e) en coloration et soins capillaires depuis plusieurs années.",
                "Passionné(e) de coiffure, à l'écoute de chaque client(e)."
            },
            ["Santé"] = new[] {
                "Praticien(ne) certifié(e), suivi personnalisé et bienveillant.",
                "Spécialiste en nutrition et bien-être global.",
                "Accompagnement santé sur-mesure, à l'écoute de vos besoins."
            },
            ["Consulting"] = new[] {
                "Consultant(e) expérimenté(e) en stratégie et développement.",
                "Accompagnement professionnel pour entrepreneurs et PME.",
                "Expert(e) en organisation et transformation d'entreprise."
            },
            ["Sport"] = new[] {
                "Coach sportif certifié(e), préparation physique sur-mesure.",
                "Suivi personnalisé, remise en forme et performance.",
                "Passionné(e) de sport, coaching individuel ou en groupe."
            },
            ["Éducation"] = new[] {
                "Enseignant(e) expérimenté(e), cours particuliers tous niveaux.",
                "Soutien scolaire personnalisé, pédagogie adaptée.",
                "Accompagnement académique pour progresser sereinement."
            },
            ["Photographie"] = new[] {
                "Photographe professionnel(le), événements et portraits.",
                "Spécialiste en photographie de mariage et famille.",
                "Créatif(ve) et rigoureux(se), rendu de qualité garanti."
            },
            ["Juridique"] = new[] {
                "Consultant(e) juridique, conseils clairs et accessibles.",
                "Accompagnement légal pour particuliers et entreprises.",
                "Expert(e) en droit, à l'écoute de vos problématiques."
            },
        };

        // === Pool de noms (56 prestataires nécessaires) ===
        var firstNames = new[] {
            "Amira","Sami","Yassine","Salma","Karim","Nour","Sarra","Ahmed",
            "Fatma","Walid","Rania","Mehdi","Ines","Bilel","Emna","Hatem",
            "Mariem","Anis","Sirine","Nizar","Asma","Khalil","Dorra","Zied",
            "Wafa","Amine","Nadia","Fares","Rim","Skander","Lobna","Chedi",
            "Sana","Marwen","Houda","Ayoub","Meriem","Slim","Yosra","Adel",
            "Feryel","Bassem","Rahma","Wassim","Manel","Hichem","Olfa","Tarek",
            "Ghofrane","Aymen","Syrine","Fahmi","Nesrine","Souhail","Amel","Ramzi"
        };
        var lastNames = new[] {
            "Trabelsi","Ferjani","Gharbi","Bouaziz","Khadhraoui","Ben Youssef","Jlassi","Chaabane",
            "Mansouri","Hamdi","Riahi","Sassi","Baccouche","Karray","Lahmar","Toumi",
            "Bouzid","Ayari","Guesmi","Rekik","Cherni","Dridi","Fendri","Gharsallah",
            "Hajji","Jaziri","Kammoun","Landolsi","Mabrouk","Nasri","Omrani","Rouissi",
            "Sahraoui","Tlili","Werfelli","Zouari","Belhaj","Chtioui","Douik","Ellouze",
            "Frini","Gouider","Hentati","Ibrahim","Jendoubi","Kchaou","Limam","Melki",
            "Nefzi","Ouertani","Ben Salah","Selmi","Turki","Yahyaoui","Zribi","Abidi"
        };

        var prestataireUsers = new List<User>();
        var prestataireCategoryIndex = new List<int>();
        int nameIndex = 0;

        for (int catIdx = 0; catIdx < categories.Count; catIdx++)
        {
            var slug = categories[catIdx].Name.ToLower()
                .Replace("é", "e").Replace("è", "e").Replace(" ", "");

            for (int i = 0; i < 8; i++)
            {
                var first = firstNames[nameIndex % firstNames.Length];
                var last = lastNames[nameIndex % lastNames.Length];
                nameIndex++;

                prestataireUsers.Add(new User
                {
                    Email = $"presta.{slug}{i + 1}@test.com",
                    PasswordHash = passwordHash,
                    Role = "Prestataire",
                    FullName = $"{first} {last}",
                    Phone = $"2{rng.Next(1000000, 9999999)}",
                    ApprovalStatus = "approved"
                });
                prestataireCategoryIndex.Add(catIdx);
            }
        }
        await context.Users.AddRangeAsync(prestataireUsers);

        // === Clients (10, pour répartir les réservations) ===
        var clientFirstNames = new[] { "Leila", "Sofien", "Hela", "Mounir", "Yasmine", "Aziz", "Nadia", "Wael", "Rania", "Adel" };
        var clientUsers = new List<User>();
        for (int i = 0; i < 10; i++)
        {
            clientUsers.Add(new User
            {
                Email = $"client{i + 1}@test.com",
                PasswordHash = passwordHash,
                Role = "Client",
                FullName = $"{clientFirstNames[i]} {lastNames[(i + 30) % lastNames.Length]}",
                Phone = $"9{rng.Next(1000000, 9999999)}",               
                ApprovalStatus = "approved"
            });
        }
        await context.Users.AddRangeAsync(clientUsers);
        await context.SaveChangesAsync();

        // === Clients (entités) ===
        var clientCities = new[] { "Tunis", "Sousse", "Sfax", "Nabeul", "Bizerte", "Monastir", "Gabès", "Kairouan", "Ariana", "Mahdia" };
        var clients = new List<Client>();
        for (int i = 0; i < clientUsers.Count; i++)
        {
            clients.Add(new Client { UserId = clientUsers[i].Id, Address = $"{clientCities[i]}, Tunisie" });
        }
        await context.Clients.AddRangeAsync(clients);
        await context.SaveChangesAsync();

        // === Prestataires (une Categorie chacun) ===
        var prestataires = new List<Prestataire>();
        for (int i = 0; i < prestataireUsers.Count; i++)
        {
            var catIdx = prestataireCategoryIndex[i];
            var catName = categories[catIdx].Name;
            var bios = bioTemplates[catName];
            var prestataireCities = new[] { "Tunis", "Sousse", "Sfax", "Nabeul", "Bizerte", "Monastir", "Gabès", "Kairouan", "Ariana", "Mahdia" };
            prestataires.Add(new Prestataire
            {
                UserId = prestataireUsers[i].Id,
                Bio = bios[i % bios.Length],
                CategorieId = categories[catIdx].Id,
                City = prestataireCities[rng.Next(prestataireCities.Length)]
            });
        }
        await context.Prestataires.AddRangeAsync(prestataires);
        await context.SaveChangesAsync();

        // === Tags par catégorie (pour les créneaux) ===
        var tagPools = new Dictionary<string, string[]>
        {
            ["Coiffure"] = new[] { "Coupe", "Brushing", "Coloration" },
            ["Santé"] = new[] { "Bilan nutritionnel", "Suivi bien-être", "Consultation initiale" },
            ["Consulting"] = new[] { "Stratégie d'entreprise", "Bilan de compétences" },
            ["Sport"] = new[] { "Coaching individuel", "Préparation physique" },
            ["Éducation"] = new[] { "Soutien scolaire", "Préparation examen" },
            ["Photographie"] = new[] { "Séance portrait", "Événement" },
            ["Juridique"] = new[] { "Consultation initiale", "Suivi de dossier" },
        };

        // === Pools de commentaires par palier de note ===
        var commentsByTier = new Dictionary<int, string[]>
        {
            [5] = new[] {
        "Excellent service, je recommande vivement !",
        "Professionnel(le), à l'écoute, résultat parfait.",
        "Rien à redire, une vraie expertise.",
        "Très satisfait(e), je reviendrai sans hésiter."
    },
            [4] = new[] {
        "Très bon service dans l'ensemble.",
        "Bonne prestation, quelques petits détails à améliorer.",
        "Content(e) du résultat, ponctuel(le) et sérieux(se).",
        "Bon rapport qualité-prix, je recommande."
    },
            [3] = new[] {
        "Correct, sans plus.",
        "Prestation moyenne, peut mieux faire.",
        "Ça s'est bien passé mais rien d'exceptionnel.",
        "Satisfaisant, mais j'attendais un peu mieux."
    },
            [2] = new[] {
        "Un peu déçu(e), communication à améliorer.",
        "Retard important, prestation moyenne.",
        "Pas totalement satisfait(e) du résultat."
    },
        };

        // === Créneaux, RendezVous et Avis (1 à 3 avis variés par prestataire) ===
        var allCreneaux = new List<Creneau>();
        var allAppointments = new List<RendezVousEntity>();

        for (int i = 0; i < prestataires.Count; i++)
        {
            var catName = categories[prestataireCategoryIndex[i]].Name;
            var tags = tagPools[catName];
            var prestataire = prestataires[i];

            int reviewCount = rng.Next(10, 21); // 1 à 3 avis
            for (int r = 0; r < reviewCount; r++)
            {
                var daysAgo = rng.Next(3, 60);
                var pastCreneau = new Creneau
                {
                    PrestataireId = prestataire.Id,
                    StartTime = today.AddDays(-daysAgo).AddHours(rng.Next(9, 17)),
                    EndTime = today.AddDays(-daysAgo).AddHours(rng.Next(9, 17) + 1),
                    IsAvailable = false
                };
                pastCreneau.Tags.Add(new CreneauTag { Label = tags[rng.Next(tags.Length)] });
                allCreneaux.Add(pastCreneau);

                var client = clients[rng.Next(clients.Count)];
                var completedRdv = new RendezVousEntity
                {
                    ClientId = client.Id,
                    PrestataireId = prestataire.Id,
                    CreneauId = pastCreneau.Id,
                    Status = "completed",
                    Notes = "Rendez-vous effectué",
                    CreatedAt = pastCreneau.StartTime.AddDays(-2),
                    UpdatedAt = pastCreneau.StartTime
                };
                allAppointments.Add(completedRdv);
            }

            // Un créneau futur réservé (pending/confirmed) et un libre, comme avant
            var futureBookedCreneau = new Creneau
            {
                PrestataireId = prestataire.Id,
                StartTime = today.AddDays(2 + i % 7).AddHours(9 + i % 6),
                EndTime = today.AddDays(2 + i % 7).AddHours(10 + i % 6),
                IsAvailable = false
            };
            futureBookedCreneau.Tags.Add(new CreneauTag { Label = tags[(i + 1) % tags.Length] });
            allCreneaux.Add(futureBookedCreneau);

            var futureFreeCreneau = new Creneau
            {
                PrestataireId = prestataire.Id,
                StartTime = today.AddDays(4 + i % 7).AddHours(11 + i % 5),
                EndTime = today.AddDays(4 + i % 7).AddHours(12 + i % 5),
                IsAvailable = true
            };
            futureFreeCreneau.Tags.Add(new CreneauTag { Label = tags[i % tags.Length] });
            allCreneaux.Add(futureFreeCreneau);
        }
        await context.Creneaux.AddRangeAsync(allCreneaux);
        await context.SaveChangesAsync();

        // Récupère les créneaux "futurs réservés" pour créer les RendezVous pending/confirmed restants
        for (int i = 0; i < prestataires.Count; i++)
        {
            var prestataireId = prestataires[i].Id;
            var futureBookedCreneau = allCreneaux
                .Where(c => c.PrestataireId == prestataireId && !c.IsAvailable && c.StartTime > now)
                .OrderBy(c => c.StartTime)
                .First();

            var client = clients[rng.Next(clients.Count)];
            var status = rng.Next(3) == 0 ? "pending" : "confirmed";
            allAppointments.Add(new RendezVousEntity
            {
                ClientId = client.Id,
                PrestataireId = prestataireId,
                CreneauId = futureBookedCreneau.Id,
                Status = status,
                Notes = status == "pending" ? "En attente de confirmation" : "Rendez-vous confirmé",
                CreatedAt = now.AddDays(-1),
                UpdatedAt = status == "confirmed" ? now : null
            });
        }

        await context.Appointments.AddRangeAsync(allAppointments);
        await context.SaveChangesAsync();

        // === Avis (un par RendezVous "completed") + Notifications ===
        var allAvis = new List<Avis>();
        var allNotifications = new List<Notification>();

        foreach (var rdv in allAppointments.Where(r => r.Status == "completed"))
        {
            int rating = rng.Next(100) switch
            {
                < 5 => 2,   // 5% d'avis négatifs
                < 20 => 3,  // 15% neutres
                < 55 => 4,  // 35% bons
                _ => 5      // 45% excellents
            };
            var comments = commentsByTier[rating];

            allAvis.Add(new Avis
            {
                ClientId = rdv.ClientId,
                PrestataireId = rdv.PrestataireId,
                AppointmentId = rdv.Id,
                Rating = rating,
                Comment = comments[rng.Next(comments.Length)],
                CreatedAt = rdv.UpdatedAt ?? rdv.CreatedAt
            });
        }

        foreach (var rdv in allAppointments.Where(r => r.Status is "pending" or "confirmed"))
        {
            var prestataireUser = prestataireUsers[prestataires.FindIndex(p => p.Id == rdv.PrestataireId)];
            var clientUser = clientUsers[clients.FindIndex(c => c.Id == rdv.ClientId)];

            allNotifications.Add(new Notification
            {
                UserId = prestataireUser.Id,
                Title = "New Booking Request",
                Message = $"{clientUser.FullName} a demandé un rendez-vous.",
                Type = "BookingRequest",
                CreatedAt = rdv.CreatedAt,
                IsRead = rng.Next(2) == 0
            });

            if (rdv.Status == "confirmed")
            {
                allNotifications.Add(new Notification
                {
                    UserId = clientUser.Id,
                    Title = "Booking Confirmed!",
                    Message = $"{prestataireUser.FullName} a confirmé votre rendez-vous.",
                    Type = "BookingConfirmed",
                    CreatedAt = now,
                    IsRead = false
                });
            }
        }

        await context.Avis.AddRangeAsync(allAvis);
        await context.Notifications.AddRangeAsync(allNotifications);
        await context.SaveChangesAsync();

        // === Moyennes de notation ===
        foreach (var prestataire in prestataires)
        {
            var ratings = allAvis.Where(a => a.PrestataireId == prestataire.Id).Select(a => a.Rating).ToList();
            if (ratings.Count > 0)
            {
                prestataire.RatingAvg = (decimal)ratings.Average();
                prestataire.TotalReviews = ratings.Count;
            }
        }
        await context.SaveChangesAsync();

        Console.WriteLine(
            $"Database seeded — Admin, {categories.Count} Categories, {prestataires.Count} Prestataires (8/catégorie), " +
            $"{clients.Count} Clients, {allCreneaux.Count} Creneaux, {allAppointments.Count} RendezVous, " +
            $"{allAvis.Count} Avis, {allNotifications.Count} Notifications."
        );
    }
}