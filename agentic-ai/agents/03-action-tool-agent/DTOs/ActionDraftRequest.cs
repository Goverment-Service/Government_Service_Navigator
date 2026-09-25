using System;
using Government_Service_Navigator.AgenticAi.Agents.EligibilityDocumentAgent.DTOs;
using Government_Service_Navigator.AgenticAi.Tools.PrefillApplication;

namespace Government_Service_Navigator.AgenticAi.Agents.ActionToolAgent.DTOs;

public record ActionDraftRequest(
    int ApplicationId,
    int ServiceProcedureId,
    string ServiceName,
    ApplicantDetails Applicant,
    EligibilityPlanResponse Eligibility,
    List<string>? ProvidedDocuments = null,
    DateTime? PreferredAppointmentDateUtc = null,
    bool ExpressProcessing = false
);
