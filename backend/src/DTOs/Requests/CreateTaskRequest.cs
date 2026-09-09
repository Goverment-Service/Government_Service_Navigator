using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateTaskRequest
    {
        [Required(ErrorMessage = "ApplicationId is required.")]
        public int ApplicationId { get; set; }
    }
}
