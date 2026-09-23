namespace Government_Service_Navigator.AgenticAi.Schemas
{
    public class ComplianceCheckItem
    {
        public string CheckType { get; set; } = string.Empty;
        public bool IsPassed { get; set; }
        public string Details { get; set; } = string.Empty;

        public ComplianceCheckItem() { }

        public ComplianceCheckItem(string checkType, bool isPassed, string details)
        {
            CheckType = checkType;
            IsPassed = isPassed;
            Details = details;
        }
    }
}
