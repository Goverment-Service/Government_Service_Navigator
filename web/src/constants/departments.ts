export interface DepartmentOption {
  label: string;
  slug: string;
  // Service Catalog "Category" value handled by this department.
  category: string;
}

export const DEPARTMENTS: DepartmentOption[] = [
  { label: "Police Department", slug: "police", category: "Police" },
  { label: "Finance Department", slug: "finance", category: "Commerce" },
  { label: "Transport Department", slug: "transport", category: "Transport" },
  { label: "Civil Department", slug: "civil", category: "Civil" },
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
