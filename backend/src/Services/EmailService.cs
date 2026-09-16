using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    // Sends transactional payment/refund emails over SMTP. Configuration is
    // read from SMTP_* environment variables (see .env.example). If SMTP is
    // not configured, emails are skipped with a warning instead of throwing -
    // payment verification must never fail just because mail delivery isn't
    // set up yet.
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        private string? Get(string key) => _configuration[key] ?? Environment.GetEnvironmentVariable(key);

        private bool IsConfigured =>
            !string.IsNullOrWhiteSpace(Get("SMTP_HOST")) &&
            !string.IsNullOrWhiteSpace(Get("SMTP_USER")) &&
            !string.IsNullOrWhiteSpace(Get("SMTP_PASSWORD"));

        private async Task SendAsync(string toEmail, string toName, string subject, string bodyHtml)
        {
            if (string.IsNullOrWhiteSpace(toEmail)) return;

            if (!IsConfigured)
            {
                _logger.LogWarning("SMTP is not configured; skipping email '{Subject}' to {Email}", subject, toEmail);
                return;
            }

            var host = Get("SMTP_HOST")!;
            var port = int.TryParse(Get("SMTP_PORT"), out var p) ? p : 587;
            var user = Get("SMTP_USER")!;
            var password = Get("SMTP_PASSWORD")!;
            var useSsl = !bool.TryParse(Get("SMTP_USE_SSL"), out var ssl) || ssl;
            var fromEmail = Get("SMTP_FROM_EMAIL") ?? user;
            var fromName = Get("SMTP_FROM_NAME") ?? "Government Service Navigator";

            using var message = new MailMessage
            {
                From = new MailAddress(fromEmail, fromName),
                Subject = subject,
                Body = bodyHtml,
                IsBodyHtml = true,
            };
            message.To.Add(new MailAddress(toEmail, toName));

            using var client = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, password),
                EnableSsl = useSsl,
            };

            try
            {
                await client.SendMailAsync(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email '{Subject}' to {Email}", subject, toEmail);
            }
        }

        public Task SendBankTransferPendingEmailAsync(User user, Payment payment)
        {
            var subject = $"Payment Pending Verification - {payment.TransactionReference}";
            var body = $@"
                <p>Dear {WebUtil.Escape(user.FullName)},</p>
                <p>We have received your bank transfer/deposit slip for payment <strong>{payment.TransactionReference}</strong>
                ({payment.ServiceName}) of <strong>{payment.Currency} {payment.Amount:N2}</strong>.</p>
                <p>Your payment status is now <strong>Pending Verification</strong>. A Finance Officer will review your
                uploaded slip and you will receive a confirmation email once it has been verified.</p>
                <p>Thank you.</p>";
            return SendAsync(user.Email, user.FullName, subject, body);
        }

        public Task SendPaymentConfirmationEmailAsync(User user, Payment payment)
        {
            var subject = $"Payment Confirmation & Receipt - {payment.TransactionReference}";
            var receiptLine = string.IsNullOrEmpty(payment.StripeReceiptUrl)
                ? ""
                : $"<p><a href=\"{payment.StripeReceiptUrl}\">View your Stripe receipt</a></p>";
            var body = $@"
                <p>Dear {WebUtil.Escape(user.FullName)},</p>
                <p>Your payment has been confirmed. Please find your receipt details below.</p>
                <table cellpadding=""6"" style=""border-collapse:collapse;border:1px solid #ccc"">
                  <tr><td><strong>Reference</strong></td><td>{payment.TransactionReference}</td></tr>
                  <tr><td><strong>Service</strong></td><td>{WebUtil.Escape(payment.ServiceName)}</td></tr>
                  <tr><td><strong>Amount</strong></td><td>{payment.Currency} {payment.Amount:N2}</td></tr>
                  <tr><td><strong>Method</strong></td><td>{payment.Method}</td></tr>
                  <tr><td><strong>Status</strong></td><td>{payment.Status}</td></tr>
                  <tr><td><strong>Date</strong></td><td>{(payment.VerifiedAt ?? payment.CreatedAt):yyyy-MM-dd HH:mm} UTC</td></tr>
                </table>
                {receiptLine}
                <p>Thank you for your payment.</p>";
            return SendAsync(user.Email, user.FullName, subject, body);
        }

        public Task SendRefundRequestEmailAsync(User user, Payment payment, PaymentRefund refund)
        {
            var baseUrl = Get("FRONTEND_BASE_URL") ?? "http://localhost:5173";
            var link = $"{baseUrl}/refunds/form/{refund.RequestToken}";
            var subject = $"Refund Request - {payment.TransactionReference}";
            var body = $@"
                <p>Dear {WebUtil.Escape(user.FullName)},</p>
                <p>We received your refund request for payment <strong>{payment.TransactionReference}</strong>
                ({payment.Currency} {payment.Amount:N2}).</p>
                <p>To proceed, please complete the refund form with your bank details using the link below:</p>
                <p><a href=""{link}"">{link}</a></p>
                <p>A Finance Officer will review your submission and process your refund.</p>";
            return SendAsync(user.Email, user.FullName, subject, body);
        }

        public Task SendRefundProcessedEmailAsync(User user, Payment payment, PaymentRefund refund)
        {
            var approved = string.Equals(refund.Status, "Approved", StringComparison.OrdinalIgnoreCase);
            var subject = approved
                ? $"Refund Processed - {payment.TransactionReference}"
                : $"Refund Request Update - {payment.TransactionReference}";
            var body = approved
                ? $@"<p>Dear {WebUtil.Escape(user.FullName)},</p>
                     <p>Your refund of <strong>{payment.Currency} {refund.RefundAmount:N2}</strong> for payment
                     {payment.TransactionReference} has been processed.</p>
                     <p>{WebUtil.Escape(refund.ProcessingNotes ?? "")}</p>"
                : $@"<p>Dear {WebUtil.Escape(user.FullName)},</p>
                     <p>Your refund request for payment {payment.TransactionReference} was not approved.</p>
                     <p>{WebUtil.Escape(refund.ProcessingNotes ?? "")}</p>";
            return SendAsync(user.Email, user.FullName, subject, body);
        }
    }

    internal static class WebUtil
    {
        public static string Escape(string? value) => System.Net.WebUtility.HtmlEncode(value ?? string.Empty);
    }
}
