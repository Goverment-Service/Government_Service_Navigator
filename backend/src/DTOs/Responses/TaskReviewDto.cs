using System;
using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class ReviewFieldDto
    {
        public string Id { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string? Options { get; set; }
        public bool IsRequired { get; set; }
        public int OrderIndex { get; set; }
    }

    public class ReviewPaymentDto
    {
        public string TransactionReference { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime? VerifiedAt { get; set; }
    }

    // Everything a Verifying Officer needs to review one task in a single
    // call: the real citizen submission (answers, form layout), any uploaded
    // documents, and a matching payment - instead of the officer workspace
    // showing placeholder/mock content.
    public class TaskReviewDto
    {
        public int TaskId { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime CreatedDate { get; set; }

        public int? ApplicationId { get; set; }
        public string? ApplicationReference { get; set; }
        public string? ServiceName { get; set; }
        public string? Department { get; set; }
        public string? CitizenName { get; set; }
        public string? CitizenEmail { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public Dictionary<string, string> Answers { get; set; } = new();

        public string? FormName { get; set; }
        public string? SubTitle { get; set; }
        public List<ReviewFieldDto> Fields { get; set; } = new();

        public List<ApplicationDocumentDto> Documents { get; set; } = new();

        public ReviewPaymentDto? Payment { get; set; }
    }
}
