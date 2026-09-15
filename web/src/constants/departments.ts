export interface DepartmentOption {
  label: string;
  slug: string;
}

export const DEPARTMENTS: DepartmentOption[] = [
  { label: "Police Department", slug: "police" },
  { label: "Finance Department", slug: "finance" },
  { label: "Transport Department", slug: "transport" },
  { label: "Civil Department", slug: "civil" },
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
