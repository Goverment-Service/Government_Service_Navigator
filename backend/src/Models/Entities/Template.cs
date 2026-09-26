using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class Template
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(200)]
        public string FormName {get;set;} = string.Empty;

        [MaxLength(500)]
        public string? SubTitle {get;set;}
        public string? LawText {get;set;}

        [MaxLength(20)]
        public string Status {get;set;} = "Active";
        public DateTime CreatedAt {get;set;} = DateTime.UtcNow;

        // Optional link to the Service Catalog entry this application template is for,
        // so its Eligibility Rules and Document/Fee configuration can be surfaced
        // alongside the builder instead of living in a disconnected module.
        public int? ServiceProcedureId {get;set;}
        public ServiceProcedure? ServiceProcedure {get;set;}

        // Department this specific form belongs to (e.g., "Department of Registration of Persons", "Department of Immigration & Emigration")
        [MaxLength(150)]
        public string? Department { get; set; }

        // Sequential stage in the service workflow (e.g., 1 for Initial Intake, 2 for Secondary Inter-Departmental Endorsement)
        public int StageOrder { get; set; } = 1;

        [MaxLength(300)]
        public string? StageDescription { get; set; }

        public ICollection<FormField> Fields {get;set;} = new List<FormField>();
    }
}