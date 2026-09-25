# Tool: get_document_requirements

Used by: Eligibility & Document Analysis Agent.

Returns the document names the service catalog lists for a service (`DocumentRequirements` table,
read through `IDocumentRequirementRepository`). Agent 2 uses it when the service has no chunk in the
vector DB yet, e.g. before `POST api/RagSetup/seed` has been run.
