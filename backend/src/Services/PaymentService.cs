using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class PaymentService : IPaymentService
    {
        private const long MaxSlipSizeBytes = 10 * 1024 * 1024; // 10 MB
        private static readonly string[] AllowedSlipExtensions = { ".jpg", ".jpeg", ".png", ".pdf" };

        // Payment statuses that represent recognized, refund-eligible revenue.
        private static readonly string[] PaidStatuses = { "Verified", "Paid" };

        private readonly AppDbContext _context;
        private readonly IEmailService _emailService;
        private readonly IStripeService _stripeService;
        private readonly IWebHostEnvironment _environment;
        private readonly IConfiguration _configuration;

        public PaymentService(
            AppDbContext context,
            IEmailService emailService,
            IStripeService stripeService,
            IWebHostEnvironment environment,
            IConfiguration configuration)
        {
            _context = context;
            _emailService = emailService;
            _stripeService = stripeService;
            _environment = environment;
            _configuration = configuration;
        }

        private string Currency => _configuration["PAYMENT_CURRENCY"] ?? Environment.GetEnvironmentVariable("PAYMENT_CURRENCY") ?? "USD";

        private static string GenerateReference() =>
            $"PAY-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}";

        private string SlipDirectory
        {
            get
            {
                var root = _environment.ContentRootPath;
                var dir = Path.Combine(root, "App_Data", "payment-slips");
                Directory.CreateDirectory(dir);
                return dir;
            }
        }

        // ---------------- Citizen-facing ----------------

        public async Task<PaymentDto> CreateBankTransferPaymentAsync(int userId, CreateBankTransferPaymentRequest request)
        {
            var user = await _context.Users.FindAsync(userId)
                ?? throw new InvalidOperationException("User not found.");

            if (request.Slip == null || request.Slip.Length == 0)
                throw new InvalidOperationException("A payment slip file is required.");
            if (request.Slip.Length > MaxSlipSizeBytes)
                throw new InvalidOperationException("The payment slip must be smaller than 10 MB.");

            var extension = Path.GetExtension(request.Slip.FileName).ToLowerInvariant();
            if (!AllowedSlipExtensions.Contains(extension))
                throw new InvalidOperationException("Only JPG, PNG, or PDF slips are accepted.");

            var payment = new Payment
            {
                TransactionReference = GenerateReference(),
                UserId = userId,
                ApplicationId = request.ApplicationId,
                ServiceName = request.ServiceName,
                Method = "BankTransfer",
                Amount = request.Amount,
                Currency = Currency,
                Status = "Pending",
                BankName = request.BankName,
                BranchName = request.BranchName,
                AccountNumber = request.AccountNumber,
                ReferenceNumber = request.ReferenceNumber,
                PaymentDate = DateTime.SpecifyKind(request.PaymentDate, DateTimeKind.Utc),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
            };

            var storedFileName = $"{Guid.NewGuid():N}{extension}";
            var fullPath = Path.Combine(SlipDirectory, storedFileName);
            await using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await request.Slip.CopyToAsync(stream);
            }

            payment.SlipFilePath = storedFileName;
            payment.SlipFileName = request.Slip.FileName;
            payment.SlipUploadedAt = DateTime.UtcNow;

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            await _emailService.SendBankTransferPendingEmailAsync(user, payment);

            return MapToDto(payment, user);
        }

        public async Task<StripeIntentDto> CreateStripeIntentAsync(int userId, CreateStripeIntentRequest request)
        {
            var user = await _context.Users.FindAsync(userId)
                ?? throw new InvalidOperationException("User not found.");

            var payment = new Payment
            {
                TransactionReference = GenerateReference(),
                UserId = userId,
                ApplicationId = request.ApplicationId,
                ServiceName = request.ServiceName,
                Method = "Stripe",
                Amount = request.Amount,
                Currency = Currency,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            var intent = await _stripeService.CreatePaymentIntentAsync(request.Amount, Currency, payment.TransactionReference, user.Email);
            payment.StripePaymentIntentId = intent.Id;
            await _context.SaveChangesAsync();

            return new StripeIntentDto
            {
                PaymentId = payment.Id,
                ClientSecret = intent.ClientSecret,
                PublishableKey = _stripeService.PublishableKey,
            };
        }

        public async Task<PaymentDto?> GetPaymentForUserAsync(int paymentId, int userId)
        {
            var payment = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .FirstOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId);
            return payment == null ? null : MapToDto(payment, payment.User);
        }

        public async Task<List<PaymentDto>> GetPaymentsForUserAsync(int userId)
        {
            var payments = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
            return payments.Select(p => MapToDto(p, p.User)).ToList();
        }

        public async Task<SlipFileResult?> GetSlipForUserAsync(int paymentId, int userId)
        {
            var payment = await _context.Payments.FirstOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId);
            if (payment == null) return null;
            return ReadSlipFromDisk(payment);
        }

        public async Task<RefundDto?> RequestRefundAsync(int paymentId, int userId, RequestRefundRequest request)
        {
            var payment = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .FirstOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId);
            if (payment == null) return null;

            if (!IsRefundEligible(payment))
                throw new InvalidOperationException("This payment is not eligible for a refund request.");

            var refund = new PaymentRefund
            {
                PaymentId = payment.Id,
                Status = "Requested",
                RequestToken = Guid.NewGuid().ToString("N"),
                RequestedAt = DateTime.UtcNow,
                Reason = request.Reason,
            };
            _context.PaymentRefunds.Add(refund);
            await _context.SaveChangesAsync();

            refund.RequestEmailSentAt = DateTime.UtcNow;
            await _emailService.SendRefundRequestEmailAsync(payment.User!, payment, refund);
            await _context.SaveChangesAsync();

            return MapRefundToDto(refund, payment);
        }

        // ---------------- Stripe webhook / confirmation ----------------

        public async Task HandleStripePaymentSucceededAsync(string paymentIntentId)
        {
            var payment = await _context.Payments.Include(p => p.User)
                .FirstOrDefaultAsync(p => p.StripePaymentIntentId == paymentIntentId);
            if (payment == null || payment.Status == "Paid") return;

            var intent = await _stripeService.GetPaymentIntentAsync(paymentIntentId);
            payment.Status = "Paid";
            payment.VerifiedAt = DateTime.UtcNow;
            payment.StripeChargeId = intent.LatestChargeId;
            payment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            await _emailService.SendPaymentConfirmationEmailAsync(payment.User!, payment);
        }

        public async Task<PaymentDto?> SyncStripePaymentAsync(int paymentId, int userId)
        {
            var payment = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .FirstOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId);
            if (payment == null || string.IsNullOrEmpty(payment.StripePaymentIntentId)) return null;

            if (payment.Status != "Paid")
            {
                var intent = await _stripeService.GetPaymentIntentAsync(payment.StripePaymentIntentId);
                if (intent.Status == "succeeded")
                {
                    payment.Status = "Paid";
                    payment.VerifiedAt = DateTime.UtcNow;
                    payment.StripeChargeId = intent.LatestChargeId;
                    payment.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                    await _emailService.SendPaymentConfirmationEmailAsync(payment.User!, payment);
                }
            }

            return MapToDto(payment, payment.User);
        }

        // ---------------- Public refund form ----------------

        public async Task<RefundFormViewDto?> GetRefundFormAsync(string token)
        {
            var refund = await _context.PaymentRefunds.Include(r => r.Payment)
                .FirstOrDefaultAsync(r => r.RequestToken == token);
            if (refund?.Payment == null) return null;

            return new RefundFormViewDto
            {
                TransactionReference = refund.Payment.TransactionReference,
                Amount = refund.Payment.Amount,
                Currency = refund.Payment.Currency,
                Status = refund.Status,
                AlreadySubmitted = refund.FormSubmittedAt != null,
            };
        }

        public async Task<bool> SubmitRefundFormAsync(string token, SubmitRefundFormRequest request)
        {
            var refund = await _context.PaymentRefunds.FirstOrDefaultAsync(r => r.RequestToken == token);
            if (refund == null || refund.FormSubmittedAt != null) return false;

            refund.AccountHolderName = request.AccountHolderName;
            refund.BankName = request.BankName;
            refund.BranchName = request.BranchName;
            refund.AccountNumber = request.AccountNumber;
            refund.Reason = request.Reason;
            refund.FormSubmittedAt = DateTime.UtcNow;
            refund.Status = "FormSubmitted";

            await _context.SaveChangesAsync();
            return true;
        }

        // ---------------- Finance Officer ----------------

        public async Task<List<PaymentDto>> GetAllPaymentsAsync(string? status, string? method, string? search)
        {
            var query = _context.Payments.Include(p => p.User).Include(p => p.Refund).AsQueryable();

            if (!string.IsNullOrWhiteSpace(status) && status != "All")
                query = query.Where(p => p.Status == status);
            if (!string.IsNullOrWhiteSpace(method) && method != "All")
                query = query.Where(p => p.Method == method);
            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim().ToLower();
                query = query.Where(p =>
                    p.TransactionReference.ToLower().Contains(term) ||
                    (p.ApplicationId != null && p.ApplicationId.ToLower().Contains(term)) ||
                    (p.User != null && (p.User.Email.ToLower().Contains(term) || p.User.FullName.ToLower().Contains(term))));
            }

            var payments = await query.OrderByDescending(p => p.CreatedAt).ToListAsync();
            return payments.Select(p => MapToDto(p, p.User)).ToList();
        }

        public async Task<List<PaymentDto>> GetPendingBankPaymentsAsync()
        {
            var payments = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .Where(p => p.Method == "BankTransfer" && p.Status == "Pending")
                .OrderBy(p => p.CreatedAt)
                .ToListAsync();
            return payments.Select(p => MapToDto(p, p.User)).ToList();
        }

        public async Task<List<PaymentDto>> GetStripePaymentsAsync()
        {
            var payments = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .Where(p => p.Method == "Stripe")
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
            return payments.Select(p => MapToDto(p, p.User)).ToList();
        }

        public async Task<PaymentDto?> GetPaymentByIdAsync(int paymentId)
        {
            var payment = await _context.Payments.Include(p => p.User).Include(p => p.Refund)
                .FirstOrDefaultAsync(p => p.Id == paymentId);
            return payment == null ? null : MapToDto(payment, payment.User);
        }

        public async Task<SlipFileResult?> GetSlipAsync(int paymentId)
        {
            var payment = await _context.Payments.FindAsync(paymentId);
            if (payment == null) return null;
            return ReadSlipFromDisk(payment);
        }

        public async Task<PaymentDto?> VerifyPaymentAsync(int paymentId, VerifyPaymentDecisionRequest request, string officerId)
        {
            var payment = await _context.Payments.Include(p => p.User)
                .FirstOrDefaultAsync(p => p.Id == paymentId);
            if (payment == null || payment.Method != "BankTransfer" || payment.Status != "Pending") return null;

            var decision = request.Decision;
            if (decision != "Verified" && decision != "Rejected")
                throw new InvalidOperationException("Decision must be 'Verified' or 'Rejected'.");

            var officerName = "Finance Officer";
            if (int.TryParse(officerId, out var officerIntId))
            {
                var officer = await _context.Officers.FindAsync(officerIntId);
                if (officer != null) officerName = officer.Name;
            }

            payment.Status = decision;
            payment.VerifiedAt = DateTime.UtcNow;
            payment.VerifiedByOfficerId = int.TryParse(officerId, out var oid) ? oid : null;
            payment.VerifiedByOfficerName = officerName;
            payment.VerificationNotes = request.Notes;
            payment.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            if (decision == "Verified" && payment.User != null)
            {
                await _emailService.SendPaymentConfirmationEmailAsync(payment.User, payment);
            }

            return MapToDto(payment, payment.User);
        }

        public async Task<List<PaymentLogBucketDto>> GetLogsAsync(string period)
        {
            var now = DateTime.UtcNow;
            var buckets = BuildBuckets(period, now);

            var recognized = await _context.Payments
                .Where(p => PaidStatuses.Contains(p.Status) && p.VerifiedAt != null)
                .Select(p => new { p.Method, p.Amount, p.VerifiedAt })
                .ToListAsync();

            var refunded = await _context.PaymentRefunds
                .Where(r => r.Status == "Approved" && r.ProcessedAt != null)
                .Select(r => new { r.RefundAmount, r.ProcessedAt })
                .ToListAsync();

            return buckets.Select(bucket =>
            {
                var inBucket = recognized.Where(p => p.VerifiedAt!.Value >= bucket.Start && p.VerifiedAt.Value <= bucket.End).ToList();
                var refundsInBucket = refunded.Where(r => r.ProcessedAt!.Value >= bucket.Start && r.ProcessedAt.Value <= bucket.End).ToList();

                return new PaymentLogBucketDto
                {
                    Label = bucket.Label,
                    PeriodStart = bucket.Start,
                    PeriodEnd = bucket.End,
                    Count = inBucket.Count,
                    BankTransferTotal = inBucket.Where(p => p.Method == "BankTransfer").Sum(p => p.Amount),
                    StripeTotal = inBucket.Where(p => p.Method == "Stripe").Sum(p => p.Amount),
                    RefundedTotal = refundsInBucket.Sum(r => r.RefundAmount ?? 0),
                    Total = inBucket.Sum(p => p.Amount),
                };
            }).ToList();
        }

        public async Task<List<RefundDto>> GetRefundRequestsAsync(string? status)
        {
            var query = _context.PaymentRefunds.Include(r => r.Payment).ThenInclude(p => p!.User).AsQueryable();
            if (!string.IsNullOrWhiteSpace(status) && status != "All")
                query = query.Where(r => r.Status == status);
            else
                query = query.Where(r => r.Status == "Requested" || r.Status == "FormSubmitted");

            var refunds = await query.OrderByDescending(r => r.RequestedAt).ToListAsync();
            return refunds.Select(r => MapRefundToDto(r, r.Payment!)).ToList();
        }

        public async Task<RefundDto?> GetRefundByIdAsync(int refundId)
        {
            var refund = await _context.PaymentRefunds.Include(r => r.Payment).ThenInclude(p => p!.User)
                .FirstOrDefaultAsync(r => r.Id == refundId);
            return refund == null ? null : MapRefundToDto(refund, refund.Payment!);
        }

        public async Task<RefundDto?> ProcessRefundAsync(int refundId, ProcessRefundRequest request, string officerId)
        {
            var refund = await _context.PaymentRefunds.Include(r => r.Payment).ThenInclude(p => p!.User)
                .FirstOrDefaultAsync(r => r.Id == refundId);
            if (refund == null || refund.Payment == null) return null;
            if (refund.Status == "Approved" || refund.Status == "Rejected")
                throw new InvalidOperationException("This refund request has already been processed.");

            var decision = request.Decision;
            if (decision != "Approved" && decision != "Rejected")
                throw new InvalidOperationException("Decision must be 'Approved' or 'Rejected'.");

            var officerName = "Finance Officer";
            if (int.TryParse(officerId, out var officerIntId))
            {
                var officer = await _context.Officers.FindAsync(officerIntId);
                if (officer != null) officerName = officer.Name;
            }

            var payment = refund.Payment;

            if (decision == "Approved")
            {
                var amount = request.RefundAmount ?? payment.Amount;

                if (payment.Method == "Stripe" && !string.IsNullOrEmpty(payment.StripePaymentIntentId) && _stripeService.IsConfigured)
                {
                    var stripeRefund = await _stripeService.CreateRefundAsync(payment.StripePaymentIntentId, amount, payment.Currency);
                    refund.StripeRefundId = stripeRefund.Id;
                }

                refund.RefundAmount = amount;
                payment.Status = amount >= payment.Amount ? "Refunded" : "PartiallyRefunded";
                payment.UpdatedAt = DateTime.UtcNow;
            }

            refund.Status = decision;
            refund.ProcessedAt = DateTime.UtcNow;
            refund.ProcessedByOfficerId = int.TryParse(officerId, out var oid) ? oid : null;
            refund.ProcessedByOfficerName = officerName;
            refund.ProcessingNotes = request.Notes;

            await _context.SaveChangesAsync();

            if (payment.User != null)
            {
                await _emailService.SendRefundProcessedEmailAsync(payment.User, payment, refund);
            }

            return MapRefundToDto(refund, payment);
        }

        public async Task<List<RefundDto>> GetRefundHistoryAsync()
        {
            var refunds = await _context.PaymentRefunds.Include(r => r.Payment).ThenInclude(p => p!.User)
                .Where(r => r.Status == "Approved" || r.Status == "Rejected")
                .OrderByDescending(r => r.ProcessedAt)
                .ToListAsync();
            return refunds.Select(r => MapRefundToDto(r, r.Payment!)).ToList();
        }

        // ---------------- Helpers ----------------

        private SlipFileResult? ReadSlipFromDisk(Payment payment)
        {
            if (string.IsNullOrEmpty(payment.SlipFilePath)) return null;
            var fullPath = Path.Combine(SlipDirectory, payment.SlipFilePath);
            if (!File.Exists(fullPath)) return null;

            var extension = Path.GetExtension(fullPath).ToLowerInvariant();
            var contentType = extension switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".pdf" => "application/pdf",
                _ => "application/octet-stream",
            };

            return new SlipFileResult
            {
                Bytes = File.ReadAllBytes(fullPath),
                ContentType = contentType,
                FileName = payment.SlipFileName ?? "slip" + extension,
            };
        }

        private static bool IsRefundEligible(Payment payment)
        {
            if (!PaidStatuses.Contains(payment.Status)) return false;
            if (payment.Refund != null) return false;
            if (payment.VerifiedAt == null) return false;
            return DateTime.UtcNow - payment.VerifiedAt.Value <= TimeSpan.FromDays(3);
        }

        private static PaymentDto MapToDto(Payment payment, User? user)
        {
            return new PaymentDto
            {
                Id = payment.Id,
                TransactionReference = payment.TransactionReference,
                UserId = payment.UserId,
                UserFullName = user?.FullName ?? string.Empty,
                UserEmail = user?.Email ?? string.Empty,
                ApplicationId = payment.ApplicationId,
                ServiceName = payment.ServiceName,
                Method = payment.Method,
                Amount = payment.Amount,
                Currency = payment.Currency,
                Status = payment.Status,
                BankName = payment.BankName,
                BranchName = payment.BranchName,
                AccountNumber = payment.AccountNumber,
                ReferenceNumber = payment.ReferenceNumber,
                PaymentDate = payment.PaymentDate,
                SlipFileName = payment.SlipFileName,
                SlipUploadedAt = payment.SlipUploadedAt,
                HasSlip = !string.IsNullOrEmpty(payment.SlipFilePath),
                StripePaymentIntentId = payment.StripePaymentIntentId,
                StripeReceiptUrl = payment.StripeReceiptUrl,
                VerifiedByOfficerName = payment.VerifiedByOfficerName,
                VerifiedAt = payment.VerifiedAt,
                VerificationNotes = payment.VerificationNotes,
                CreatedAt = payment.CreatedAt,
                RefundEligible = IsRefundEligible(payment),
                Refund = payment.Refund == null ? null : MapRefundToDto(payment.Refund, payment),
            };
        }

        private static RefundDto MapRefundToDto(PaymentRefund refund, Payment payment)
        {
            return new RefundDto
            {
                Id = refund.Id,
                PaymentId = refund.PaymentId,
                TransactionReference = payment.TransactionReference,
                UserFullName = payment.User?.FullName ?? string.Empty,
                UserEmail = payment.User?.Email ?? string.Empty,
                PaymentAmount = payment.Amount,
                Currency = payment.Currency,
                Status = refund.Status,
                RequestedAt = refund.RequestedAt,
                AccountHolderName = refund.AccountHolderName,
                BankName = refund.BankName,
                BranchName = refund.BranchName,
                AccountNumber = refund.AccountNumber,
                Reason = refund.Reason,
                FormSubmittedAt = refund.FormSubmittedAt,
                ProcessedByOfficerName = refund.ProcessedByOfficerName,
                ProcessedAt = refund.ProcessedAt,
                ProcessingNotes = refund.ProcessingNotes,
                RefundAmount = refund.RefundAmount,
            };
        }

        private record Bucket(string Label, DateTime Start, DateTime End);

        private static List<Bucket> BuildBuckets(string period, DateTime referenceDate)
        {
            var buckets = new List<Bucket>();
            var ref_ = referenceDate.Date;

            switch (period)
            {
                case "weekly":
                    var weekStart = StartOfWeek(ref_);
                    for (var i = 11; i >= 0; i--)
                    {
                        var start = weekStart.AddDays(-7 * i);
                        var end = start.AddDays(7).AddTicks(-1);
                        buckets.Add(new Bucket($"{start:MMM d} - {end:MMM d}", start, end));
                    }
                    break;
                case "monthly":
                    var anchor = new DateTime(ref_.Year, ref_.Month, 1);
                    for (var i = 11; i >= 0; i--)
                    {
                        var start = anchor.AddMonths(-i);
                        var end = start.AddMonths(1).AddTicks(-1);
                        buckets.Add(new Bucket($"{start:MMM yyyy}", start, end));
                    }
                    break;
                case "yearly":
                    for (var i = 4; i >= 0; i--)
                    {
                        var year = ref_.Year - i;
                        var start = new DateTime(year, 1, 1);
                        var end = new DateTime(year, 12, 31, 23, 59, 59, 999);
                        buckets.Add(new Bucket($"{year}", start, end));
                    }
                    break;
                default: // daily
                    for (var i = 13; i >= 0; i--)
                    {
                        var day = ref_.AddDays(-i);
                        var start = day;
                        var end = day.AddDays(1).AddTicks(-1);
                        buckets.Add(new Bucket($"{start:MMM d, yyyy}", start, end));
                    }
                    break;
            }

            return buckets.Select(b => new Bucket(b.Label, DateTime.SpecifyKind(b.Start, DateTimeKind.Utc), DateTime.SpecifyKind(b.End, DateTimeKind.Utc))).ToList();
        }

        private static DateTime StartOfWeek(DateTime date)
        {
            var diff = (7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7;
            return date.AddDays(-diff).Date;
        }
    }
}
