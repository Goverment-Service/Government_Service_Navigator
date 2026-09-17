using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api")]
    public class AnalyticsController : ControllerBase
    {
        private readonly IAnalyticsService _analyticsService;
        private readonly IAnomalyDetectionService _anomalyService;

        public AnalyticsController(IAnalyticsService analyticsService, IAnomalyDetectionService anomalyService)
        {
            _analyticsService = analyticsService;
            _anomalyService = anomalyService;
        }

        [HttpGet("analytics/daily")]
        [Authorize]
        public async Task<IActionResult> GetDaily([FromQuery] DateTime? date)
        {
            var result = await _analyticsService.GetDailyAsync(date ?? DateTime.UtcNow);
            return Ok(result);
        }

        [HttpGet("analytics/weekly")]
        [Authorize]
        public async Task<IActionResult> GetWeekly([FromQuery] DateTime? weekStart)
        {
            var result = await _analyticsService.GetWeeklyAsync(weekStart ?? DateTime.UtcNow.AddDays(-7));
            return Ok(result);
        }

        [HttpGet("analytics/monthly")]
        [Authorize]
        public async Task<IActionResult> GetMonthly([FromQuery] int year, [FromQuery] int month)
        {
            var result = await _analyticsService.GetMonthlyAsync(year, month);
            return Ok(result);
        }

        [HttpGet("analytics/yearly")]
        [Authorize]
        public async Task<IActionResult> GetYearly([FromQuery] int year)
        {
            var result = await _analyticsService.GetYearlyAsync(year);
            return Ok(result);
        }

        [HttpPost("report-snapshots")]
        [Authorize]
        public async Task<IActionResult> SaveSnapshot([FromBody] SaveReportSnapshotDto dto)
        {
            var email = User.Identity?.Name ?? "unknown@officer";
            var snapshot = await _analyticsService.SaveSnapshotAsync(dto.Title, dto.Period, dto.DataJson, email);
            return Ok(snapshot);
        }

        [HttpGet("report-snapshots")]
        [Authorize]
        public async Task<IActionResult> ListSnapshots()
        {
            var snapshots = await _analyticsService.ListSnapshotsAsync();
            return Ok(snapshots);
        }

        [HttpDelete("report-snapshots/{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteSnapshot(int id)
        {
            try
            {
                await _analyticsService.DeleteSnapshotAsync(id);
                return NoContent();
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        }

        [HttpPost("analytics/anomaly-detection")]
        [Authorize]
        public async Task<IActionResult> RunAnomalyDetection()
        {
            var newFlags = await _anomalyService.ScanAsync();
            return Ok(new { newFlagsCount = newFlags.Count, flags = newFlags });
        }

        [HttpGet("analytics/anomaly-detection/open")]
        [Authorize]
        public async Task<IActionResult> GetOpenAnomalies()
        {
            var flags = await _anomalyService.GetOpenFlagsAsync();
            return Ok(flags);
        }

                [HttpGet("analytics/approval-likelihood/{serviceProcedureId}")]
        [Authorize]
        public async Task<IActionResult> GetApprovalLikelihood(int serviceProcedureId)
        {
            var result = await _analyticsService.GetApprovalLikelihoodAsync(serviceProcedureId);
            return Ok(result);
        }

        [HttpGet("analytics/anomaly-detection/open")]

        [HttpPost("analytics/anomaly-detection/{id}/resolve")]
        [Authorize]
        public async Task<IActionResult> ResolveAnomaly(int id, [FromQuery] string status)
        {
            var email = User.Identity?.Name ?? "unknown@officer";
            try
            {
                var flag = await _anomalyService.ResolveFlagAsync(id, status, email);
                return Ok(flag);
            }
            catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        }
    }
}