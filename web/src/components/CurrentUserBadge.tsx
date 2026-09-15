import { getStoredUser, getDisplayName } from "../utils/currentUser";

// Shows who is currently logged in, consistently, in the Carbon Header's
// HeaderGlobalBar. Previously only 2 of 9 admin pages showed this (as a big
// "Welcome back" banner), so the same session appeared to have a different
// (or no) identity depending which page you were on.
export default function CurrentUserBadge() {
  const user = getStoredUser();
  const name = getDisplayName(user);
  const role = user?.role;

  return (
    <div
      className="hidden sm:flex items-center mr-3 sm:mr-4"
      style={{ color: "#f4f4f4", fontSize: "0.8125rem", lineHeight: 1.2 }}
    >
      <span style={{ fontWeight: 600, whiteSpace: "nowrap" }}>{name}</span>
      {role && (
        <span style={{ marginLeft: "0.375rem", color: "#c6c6c6", whiteSpace: "nowrap" }}>
          ({role})
        </span>
      )}
    </div>
  );
}
