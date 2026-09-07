using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class FormField
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid TemplateId { get; set; }

        [ForeignKey(nameof(TemplateId))]
        public Template? Template { get; set; }

        [Required]
        public string Label { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Type {get;set;} = string.Empty; 

        public string? Options {get;set;}  

        public bool IsRequired {get;set;} = false;

        public int OrderIndex {get;set;}
    }
}