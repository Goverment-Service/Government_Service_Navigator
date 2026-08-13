using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class AdminService : IAdminService 
    {
        private readonly AppDbContext _context;
        
        public AdminService(AppDbContext context) {
            _context = context;
        }

        public async Task<IEnumerable<OfficerDetailsDto>> GetAllOfficersAsync() {
            var officers = await _context.Officers.ToListAsync();
            return officers.Select(o => new OfficerDetailsDto {
                Id = o.Id.ToString(),
                Name = o.Name,
                Email = o.Email,
                Role = o.Role,
                Department = o.Department,
                Status = o.Status
            });
        }
        public async Task<AuthResponse> CreateOfficerAsync(CreateOfficerRequest request) {
            if (await _context.Officers.AnyAsync(o => o.Email == request.Email)) {
                return new AuthResponse {
                    Success = false,
                    ErrorMessage = "Officer with this email already exists."
                };
            }
            var officer = new Officer {
                Name = request.FullName,
                Email = request.Email,
                Role = request.Role,
                Department = request.Department,
                Status = "Active",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password) 
            };
            _context.Officers.Add(officer);
            await _context.SaveChangesAsync();

            return new AuthResponse {
                Success = true,
                Officer = new OfficerDto {
                    Email = officer.Email,
                    Role = officer.Role,
                }
            };
        }
    }
}