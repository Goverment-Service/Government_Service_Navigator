using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Tools.PrefillApplication;

public record FormFieldDefinition(string Label, string Type, bool IsRequired, int OrderIndex = 0);

public interface IApplicationTemplateRepository
{
    /// <summary>Returns the form fields of the active template linked to the service, or an empty list if none.</summary>
    Task<List<FormFieldDefinition>> GetFormFieldsAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default);
}

public class ApplicantDetails
{
    public string CitizenNic { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int Age { get; set; }
    public string CitizenshipStatus { get; set; } = string.Empty;
    public decimal AnnualIncome { get; set; }
    public string EmploymentStatus { get; set; } = string.Empty;
    public Dictionary<string, string> AdditionalAttributes { get; set; } = new();
}

public class PrefillResult
{
    public Dictionary<string, string> FormFields { get; set; } = new();
    public List<string> UnfilledRequiredFields { get; set; } = new();
    public List<string> UnfilledOptionalFields { get; set; } = new();
    public bool UsedDefaultTemplate { get; set; }
}

public interface IPrefillApplicationTool
{
    Task<PrefillResult> PrefillAsync(int serviceProcedureId, ApplicantDetails applicant, int? stage = null, CancellationToken cancellationToken = default);
}

public class PrefillApplicationTool : IPrefillApplicationTool
{
    // Used when the service has no application template configured yet
    private static readonly List<FormFieldDefinition> DefaultTemplate = new()
    {
        new("Full Name", "text", true, 0),
        new("NIC Number", "text", true, 1),
        new("Email", "email", true, 2),
        new("Age", "number", true, 3),
        new("Citizenship", "text", true, 4),
        new("Annual Income", "number", false, 5),
        new("Employment Status", "text", false, 6)
    };

    private readonly IApplicationTemplateRepository? _repository;

    public PrefillApplicationTool(IApplicationTemplateRepository? repository = null)
    {
        _repository = repository;
    }

    public async Task<PrefillResult> PrefillAsync(int serviceProcedureId, ApplicantDetails applicant, int? stage = null, CancellationToken cancellationToken = default)
    {
        var result = new PrefillResult();

        var fields = _repository != null
            ? await _repository.GetFormFieldsAsync(serviceProcedureId, stage, cancellationToken)
            : new List<FormFieldDefinition>();

        if (fields.Count == 0)
        {
            fields = DefaultTemplate;
            result.UsedDefaultTemplate = true;
        }

        foreach (var field in fields.OrderBy(f => f.OrderIndex))
        {
            var value = ResolveValue(field.Label, applicant);
            if (!string.IsNullOrWhiteSpace(value))
            {
                result.FormFields[field.Label] = value;
            }
            else if (field.IsRequired)
            {
                result.UnfilledRequiredFields.Add(field.Label);
            }
            else
            {
                result.UnfilledOptionalFields.Add(field.Label);
            }
        }

        return result;
    }

    /// <summary>
    /// Deterministically maps a form label to a known applicant attribute. Only data the citizen
    /// supplied is used — nothing is invented.
    /// </summary>
    private static string? ResolveValue(string label, ApplicantDetails a)
    {
        // Exact match against extra attributes the citizen supplied (e.g. "Business Name")
        var extra = a.AdditionalAttributes.FirstOrDefault(kv => Normalize(kv.Key) == Normalize(label));
        if (!string.IsNullOrWhiteSpace(extra.Value)) return extra.Value.Trim();

        var l = Normalize(label);

        if (l.Contains("nic") || l.Contains("national identity") || l.Contains("identity card"))
            return a.CitizenNic;
        if (l.Contains("email") || l.Contains("e-mail"))
            return a.Email;
        if (l.Contains("name") && !l.Contains("business") && !l.Contains("company") && !l.Contains("father") && !l.Contains("mother"))
            return a.FullName;
        if (l == "age" || l.Contains("applicant age") || l.Contains("age (years)"))
            return a.Age > 0 ? a.Age.ToString() : null;
        if (l.Contains("citizenship") || l.Contains("nationality"))
            return a.CitizenshipStatus;
        if (l.Contains("income") || l.Contains("salary"))
            return a.AnnualIncome > 0 ? a.AnnualIncome.ToString("0.##") : null;
        if (l.Contains("employment") || l.Contains("occupation"))
            return a.EmploymentStatus;

        return null;
    }

    private static string Normalize(string s) => s.Trim().ToLowerInvariant();
}
