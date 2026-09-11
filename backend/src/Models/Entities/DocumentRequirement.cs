namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class DocumentRequirement
    {
        public int Id { get; set; }
        public int ServiceProcedureId { get; set; }
        public required string DocumentName { get; set; }
        public string? Description { get; set; }
        public bool IsMandatory { get; set; }
    }
}
