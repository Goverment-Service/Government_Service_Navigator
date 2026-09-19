using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class ResolveFlagRequest
    {
        // Allowed values: "Reviewed", "Dismissed"
        [Required]
        public string Status { get; set; } = string.Empty;
    }
}
