using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Tools.CalculateFee;

public record FeeScheduleEntry(string FeeType, decimal Amount, DateTime EffectiveDate);

public interface IFeeScheduleRepository
{
    Task<List<FeeScheduleEntry>> GetFeeSchedulesAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default);
}

public record FeeLineItem(string FeeType, decimal Amount);

public class FeeCalculationResult
{
    public string Currency { get; set; } = "LKR";
    public List<FeeLineItem> LineItems { get; set; } = new();
    public decimal TotalAmount { get; set; }
    public List<string> Notes { get; set; } = new();
}

public interface ICalculateFeeTool
{
    Task<FeeCalculationResult> CalculateAsync(
        int serviceProcedureId,
        bool expressProcessing = false,
        DateTime? asOf = null,
        int? stage = null,
        CancellationToken cancellationToken = default);
}

public class CalculateFeeTool : ICalculateFeeTool
{
    // Fee types that are only charged when the citizen opts into faster processing
    private static readonly string[] OptionalExpressKeywords = { "express", "urgent", "fast track", "one day" };

    private readonly IFeeScheduleRepository? _repository;

    public CalculateFeeTool(IFeeScheduleRepository? repository = null)
    {
        _repository = repository;
    }

    public async Task<FeeCalculationResult> CalculateAsync(
        int serviceProcedureId,
        bool expressProcessing = false,
        DateTime? asOf = null,
        int? stage = null,
        CancellationToken cancellationToken = default)
    {
        var result = new FeeCalculationResult();
        var effectiveAt = asOf ?? DateTime.UtcNow;

        if (_repository == null)
        {
            result.Notes.Add("Fee schedule repository unavailable; fee could not be computed and must be confirmed by an officer.");
            return result;
        }

        var schedules = await _repository.GetFeeSchedulesAsync(serviceProcedureId, stage, cancellationToken);

        // Only schedules already in force; unset (default) effective dates are treated as always in force.
        // When a fee type has several revisions, the most recent one in force wins.
        var activeFees = schedules
            .Where(f => f.EffectiveDate == default || f.EffectiveDate <= effectiveAt)
            .GroupBy(f => f.FeeType.Trim(), StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderByDescending(f => f.EffectiveDate).First())
            .ToList();

        foreach (var fee in activeFees)
        {
            bool isExpressFee = OptionalExpressKeywords.Any(k => fee.FeeType.Contains(k, StringComparison.OrdinalIgnoreCase));
            if (isExpressFee && !expressProcessing)
            {
                result.Notes.Add($"Optional '{fee.FeeType}' (LKR {fee.Amount:N2}) not applied — express processing not requested.");
                continue;
            }

            result.LineItems.Add(new FeeLineItem(fee.FeeType, fee.Amount));
        }

        result.TotalAmount = result.LineItems.Sum(i => i.Amount);

        if (result.LineItems.Count == 0)
        {
            result.Notes.Add("No fee schedule in force for this service — treated as free of charge.");
        }

        return result;
    }
}
