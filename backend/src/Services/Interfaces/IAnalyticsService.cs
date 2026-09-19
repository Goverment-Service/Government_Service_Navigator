using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IAnalyticsService
    {
        Task<UsageAggregateDto> GetDailyAsync(DateTime date);
        Task<UsageAggregateDto> GetWeeklyAsync(DateTime weekStart);
        Task<UsageAggregateDto> GetMonthlyAsync(int year, int month);
        Task<UsageAggregateDto> GetYearlyAsync(int year);
        Task<ApprovalLikelihoodDto> GetApprovalLikelihoodAsync(int serviceProcedureId);

        Task<ReportSnapshot> SaveSnapshotAsync(string title, string period, string dataJson, string generatedByEmail);
        Task<List<ReportSnapshot>> ListSnapshotsAsync();
        Task DeleteSnapshotAsync(int id);
    }
}