using System.ComponentModel.DataAnnotations;
namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class UpdateOfficerRequest 
    {
        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        public string Department { get; set; } = string.Empty;

        [Required]
        public string Role { get; set; } = string.Empty;
    }
}