using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Responses;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly AppDbContext _context;

        public AnalyticsService(AppDbContext context)
        {
            _context = context;
        }

        private async Task<UsageAggregateDto> AggregateAsync(DateTime start, DateTime end, string periodLabel)
        {
            var stats = await _context.ServiceUsageStats
                .Where(s => s.Date >= start && s.Date < end)
                .ToListAsync();

            var totalApplications = stats.Sum(s => s.TotalApplications);
            var approved = stats.Sum(s => s.ApprovedCount);
            var rejected = stats.Sum(s => s.RejectedCount);
            var avgHours = stats.Any() ? stats.Average(s => s.AverageProcessingHours) : 0;

            return new UsageAggregateDto
            {
                Period = periodLabel,
                TotalApplications = totalApplications,
                ApprovedCount = approved,
                RejectedCount = rejected,
                AverageProcessingHours = Math.Round(avgHours, 2)
            };
        }

        public Task<UsageAggregateDto> GetDailyAsync(DateTime date)
        {
            var start = date.Date;
            var end = start.AddDays(1);
            return AggregateAsync(start, end, start.ToString("yyyy-MM-dd"));
        }

        public Task<UsageAggregateDto> GetWeeklyAsync(DateTime weekStart)
        {
            var start = weekStart.Date;
            var end = start.AddDays(7);
            return AggregateAsync(start, end, $"Week of {start:yyyy-MM-dd}");
        }

        public Task<UsageAggregateDto> GetMonthlyAsync(int year, int month)
        {
            var start = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
            var end = start.AddMonths(1);
            return AggregateAsync(start, end, start.ToString("yyyy-MM"));
        }

        public Task<UsageAggregateDto> GetYearlyAsync(int year)
        {
            var start = new DateTime(year, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            var end = start.AddYears(1);
            return AggregateAsync(start, end, year.ToString());
        }

        public async Task<ApprovalLikelihoodDto> GetApprovalLikelihoodAsync(int serviceProcedureId)
        {
            var stats = await _context.ServiceUsageStats
                .Where(s => s.ServiceProcedureId == serviceProcedureId)
                .ToListAsync();

            var totalDecided = stats.Sum(s => s.ApprovedCount + s.RejectedCount);
            var totalApproved = stats.Sum(s => s.ApprovedCount);

            // With no historical data yet, default to a neutral 50% rather than divide by zero.
            var likelihood = totalDecided > 0
                ? Math.Round((double)totalApproved / totalDecided * 100, 1)
                : 50.0;

            return new ApprovalLikelihoodDto
            {
                ServiceProcedureId = serviceProcedureId,
                ApprovalLikelihoodPercent = likelihood,
                SampleSize = totalDecided
            };
        }

        public async Task<ReportSnapshot> SaveSnapshotAsync(string title, string period, string dataJson, string generatedByEmail)
        {
            var snapshot = new ReportSnapshot
            {
                Title = title,
                Period = period,
                DataJson = dataJson,
                GeneratedByEmail = generatedByEmail,
                GeneratedDate = DateTime.UtcNow
            };

            _context.ReportSnapshots.Add(snapshot);
            await _context.SaveChangesAsync();

            return snapshot;
        }

        public async Task<List<ReportSnapshot>> ListSnapshotsAsync()
        {
            return await _context.ReportSnapshots
                .OrderByDescending(s => s.GeneratedDate)
                .ToListAsync();
        }

        public async Task DeleteSnapshotAsync(int id)
        {
            var snapshot = await _context.ReportSnapshots.FindAsync(id);

            if (snapshot == null)
            {
                throw new KeyNotFoundException($"Report snapshot {id} not found.");
            }

            _context.ReportSnapshots.Remove(snapshot);
            await _context.SaveChangesAsync();
        }
    }
}