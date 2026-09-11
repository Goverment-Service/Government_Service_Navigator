namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class EligibilityRule
    {
        public int Id { get; set; }
        public int ServiceProcedureId { get; set; }
        public required string Field { get; set; } // Age, Citizenship, Income
        public required string Operator { get; set; } // >=, <=, ==, !=
        public required string Value { get; set; }
        public bool IsStrict { get; set; } = true;
    }
}
