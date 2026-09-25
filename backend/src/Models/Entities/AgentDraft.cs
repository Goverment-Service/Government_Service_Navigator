using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    // Latest Action/Tool Agent (Agent 3) output for a submitted application, shown to the
    // Verifying Officer. Stored so the proposed appointment slot stays stable between views.
    public class AgentDraft
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }

        // Serialized AgentDraftView (eligibility summary + ActionDraftResponse)
        public string DraftJson { get; set; } = "{}";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
