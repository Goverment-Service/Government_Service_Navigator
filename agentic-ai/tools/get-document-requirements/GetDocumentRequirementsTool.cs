using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace Government_Service_Navigator.AgenticAi.Tools.GetDocumentRequirements;

/// <summary>Reads the service catalog's document requirements (implemented by the backend over AppDbContext).</summary>
public interface IDocumentRequirementRepository
{
    Task<List<string>> GetDocumentNamesAsync(int serviceProcedureId, int? stage = null, CancellationToken cancellationToken = default);
}

public interface IGetDocumentRequirementsTool
{
    Task<List<string>> GetRequiredDocumentsForServiceAsync(int serviceId, int? stage = null, CancellationToken cancellationToken = default);
}

/// <summary>get_document_requirements — the documents the service catalog lists for a service.</summary>
public class GetDocumentRequirementsTool : IGetDocumentRequirementsTool
{
    private readonly IDocumentRequirementRepository _repository;

    public GetDocumentRequirementsTool(IDocumentRequirementRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<string>> GetRequiredDocumentsForServiceAsync(int serviceId, int? stage = null, CancellationToken cancellationToken = default)
    {
        var names = await _repository.GetDocumentNamesAsync(serviceId, stage, cancellationToken);
        return names.Where(n => !string.IsNullOrWhiteSpace(n)).Select(n => n.Trim()).Distinct().ToList();
    }
}
