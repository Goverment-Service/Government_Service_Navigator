using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IRefundService
    {
        Task<List<RefundRequest>> GetAllAsync(string? status);
        Task<RefundRequest> CreateRefundRequestAsync(int paymentId, decimal amount, string reason, string requestedByEmail);
        Task<RefundRequest?> GetRefundByIdAsync(int id);
        Task<RefundRequest> ApproveAsync(int id, string decidedByEmail, string? note);
        Task<RefundRequest> RejectAsync(int id, string decidedByEmail, string? note);
        Task<RefundRequest> ProcessAsync(int id, string transactionRef);
        Task<RefundRequest> CompleteAsync(int id);
        Task<List<RefundRequest>> GetByRequesterAsync(string email);
    }
}