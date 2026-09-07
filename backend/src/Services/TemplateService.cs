using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.DTOs.Requests;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Government_Service_Navigator.Backend.Services
{
    public class TemplateService: ITemplateService
    {
        private readonly AppDbContext _context;
        public TemplateService(AppDbContext context) 
        {
            _context = context;
        }
        public async Task<Template>CreateTemplateAsync(CreateTemplateRequest request)
        {
            var template = new Template
            {
                FormName = request.FormName,
                SubTitle = request.SubTitle,
                LawText = request.LawText,
                Fields = request.Fields.Select((f, index) => new FormField
                {
                    Label = f.Label,
                    Type = f.Type,
                    Options = f.Options,
                    IsRequired = f.Required ?? false,
                    OrderIndex = index 
                }).ToList()
            };
            _context.Templates.Add(template);
            await _context.SaveChangesAsync();
            return template;
        }
        public async Task<IEnumerable<Template>> GetAllTemplatesAsync() 
        {
            return await _context.Templates
                .Include(t => t.Fields.OrderBy(f=> f.OrderIndex))
                .ToListAsync();
        }
        public async Task<Template?> GetTemplateByIdAsync(Guid id)
        {
            return await _context.Templates
                .Include(t => t.Fields.OrderBy(f => f.OrderIndex))
                .FirstOrDefaultAsync(t => t.Id == id);
        }
    }
}