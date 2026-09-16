using System.Collections.Generic;

namespace Government_Service_Navigator.Backend.Services
{
    // Maps a Service Catalog "Category" (ServiceProcedure.Category) to the
    // human-readable department name that owns it. Mirrors
    // web/src/constants/departments.ts's category mapping - the web admin
    // side additionally needs URL slugs for routing, which is a pure
    // frontend concern and stays there, but the category-to-department
    // business mapping itself is owned here so every client (web, mobile)
    // gets the same department name without duplicating this table.
    public static class DepartmentCatalog
    {
        private static readonly Dictionary<string, string> CategoryToDepartment = new()
        {
            { "Police", "Police Department" },
            { "Commerce", "Finance Department" },
            { "Transport", "Transport Department" },
            { "Civil", "Civil Department" },
        };

        public static string GetDepartmentForCategory(string? category)
        {
            if (string.IsNullOrWhiteSpace(category)) return string.Empty;
            return CategoryToDepartment.TryGetValue(category, out var department) ? department : category;
        }
    }
}
