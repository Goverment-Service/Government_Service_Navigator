using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Tools.FindAppointmentSlot;

public class AppointmentSlotResult
{
    public bool IsSlotFound { get; set; }
    public DateTime? SlotStartUtc { get; set; }
    public DateTime? SlotEndUtc { get; set; }
    public string LocalDisplay { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public interface IFindAppointmentSlotTool
{
    Task<AppointmentSlotResult> FindSlotAsync(int serviceProcedureId, DateTime? preferredDateUtc = null, DateTime? nowUtc = null);
}

/// <summary>
/// Proposes (never reserves) the earliest free counter slot for a service.
/// Reserving a limited slot is a high-impact action that requires officer approval (§2 Project Plan),
/// so the result is only a proposal carried on the draft application.
/// </summary>
public class FindAppointmentSlotTool : IFindAppointmentSlotTool
{
    // Sri Lanka Standard Time (UTC+05:30, no daylight saving)
    private static readonly TimeSpan SriLankaOffset = TimeSpan.FromHours(5.5);
    private static readonly TimeSpan OfficeOpens = new(9, 0, 0);
    private static readonly TimeSpan OfficeCloses = new(15, 0, 0);
    private static readonly TimeSpan SlotLength = TimeSpan.FromMinutes(30);
    private const int MinimumLeadWorkingDays = 2;
    private const int SearchHorizonDays = 30;

    // Slots already proposed per service, so concurrent drafts are not all offered the same time
    private static readonly ConcurrentDictionary<string, byte> ProposedSlots = new();

    public Task<AppointmentSlotResult> FindSlotAsync(int serviceProcedureId, DateTime? preferredDateUtc = null, DateTime? nowUtc = null)
    {
        var nowLocal = new DateTimeOffset(nowUtc ?? DateTime.UtcNow, TimeSpan.Zero).ToOffset(SriLankaOffset);

        // Earliest allowed day: N working days after today, giving officers time to review the draft
        var earliestDay = AddWorkingDays(nowLocal.Date, MinimumLeadWorkingDays);
        if (preferredDateUtc.HasValue)
        {
            var preferredLocalDay = new DateTimeOffset(DateTime.SpecifyKind(preferredDateUtc.Value, DateTimeKind.Utc)).ToOffset(SriLankaOffset).Date;
            if (preferredLocalDay > earliestDay) earliestDay = preferredLocalDay;
        }

        for (var day = earliestDay; day <= earliestDay.AddDays(SearchHorizonDays); day = day.AddDays(1))
        {
            if (!IsWorkingDay(day)) continue;

            for (var time = OfficeOpens; time + SlotLength <= OfficeCloses; time += SlotLength)
            {
                var slotStart = new DateTimeOffset(day + time, SriLankaOffset);
                var key = $"{serviceProcedureId}_{slotStart.UtcDateTime:O}";
                if (!ProposedSlots.TryAdd(key, 0)) continue;

                return Task.FromResult(new AppointmentSlotResult
                {
                    IsSlotFound = true,
                    SlotStartUtc = slotStart.UtcDateTime,
                    SlotEndUtc = (slotStart + SlotLength).UtcDateTime,
                    LocalDisplay = $"{slotStart:dddd, dd MMM yyyy HH:mm} - {slotStart + SlotLength:HH:mm} (Sri Lanka Time)",
                    Message = "Proposed slot — pending Verifying Officer approval before it is reserved."
                });
            }
        }

        return Task.FromResult(new AppointmentSlotResult
        {
            IsSlotFound = false,
            Message = $"No free appointment slot within {SearchHorizonDays} days of {earliestDay:dd MMM yyyy}. An officer will schedule manually."
        });
    }

    public static void ClearProposedSlots() => ProposedSlots.Clear();

    private static bool IsWorkingDay(DateTime day) =>
        day.DayOfWeek != DayOfWeek.Saturday && day.DayOfWeek != DayOfWeek.Sunday;

    private static DateTime AddWorkingDays(DateTime start, int workingDays)
    {
        var day = start;
        while (workingDays > 0)
        {
            day = day.AddDays(1);
            if (IsWorkingDay(day)) workingDays--;
        }
        return day;
    }
}
