using Microsoft.AspNetCore.Http;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    // multipart/form-data body for POST api/Applications/documents
    public class UploadDocumentRequest
    {
        public IFormFile? File { get; set; }

        // Label of the "file" form field the document answers
        public string? FieldLabel { get; set; }
    }
}
