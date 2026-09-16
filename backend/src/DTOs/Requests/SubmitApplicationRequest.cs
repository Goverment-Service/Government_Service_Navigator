using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class SubmitApplicationRequest
    {
        [Required]
        public int ServiceProcedureId { get; set; }

        // Keyed by FormField.Id (as string), value is the citizen's answer.
        public Dictionary<string, string>? Answers { get; set; }
    }
}
