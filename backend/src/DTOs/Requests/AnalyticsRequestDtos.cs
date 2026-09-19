namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    public class SaveReportSnapshotDto
    {
        public string Title { get; set; } = string.Empty;
        public string Period { get; set; } = string.Empty;
        public string DataJson { get; set; } = string.Empty;
    }
}