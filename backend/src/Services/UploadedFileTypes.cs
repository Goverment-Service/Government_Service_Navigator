namespace Government_Service_Navigator.Backend.Services
{
    // Identifies accepted uploads (PDF / JPEG / PNG) from their bytes rather than the client-supplied type.
    public static class UploadedFileTypes
    {
        public const long MaxBytes = 10 * 1024 * 1024;

        public static string? Detect(byte[] c)
        {
            if (c.Length >= 4 && c[0] == 0x25 && c[1] == 0x50 && c[2] == 0x44 && c[3] == 0x46) return "application/pdf"; // %PDF
            if (c.Length >= 3 && c[0] == 0xFF && c[1] == 0xD8 && c[2] == 0xFF) return "image/jpeg";
            if (c.Length >= 8 && c[0] == 0x89 && c[1] == 0x50 && c[2] == 0x4E && c[3] == 0x47) return "image/png";
            return null;
        }
    }
}
