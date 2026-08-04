using System;

namespace GSN.Domain.Entities {
    public enum UserRole {
        Citizen,
        VerifyingOfficer,
        DepartmentAdmin,
        SystemAdmin
    }
    public class User {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string? NicNumber { get; set; }
        public UserRole Role { get; set; } = UserRole.Citizen;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}