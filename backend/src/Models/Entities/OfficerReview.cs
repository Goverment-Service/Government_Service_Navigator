using System;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class OfficerReview
    {
        public int Id { get; set; }
        public int TaskId { get; set; }
        public string OfficerId { get; set; }
        public DateTime ReviewDate { get; set; }
        public string Comments { get; set; }
        
        // Nullable because approval might not need a rejection reason
        public int? RejectionReasonId { get; set; } 
        
        public VerificationTask Task { get; set; }
        public RejectionReason RejectionReason { get; set; }
    }
}
