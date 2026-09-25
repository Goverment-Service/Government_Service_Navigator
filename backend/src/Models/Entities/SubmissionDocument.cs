using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A file a citizen uploaded for a "file" form field. Uploaded before submit (ApplicationId null),
    // then attached to the ApplicationSubmission when the form is submitted.
    public class SubmissionDocument
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public int? ApplicationId { get; set; }
        public string FieldLabel { get; set; } = string.Empty;

        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = "application/octet-stream";
        public long SizeBytes { get; set; }
        public byte[] Content { get; set; } = Array.Empty<byte>();

        // NIC of the citizen who uploaded it; only they can attach it to an application.
        public string UploaderNic { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}
