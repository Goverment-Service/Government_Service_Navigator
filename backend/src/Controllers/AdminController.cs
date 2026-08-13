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
        [HttpPut("officers/{id}")]
        public async Task<IActionResult> UpdateOfficer(int id, [FromBody]UpdateOfficerRequest request) {
            if(!ModelState.IsValid) {
                return BadRequest(ModelState);
            }
            var success = await _adminService.UpdateOfficerAsync(id,request);
            if(!success) {
                return NotFound(new {
                    message = "Officer not found or update failed."
                });
            }
            return Ok(new {
                message = "Officer updated successfully."
            });
        }
        [HttpPost("officers/{id}/reset-password")]
        public async Task<IActionResult> ResetOfficerPassword(int id, [FromBody]ResetPasswordRequest request) {
            if(!ModelState.IsValid) {
                return BadRequest(ModelState);
            }
            var success = await _adminService.ResetOfficerPasswordAsync(id,request);
            if(!success) {
                return NotFound(new {
                    message = "Officer not found or password reset failed."
                });
            }
            return Ok(new {
                message = "Password reset successfully."
            });
        }
        [HttpPatch("officers/{id}/suspend")]
        public async Task<IActionResult> SuspendOfficer(int id) {
            var success = await _adminService.UpdateOfficerStatusAsync(id,"Suspended");
            if(!success) {
                return NotFound(new {
                    message = "Officer not found or status update failed."
                });
            }
            return Ok(new {
                message = "Account Suspended successfully."
            });
        }
        [HttpPatch("officers/{id}/activate")]
        public async Task<IActionResult> ActivateOfficer(int id) {
            var success = await _adminService.UpdateOfficerStatusAsync(id,"Active");
            if(!success) {
                return NotFound(new {
                    message = "Officer not found or status update failed."
                });
            }
            return Ok(new {
                message = "Account Activated successfully."
            });
        }
    }
}