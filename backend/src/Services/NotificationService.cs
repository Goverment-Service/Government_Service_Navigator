using System.Net;
using System.Net.Mail;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class NotificationService : INotificationService
    {
        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var host = Environment.GetEnvironmentVariable("SMTP_HOST");
            var portStr = Environment.GetEnvironmentVariable("SMTP_PORT");
            var user = Environment.GetEnvironmentVariable("SMTP_USER");
            var pass = Environment.GetEnvironmentVariable("SMTP_PASSWORD");
            var fromEmail = Environment.GetEnvironmentVariable("SMTP_FROM_EMAIL") ?? user;

            if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(user) || string.IsNullOrEmpty(pass))
            {
                // SMTP not configured yet — log instead of failing the whole request.
                Console.WriteLine($"[Notification skipped - SMTP not configured] To: {toEmail}, Subject: {subject}");
                return;
            }

            var port = int.TryParse(portStr, out var p) ? p : 587;

            using var client = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, pass),
                EnableSsl = true
            };

            using var message = new MailMessage(fromEmail!, toEmail, subject, body);

            try
            {
                await client.SendMailAsync(message);
            }
            catch (Exception ex)
            {
                // Don't let an email failure break the underlying business operation.
                Console.WriteLine($"[Notification failed] To: {toEmail}, Error: {ex.Message}");
            }
        }

        // Templates implemented in the next commit.
        public Task NotifyRefundStatusAsync(string toEmail, int refundId, string status, string? note)
        {
            throw new NotImplementedException();
        }

        public Task NotifyPaymentStatusAsync(string toEmail, int paymentId, string status)
        {
            throw new NotImplementedException();
        }
    }
}