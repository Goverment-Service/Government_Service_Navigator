namespace Government_Service_Navigator.Backend.Models.Entities
{
    // Tracks the lifecycle of a refund request from creation to completion.
    public enum RefundStatus
    {
        Pending,
        Approved,
        Rejected,
        Processing,
        Completed,
        Failed
    }
}