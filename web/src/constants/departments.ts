export interface DepartmentOption {
  label: string;
  slug: string;
  // Service Catalog "Category" value handled by this department.
  category: string;
}

export const DEPARTMENTS: DepartmentOption[] = [
  { label: "Department of Immigration & Emigration", slug: "immigration", category: "Immigration" },
  { label: "Department of Motor Traffic", slug: "motor-traffic", category: "Transport" },
  { label: "Police Department", slug: "police", category: "Police" },
  { label: "Department of Registration of Persons", slug: "registration-of-persons", category: "Civil" },
  { label: "Divisional Secretariat", slug: "divisional-secretariat", category: "Public Administration" },
];

export function getDepartmentSlug(department: string): string | null {
  const normalized = department.trim().toLowerCase();
  const match = DEPARTMENTS.find((d) => d.label.toLowerCase() === normalized);
  return match ? match.slug : null;
}

export function getDepartmentLabel(slug: string): string | null {
  const match = DEPARTMENTS.find((d) => d.slug === slug.toLowerCase());
  return match ? match.label : null;
}

export function getCategoryForDepartment(department: string): string | null {
  const normalized = department.trim().toLowerCase();
  const match = DEPARTMENTS.find((d) => d.label.toLowerCase() === normalized);
  return match ? match.category : null;
}

export function getDepartmentForCategory(category: string): string | null {
  const normalized = category.trim().toLowerCase();
  const match = DEPARTMENTS.find((d) => d.category.toLowerCase() === normalized);
  return match ? match.label : null;
}
