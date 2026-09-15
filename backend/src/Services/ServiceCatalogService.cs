using Microsoft.EntityFrameworkCore;
using Government_Service_Navigator.Backend.Data.Context;
using Government_Service_Navigator.Backend.Models.Entities;
using Government_Service_Navigator.Backend.DTOs;
using Government_Service_Navigator.Backend.Services.Interfaces;

namespace Government_Service_Navigator.Backend.Services
{
    public class ServiceCatalogService : IServiceCatalogService
    {
        private readonly AppDbContext _context;

        public ServiceCatalogService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<ServiceProcedure> CreateServiceAsync(ServiceProcedure service)
        {
            _context.ServiceProcedures.Add(service);
            await _context.SaveChangesAsync();
            return service;
        }
        public async Task<IEnumerable<ServiceProcedure>> GetAllServicesAsync()
        {
            return await _context.ServiceProcedures
                .Include(s => s.DocumentRequirements)
                .Include(s => s.FeeSchedules)
                .Where(s => s.Status != "Retired") // Exclude deleted/retired services
                .ToListAsync();
        }



        public async Task<ServiceProcedure?> GetServiceByIdAsync(int id)
        {
            return await _context.ServiceProcedures
                .Include(s => s.EligibilityRules)
                .Include(s => s.DocumentRequirements)
                .Include(s => s.FeeSchedules)
                .FirstOrDefaultAsync(s => s.Id == id);
        }

        // public async Task<IEnumerable<ServiceProcedure>> GetAllServicesAsync()
        // {
        //     return await _context.ServiceProcedures.ToListAsync();
        // }

        public async Task<ServiceProcedure> UpdateEligibilityRulesAsync(int id, List<EligibilityRule> rules)
        {
            var service = await _context.ServiceProcedures
                .Include(s => s.EligibilityRules)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (service == null) throw new KeyNotFoundException();

            // Replace old rules with new ones
            _context.EligibilityRules.RemoveRange(service.EligibilityRules);
            service.EligibilityRules = rules;

            await _context.SaveChangesAsync();
            return service;
        }

        public async Task<bool> RetireServiceAsync(int id)
        {
            var service = await _context.ServiceProcedures.FindAsync(id);
            if (service == null) return false;

            service.Status = "Retired";
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<EligibilityScoreResultDto> CalculateEligibilityScoreAsync(int serviceId, CitizenProfileDto profile)
        {
            var service = await _context.ServiceProcedures
                .Include(s => s.EligibilityRules)
                .FirstOrDefaultAsync(s => s.Id == serviceId);

            if (service == null) throw new KeyNotFoundException();

            var result = new EligibilityScoreResultDto { IsEligible = true, MatchPercentage = 100 };
            int totalRules = service.EligibilityRules.Count;
            if (totalRules == 0) return result;

            int passedRules = 0;

            foreach (var rule in service.EligibilityRules)
            {
                bool passed = EvaluateRule(rule, profile);
                if (passed)
                {
                    passedRules++;
                }
                else
                {
                    result.IsEligible = false;
                    result.MissingCriteria.Add($"Failed requirement: {rule.Field} {rule.Operator} {rule.Value}");
                }
            }

            result.MatchPercentage = Math.Round((double)passedRules / totalRules * 100, 2);
            return result;
        }

        private bool EvaluateRule(EligibilityRule rule, CitizenProfileDto profile)
        {
            // Basic evaluation logic - expand this based on your needs
            if (rule.Field == "Age")
            {
                if (int.TryParse(rule.Value, out int requiredAge))
                {
                    if (rule.Operator == ">=") return profile.Age >= requiredAge;
                    if (rule.Operator == "==") return profile.Age == requiredAge;
                }
            }
            if (rule.Field == "Citizenship")
            {
                if (rule.Operator == "==") return profile.Citizenship.Equals(rule.Value, StringComparison.OrdinalIgnoreCase);
            }

            return false; // Default fail if rule format is unrecognized
        }

        public async Task<ServiceProcedure?> UpdateServiceAsync(int id, ServiceProcedure updatedService)
        {
            var service = await _context.ServiceProcedures.FindAsync(id);
            if (service == null) return null;

            // Update the basic properties
            service.ServiceId = updatedService.ServiceId;
            service.Name = updatedService.Name;
            service.Category = updatedService.Category;
            service.Status = updatedService.Status;

            await _context.SaveChangesAsync();
            return service;
        }

        public async Task<ServiceProcedure> UpdateDocumentRequirementsAsync(int id, List<DocumentRequirement> incomingDocuments)
        {
            var service = await _context.ServiceProcedures
                .Include(s => s.DocumentRequirements)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (service == null) throw new KeyNotFoundException();

            // 1. Identify and remove documents that were deleted on the frontend
            var incomingIds = incomingDocuments.Select(d => d.Id).Where(dId => dId != 0).ToList();
            var docsToRemove = service.DocumentRequirements.Where(d => !incomingIds.Contains(d.Id)).ToList();
            _context.DocumentRequirements.RemoveRange(docsToRemove);

            // 2. Add new documents or update existing ones
            foreach (var incoming in incomingDocuments)
            {
                if (incoming.Id == 0)
                {
                    // Brand new document
                    incoming.ServiceProcedureId = id;
                    _context.DocumentRequirements.Add(incoming);
                }
                else
                {
                    // Existing document -> update in place
                    var existing = service.DocumentRequirements.FirstOrDefault(d => d.Id == incoming.Id);
                    if (existing != null)
                    {
                        existing.DocumentName = incoming.DocumentName;
                        existing.Description = incoming.Description;
                        existing.IsMandatory = incoming.IsMandatory;
                    }
                }
            }

            await _context.SaveChangesAsync();
            return await GetServiceByIdAsync(id);
        }

        public async Task<bool> DeleteDocumentRequirementAsync(int documentId)
        {
            var doc = await _context.DocumentRequirements.FindAsync(documentId);
            if (doc == null) return false;

            _context.DocumentRequirements.Remove(doc);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<ServiceProcedure> UpdateFeeSchedulesAsync(int id, List<FeeSchedule> incomingFees)
        {
            var service = await _context.ServiceProcedures
                .Include(s => s.FeeSchedules)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (service == null) throw new KeyNotFoundException();

            var incomingIds = incomingFees.Select(f => f.Id).Where(fId => fId != 0).ToList();
            var feesToRemove = service.FeeSchedules.Where(f => !incomingIds.Contains(f.Id)).ToList();
            _context.FeeSchedules.RemoveRange(feesToRemove);

            foreach (var incoming in incomingFees)
            {
                if (incoming.Id == 0)
                {
                    incoming.ServiceProcedureId = id;
                    _context.FeeSchedules.Add(incoming);
                }
                else
                {
                    var existing = service.FeeSchedules.FirstOrDefault(f => f.Id == incoming.Id);
                    if (existing != null)
                    {
                        existing.FeeType = incoming.FeeType;
                        existing.Amount = incoming.Amount;
                        existing.EffectiveDate = incoming.EffectiveDate;
                    }
                }
            }

            await _context.SaveChangesAsync();
            return await GetServiceByIdAsync(id);
        }

        public async Task<bool> DeleteFeeScheduleAsync(int feeId)
        {
            var fee = await _context.FeeSchedules.FindAsync(feeId);
            if (fee == null) return false;

            _context.FeeSchedules.Remove(fee);
            await _context.SaveChangesAsync();
            return true;
        }


    }
}
