using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class RevokedToken
    {
        public int Id { get; set; }
        public string Jti { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateTime RevokedAt { get; set; } = DateTime.UtcNow;
    }
}
