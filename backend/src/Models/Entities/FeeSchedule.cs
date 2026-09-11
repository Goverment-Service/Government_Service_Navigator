namespace Government_Service_Navigator.Backend.Models.Entities
{
    public class FeeSchedule
    {
        public int Id { get; set; }
        public int ServiceProcedureId { get; set; }
        public required string FeeType { get; set; }
        public decimal Amount { get; set; }
        public DateTime EffectiveDate { get; set; }
    }
}
