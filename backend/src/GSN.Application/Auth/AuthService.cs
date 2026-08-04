using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using GSN.Domain.Entities;
using GSN.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace GSN.Application.Auth
{
    public class AuthService
    {
        private readonly GsnDbContext _db;

        public AuthService(GsnDbContext db)
        {
            _db = db;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            var existing = await _db.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (existing != null)
            {
                return new AuthResponse
                {
                    Success = false,
                    ErrorMessage = "An account with this email already exists."
                };
            }

            var user = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                NicNumber = request.NicNumber,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = UserRole.Citizen
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            var token = GenerateJwt(user);

            return new AuthResponse
            {
                Success = true,
                Token = token,
                User = MapToDto(user)
            };
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            var user = await _db.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return new AuthResponse
                {
                    Success = false,
                    ErrorMessage = "Invalid email or password."
                };
            }

            var token = GenerateJwt(user);

            return new AuthResponse
            {
                Success = true,
                Token = token,
                User = MapToDto(user)
            };
        }

        private string GenerateJwt(User user)
        {
            var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")!;
            var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER");
            var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE");
            var expiryHours = double.Parse(
                Environment.GetEnvironmentVariable("JWT_EXPIRY_HOURS") ?? "24");

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: jwtIssuer,
                audience: jwtAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddHours(expiryHours),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static UserDto MapToDto(User user) => new()
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role.ToString()
        };
    }
}