using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class ProcessRefundRequest
    {
        // "Approved" or "Rejected"
        [Required]
        public string Decision { get; set; } = string.Empty;

        public decimal? RefundAmount { get; set; }

        public string? Notes { get; set; }
    }
}
