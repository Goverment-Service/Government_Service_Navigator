using System;
using System.Collections.Generic;
using Government_Service_Navigator.AgenticAi.Schemas;
using Government_Service_Navigator.AgenticAi.Tools.CalculateFee;
using Government_Service_Navigator.AgenticAi.Tools.FindAppointmentSlot;

namespace Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.DTOs;

public record ToolCallRecord(string ToolName, string Input, string Output, DateTime CalledAt);

public record ActionDraftResponse(
    bool IsReadyForValidation,
    DraftApplication? Draft,
    FeeCalculationResult? Fee,
    AppointmentSlotResult? Appointment,
    List<string> UnfilledRequiredFields,
    List<string> Blockers,
    List<string> NotesForOfficer,
    string Reasoning,
    List<ToolCallRecord> ToolCalls,
    List<string> RetrievedContextSnippets
);
