using System.Collections.Generic;
using System.Threading.Tasks;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public class SlipFileResult
    {
        public byte[] Bytes { get; set; } = System.Array.Empty<byte>();
        public string ContentType { get; set; } = "application/octet-stream";
        public string FileName { get; set; } = string.Empty;
    }

    public interface IPaymentService
    {
        // Citizen-facing
        Task<PaymentDto> CreateBankTransferPaymentAsync(int userId, CreateBankTransferPaymentRequest request);
        Task<StripeIntentDto> CreateStripeIntentAsync(int userId, CreateStripeIntentRequest request);
        Task<PaymentDto?> GetPaymentForUserAsync(int paymentId, int userId);
        Task<List<PaymentDto>> GetPaymentsForUserAsync(int userId);
        Task<SlipFileResult?> GetSlipForUserAsync(int paymentId, int userId);
        Task<RefundDto?> RequestRefundAsync(int paymentId, int userId, RequestRefundRequest request);

        // Stripe webhook / confirmation
        Task HandleStripePaymentSucceededAsync(string paymentIntentId);
        Task<PaymentDto?> SyncStripePaymentAsync(int paymentId, int userId);

        // Public refund form (token-based, no auth)
        Task<RefundFormViewDto?> GetRefundFormAsync(string token);
        Task<bool> SubmitRefundFormAsync(string token, SubmitRefundFormRequest request);

        // Finance Officer
        Task<List<PaymentDto>> GetAllPaymentsAsync(string? status, string? method, string? search);
        Task<List<PaymentDto>> GetPendingBankPaymentsAsync();
        Task<List<PaymentDto>> GetStripePaymentsAsync();
        Task<PaymentDto?> GetPaymentByIdAsync(int paymentId);
        Task<SlipFileResult?> GetSlipAsync(int paymentId);
        Task<PaymentDto?> VerifyPaymentAsync(int paymentId, VerifyPaymentDecisionRequest request, string officerId);
        Task<List<PaymentLogBucketDto>> GetLogsAsync(string period);

        Task<List<RefundDto>> GetRefundRequestsAsync(string? status);
        Task<RefundDto?> GetRefundByIdAsync(int refundId);
        Task<RefundDto?> ProcessRefundAsync(int refundId, ProcessRefundRequest request, string officerId);
        Task<List<RefundDto>> GetRefundHistoryAsync();
    }
}
