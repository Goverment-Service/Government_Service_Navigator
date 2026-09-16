using System.Threading.Tasks;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IEmailService
    {
        Task SendBankTransferPendingEmailAsync(User user, Payment payment);
        Task SendPaymentConfirmationEmailAsync(User user, Payment payment);
        Task SendRefundRequestEmailAsync(User user, Payment payment, PaymentRefund refund);
        Task SendRefundProcessedEmailAsync(User user, Payment payment, PaymentRefund refund);
    }
}
