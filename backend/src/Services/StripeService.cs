using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Stripe;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class StripeService : IStripeService
    {
        private readonly string? _secretKey;
        private readonly string? _webhookSecret;

        public StripeService(IConfiguration configuration)
        {
            _secretKey = configuration["STRIPE_SECRET_KEY"] ?? Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
            _webhookSecret = configuration["STRIPE_WEBHOOK_SECRET"] ?? Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET");
            PublishableKey = configuration["STRIPE_PUBLISHABLE_KEY"] ?? Environment.GetEnvironmentVariable("STRIPE_PUBLISHABLE_KEY") ?? string.Empty;

            if (!string.IsNullOrWhiteSpace(_secretKey))
            {
                StripeConfiguration.ApiKey = _secretKey;
            }
        }

        public bool IsConfigured => !string.IsNullOrWhiteSpace(_secretKey);
        public string PublishableKey { get; }

        private void EnsureConfigured()
        {
            if (!IsConfigured)
                throw new InvalidOperationException("Stripe is not configured. Set STRIPE_SECRET_KEY in the environment.");
        }

        public async Task<PaymentIntent> CreatePaymentIntentAsync(decimal amount, string currency, string reference, string receiptEmail)
        {
            EnsureConfigured();

            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)Math.Round(amount * 100, MidpointRounding.AwayFromZero),
                Currency = currency.ToLowerInvariant(),
                ReceiptEmail = receiptEmail,
                Metadata = new Dictionary<string, string>
                {
                    { "reference", reference }
                },
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                },
            };

            var service = new PaymentIntentService();
            return await service.CreateAsync(options);
        }

        public async Task<PaymentIntent> GetPaymentIntentAsync(string paymentIntentId)
        {
            EnsureConfigured();
            var service = new PaymentIntentService();
            return await service.GetAsync(paymentIntentId);
        }

        public Event ConstructWebhookEvent(string json, string signatureHeader)
        {
            if (string.IsNullOrWhiteSpace(_webhookSecret))
                throw new InvalidOperationException("Stripe webhook secret is not configured.");

            return EventUtility.ConstructEvent(json, signatureHeader, _webhookSecret);
        }

        public async Task<Refund> CreateRefundAsync(string paymentIntentId, decimal? amount, string currency)
        {
            EnsureConfigured();

            var options = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId,
            };
            if (amount.HasValue)
            {
                options.Amount = (long)Math.Round(amount.Value * 100, MidpointRounding.AwayFromZero);
            }

            var service = new RefundService();
            return await service.CreateAsync(options);
        }
    }
}
