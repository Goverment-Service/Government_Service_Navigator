using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IInstallmentPlanService
    {
        Task<InstallmentPlan> CreatePlanAsync(int paymentId, int numberOfInstallments, int intervalDays);
        Task<InstallmentPlanResponseDto?> GetByIdAsync(int id);
        Task<Installment> MarkInstallmentPaidAsync(int installmentId);
        Task<InstallmentPlan> CancelPlanAsync(int planId);

        // True when the installment's payment belongs to the citizen (by application NIC or payer email)
        Task<bool> BelongsToCitizenAsync(int installmentId, string? nic, string? email);

        // Online: Stripe Checkout for the installment amount, then confirm against Stripe
        Task<string> CreateOnlineCheckoutAsync(int installmentId);
        Task<Installment> ConfirmOnlineCheckoutAsync(int installmentId);

        // Bank transfer: citizen uploads the receipt; staff approve (MarkInstallmentPaidAsync) or reject it
        Task<Installment> SubmitBankTransferAsync(int installmentId, string fileName, string contentType, byte[] content);
        Task<Installment> RejectBankTransferAsync(int installmentId);
        Task<PaymentReceipt?> GetReceiptAsync(int installmentId);
    }
}
