using System.ComponentModel.DataAnnotations;
namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class ResetPasswordRequest
    {
        [Required]
        [MinLength(6)]
        public string NewPassword { get; set; } = string.Empty;
    }
}