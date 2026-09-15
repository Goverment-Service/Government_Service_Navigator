import { getDepartmentSlug } from "../constants/departments";

export interface StoredUser {
  fullName?: string;
  email?: string;
  role?: string;
  department?: string;
}

// The "officerUser" key holds whatever the login endpoint returned - an
// OfficerDto (fullName, department, role) or an AdminDto (email, role only,
// since System Admin accounts have no name in the database). Every page that
// shows "who am I logged in as" should go through this so the label is
// identical everywhere instead of each page inventing its own fallback text.
export function getStoredUser(): StoredUser | null {
  const stored = localStorage.getItem("officerUser");
  if (!stored) return null;
  try {
    return JSON.parse(stored);
  } catch {
    return null;
  }
}

export function getDisplayName(user: StoredUser | null): string {
  if (!user) return "Unknown User";
  return user.fullName || user.email || "Unknown User";
}

// A Department Admin's "Overview" is their department dashboard
// (/admin/{deptSlug}/dashboard), not the System Admin's generic
// /admin/dashboard. Pages that link back to "Overview" must resolve this
// per-user instead of hardcoding /admin/dashboard, or a Department Admin
// gets dropped onto the wrong dashboard after visiting a shared admin page.
export function getAdminOverviewHref(user: StoredUser | null): string {
  const slug = user?.department ? getDepartmentSlug(user.department) : null;
  return slug ? `/admin/${slug}/dashboard` : "/admin/dashboard";
}
