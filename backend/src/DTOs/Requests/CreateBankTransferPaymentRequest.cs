using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    // Multipart/form-data: the payment slip is uploaded together with the
    // payment details in a single request.
    public class CreateBankTransferPaymentRequest
    {
        public string? ApplicationId { get; set; }

        [Required]
        public string ServiceName { get; set; } = string.Empty;

        [Required]
        [Range(0.01, double.MaxValue)]
        public decimal Amount { get; set; }

        [Required]
        public string BankName { get; set; } = string.Empty;

        [Required]
        public string BranchName { get; set; } = string.Empty;

        [Required]
        public string AccountNumber { get; set; } = string.Empty;

        [Required]
        public string ReferenceNumber { get; set; } = string.Empty;

        [Required]
        public DateTime PaymentDate { get; set; }

        [Required]
        public IFormFile Slip { get; set; } = null!;
    }
}
