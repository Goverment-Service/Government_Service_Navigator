using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class VerifyPaymentDecisionRequest
    {
        // "Verified" or "Rejected"
        [Required]
        public string Decision { get; set; } = string.Empty;

        public string? Notes { get; set; }
    }
}
