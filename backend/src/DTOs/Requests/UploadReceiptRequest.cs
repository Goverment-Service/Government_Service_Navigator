using Microsoft.AspNetCore.Http;

namespace Government_Service_Navigator.Backend.DTOs.Requests
{
    // multipart/form-data body for POST api/installment-plans/installments/{id}/bank-transfer
    public class UploadReceiptRequest
    {
        public IFormFile? Receipt { get; set; }
    }
}
