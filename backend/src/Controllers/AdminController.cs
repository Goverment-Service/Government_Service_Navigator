using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase 
    {
        private readonly IAdminService _adminService;
        public AdminController(IAdminService adminService) {
            _adminService = adminService;
        }

        [HttpGet("officers")]
        public async Task<IActionResult> GetAllOfficers() {
            var officers = await _adminService.GetAllOfficersAsync();
            return Ok(officers);
        }
        [HttpPost("officers")]
        public async Task<IActionResult> AddOfficer([FromBody]CreateOfficerRequest request) {
            if(!ModelState.IsValid) {
                return BadRequest(ModelState);
            }
            var response = await _adminService.CreateOfficerAsync(request);
            if(!response.Success) {
                return BadRequest(new { message = response.ErrorMessage });
            }
            return Ok(response.Officer);
        }
    }
}