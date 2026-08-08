namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class UserDto
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string NicNumber { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public bool Success { get; set; }
        public string? Token { get; set; }
        public string? ErrorMessage { get; set; }
        public UserDto? User { get; set; }
    }
}
