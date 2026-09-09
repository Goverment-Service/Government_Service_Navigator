using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class BulkVerifyRequest
    {
        [Required]
        [MinLength(1, ErrorMessage = "At least one TaskId must be provided.")]
        public List<int> TaskIds { get; set; } = new List<int>();

        [Required(ErrorMessage = "Status is required.")]
        [RegularExpression("^(Approved|Rejected|Revised)$", ErrorMessage = "Status must be Approved, Rejected, or Revised.")]
        public string Status { get; set; } = string.Empty;

        public string? Comments { get; set; }
    }
}
