using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Officer
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Role { get; set; } = "Officer"; // Default role
        public string Department { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty; // e.g., Active, Inactive
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}