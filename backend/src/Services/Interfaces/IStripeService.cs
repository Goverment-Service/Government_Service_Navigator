using System.Threading.Tasks;
using Stripe;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IStripeService
    {
        bool IsConfigured { get; }
        string PublishableKey { get; }

        Task<PaymentIntent> CreatePaymentIntentAsync(decimal amount, string currency, string reference, string receiptEmail);
        Task<PaymentIntent> GetPaymentIntentAsync(string paymentIntentId);
        Event ConstructWebhookEvent(string json, string signatureHeader);
        Task<Refund> CreateRefundAsync(string paymentIntentId, decimal? amount, string currency);
    }
}
