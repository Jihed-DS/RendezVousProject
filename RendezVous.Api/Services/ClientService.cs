using Microsoft.EntityFrameworkCore;
using RendezVous.Api.DTOs;
using RendezVous.Data;
using RendezVous.Data.Entities;

namespace RendezVous.Api.Services;

public class ClientService
{
    private readonly ApplicationDbContext _context;

    public ClientService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<ClientResponseDto>> GetAllClientsAsync()
    {
        return await _context.Clients
            .Include(c => c.User)
            .Select(c => new ClientResponseDto
            {
                Id = c.Id,
                UserId = c.UserId,
                FullName = c.User.FullName ?? string.Empty,
                Email = c.User.Email,
                Phone = c.User.Phone,
                Address = c.Address,
                DateOfBirth = c.DateOfBirth
            })
            .ToListAsync();
    }
    public async Task<Client?> CreateClientAsync(Guid userId)
    {
        var alreadyExists = await _context.Clients.AnyAsync(c => c.UserId == userId);
        if (alreadyExists)
            return null; // signalera un conflit dans le controller

        var client = new Client
        {
            Id = Guid.NewGuid(),
            UserId = userId
        };

        _context.Clients.Add(client);
        await _context.SaveChangesAsync();

        return client;
    }
    public async Task<ClientResponseDto?> GetClientByIdAsync(Guid id)
    {
        return await _context.Clients
            .Include(c => c.User)
            .Where(c => c.Id == id)
            .Select(c => new ClientResponseDto
            {
                Id = c.Id,
                UserId = c.UserId,
                FullName = c.User.FullName ?? string.Empty,
                Email = c.User.Email,
                Phone = c.User.Phone,
                Address = c.Address,
                DateOfBirth = c.DateOfBirth
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ClientResponseDto?> GetClientByUserIdAsync(Guid userId)
    {
        return await _context.Clients
            .Include(c => c.User)
            .Where(c => c.UserId == userId)
            .Select(c => new ClientResponseDto
            {
                Id = c.Id,
                UserId = c.UserId,
                FullName = c.User.FullName ?? string.Empty,
                Email = c.User.Email,
                Phone = c.User.Phone,
                Address = c.Address,
                DateOfBirth = c.DateOfBirth
            })
            .FirstOrDefaultAsync();
    }

    public async Task<bool> UpdateClientAsync(Guid id, UpdateClientDto dto)
    {
        var client = await _context.Clients
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (client == null) return false;

        // Update fields on Client
        client.Address = dto.Address;
        client.DateOfBirth = dto.DateOfBirth;

        // Update fields on linked User entity
        client.User.FullName = dto.FullName;
        client.User.Phone = dto.Phone;

        await _context.SaveChangesAsync();
        return true;
    }
}