using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // In-app notification for a citizen (shown in the mobile app); also sent by email when SMTP is configured.
    public class CitizenNotification
    {
        public int Id { get; set; }

        // Addressed by NIC (citizen login claim) and/or email (payer email)
        public string CitizenNic { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;

        // "InstallmentReminder", "InstallmentOverdue", "ApplicationCancelled"
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;

        public int? ApplicationId { get; set; }
        public int? InstallmentPlanId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ReadAt { get; set; }
    }
}
