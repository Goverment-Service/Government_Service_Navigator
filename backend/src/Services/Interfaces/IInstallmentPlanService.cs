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
    }
}