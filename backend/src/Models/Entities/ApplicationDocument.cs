using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A document a citizen uploaded against one of their service's
    // DocumentRequirements while applying. DocumentRequirementId is kept
    // loose (nullable, no FK) since a requirement can be edited/removed from
    // the catalog later without invalidating documents already submitted
    // against it - DocumentName is snapshotted at upload time for that reason.
    public class ApplicationDocument
    {
        public int Id { get; set; }

        public int ServiceApplicationId { get; set; }
        public ServiceApplication? ServiceApplication { get; set; }

        public int? DocumentRequirementId { get; set; }
        public string DocumentName { get; set; } = string.Empty;

        public string FilePath { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}
