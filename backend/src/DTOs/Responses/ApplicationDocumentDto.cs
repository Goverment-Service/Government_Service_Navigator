using System;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class ApplicationDocumentDto
    {
        public int Id { get; set; }
        public int ServiceApplicationId { get; set; }
        public int? DocumentRequirementId { get; set; }
        public string DocumentName { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; }
    }
}
