using System;
namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Admin
    {
        public int Id { get; set; } 
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Role { get; set; } = "Admin"; // Default role
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}