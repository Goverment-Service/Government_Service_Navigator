using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class VerificationTask
    {
        public int Id { get; set; }
        public int ApplicationId { get; set; }
        public string Status { get; set; } = "Pending"; // "Pending", "Approved", "Rejected", "Revised"
        public DateTime CreatedDate { get; set; }

        // NIC of the citizen who submitted the application; scopes the citizen's own view.
        public string? CitizenNic { get; set; }
        
        public ICollection<OfficerReview> Reviews { get; set; }
        public ICollection<ComplianceCheck> ComplianceChecks { get; set; }

        public int CurrentStage { get; set; } = 1;
        public int MaxStages { get; set; } = 1;

    }
}
