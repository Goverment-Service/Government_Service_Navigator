using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateRefundRequestRequest
    {
        [Required]
        [MinLength(5, ErrorMessage = "Please provide a reason with at least 5 characters.")]
        public string Reason { get; set; } = string.Empty;
    }
}
