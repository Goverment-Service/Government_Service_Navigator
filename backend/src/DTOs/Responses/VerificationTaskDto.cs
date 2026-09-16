using System;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    // The queue/review list views need more than the bare VerificationTask -
    // officers need to see which real application (reference, service,
    // department) each task is actually for, not just the internal
    // ApplicationId. Resolved from the linked ServiceApplication when one
    // exists (citizen-submitted tasks); falls back gracefully for
    // legacy/manually-created tasks that predate that link.
    public class VerificationTaskDto
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public string? ApplicationReference { get; set; }
        public string? ServiceName { get; set; }
        public string? Department { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime CreatedDate { get; set; }
    }
}
