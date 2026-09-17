using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.DTOs.Responses
{
    public class InstallmentDto
    {
        public int Id { get; set; }
        public int InstallmentNumber { get; set; }
        public decimal Amount { get; set; }
        public DateTime DueDate { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime? PaidDate { get; set; }

        public static InstallmentDto FromEntity(Installment i) => new InstallmentDto
        {
            Id = i.Id,
            InstallmentNumber = i.InstallmentNumber,
            Amount = i.Amount,
            DueDate = i.DueDate,
            Status = i.Status,
            PaidDate = i.PaidDate
        };
    }

    public class InstallmentPlanResponseDto
    {
        public int Id { get; set; }
        public int PaymentId { get; set; }
        public int NumberOfInstallments { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
        public List<InstallmentDto> Installments { get; set; } = new();

        public static InstallmentPlanResponseDto FromEntity(InstallmentPlan p) => new InstallmentPlanResponseDto
        {
            Id = p.Id,
            PaymentId = p.PaymentId,
            NumberOfInstallments = p.NumberOfInstallments,
            TotalAmount = p.TotalAmount,
            Status = p.Status,
            Installments = p.Installments?.OrderBy(i => i.InstallmentNumber).Select(InstallmentDto.FromEntity).ToList() ?? new()
        };
    }
}