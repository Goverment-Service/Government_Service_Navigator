using System.Threading.Tasks;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.DTOs.Responses;

namespace Government_Service_Navigator.Backend.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<RefundResponse> CreateRefundRequestAsync(int paymentId, CreateRefundRequestRequest request);
        Task<LedgerResponse> GetLedgerAsync(int paymentId);
    }
}
