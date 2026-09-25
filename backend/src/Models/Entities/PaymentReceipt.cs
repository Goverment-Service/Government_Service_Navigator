using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // A bank transfer / deposit slip a citizen uploaded for an installment. Kept apart from Installment
    // so loading a plan never pulls file bytes.
    public class PaymentReceipt
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public int InstallmentId { get; set; }

        public string FileName { get; set; } = string.Empty;
        public string ContentType { get; set; } = "application/octet-stream";
        public long SizeBytes { get; set; }
        public byte[] Content { get; set; } = Array.Empty<byte>();

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}
