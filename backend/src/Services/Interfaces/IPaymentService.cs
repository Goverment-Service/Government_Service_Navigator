using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<Payment> CreateManualPaymentAsync(int applicationId, decimal amount, string userEmail, string slipUrl);
        Task<Payment?> GetByIdAsync(int id);
        Task<Payment> VerifyManualPaymentAsync(int id, bool approved, string? note);
        Task<PaymentLedgerDto> GetLedgerAsync(int id);
        Task<(Payment payment, string checkoutUrl)> CreateStripeCheckoutAsync(int applicationId, decimal amount, string userEmail);    
        Task<Payment> ConfirmStripePaymentAsync(int paymentId); // for  testing in swagger
    }
}