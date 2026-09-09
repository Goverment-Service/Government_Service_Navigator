using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class VerificationDecisionRequest
    {
        [Required(ErrorMessage = "Status is required.")]
        [RegularExpression("^(Approved|Rejected|Revised)$", ErrorMessage = "Status must be Approved, Rejected, or Revised.")]
        public string Status { get; set; } = string.Empty;

        public string? Comments { get; set; }
        
        public int? RejectionReasonId { get; set; } 
    }
}
