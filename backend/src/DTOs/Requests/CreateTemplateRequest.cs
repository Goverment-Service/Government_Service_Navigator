namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class CreateTemplateRequest 
    {
        public string FormName { get; set; } = string.Empty;
        public string? SubTitle { get; set; }
        public string? LawText { get; set; }
        public int? ServiceProcedureId { get; set; }
        public List<FormFieldDto> Fields { get; set; } = new List<FormFieldDto>();
    }
    public class FormFieldDto
    {
        public string Label {get; set;} = string.Empty;
        public string Type {get; set;} = string.Empty;
        public string? Options {get; set;}
        public bool? Required {get; set;}
    }

    public class UpdateTemplateStatusRequest
    {
        public string Status { get; set; } = string.Empty;
    }
}