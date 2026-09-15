# ADR-0004: Department scoping is enforced client-side, not server-side

**Status:** Accepted (with a known, documented security gap — see Consequences)
**Date:** 2026-09-15

## Context

A Department Admin (an `Officer` row with `Role` containing "Admin" and a non-empty `Department`) should only see and manage their own department's officers and Service Catalog entries — not other departments'. A System Admin (an `Admin` row, no `Department` at all) should see everything.

## Options Considered

1. **Server-side enforcement.** The backend reads the caller's department from their JWT claims and filters every relevant query (officers, services, eligibility rules, documents, fees) to that department, rejecting or 403-ing any request for another department's data.
2. **Client-side filtering only.** The web app reads `department`/`role` out of the JWT payload it already stored (`localStorage.getItem("officerUser")`) and filters what it *displays* and *defaults to* accordingly; the backend serves the same unfiltered data to everyone and trusts the frontend not to ask for the wrong thing.
3. **Mixed.** Server-side filtering only where it already happened to exist, client-side everywhere else.

## Decision

What's actually implemented is Option 3, arrived at incrementally rather than chosen upfront: `GET /api/admin/officers?department=X` (`AdminController`/`AdminService`) does filter server-side when a `department` query parameter is passed. Every other department-sensitive read — the Service Catalog manager, eligibility rule builder, eligibility simulator, service configuration tabs, and the application-template builder's "linked service" picker — filters entirely in the React components (`web/src/Admin/**`, `web/src/Officer/Application_create/TemplateBuilder.tsx`) using `currentUser.department` read out of `localStorage` and mapped to a Service Catalog category via `getCategoryForDepartment` (`web/src/constants/departments.ts`).

## Consequences

- **This is a real security gap, not just a UX nicety.** `ServicesController`, `TemplateController`, and most of `AdminController` have no `[Authorize]` attribute at all (see `docs/adr/0001-jwt-auth-with-revocation-table.md` and `docs/api.md` for the full picture) — so department scoping being client-side is compounded by there being no authentication requirement to bypass in the first place. Anyone who can reach the API (not just a logged-in Department Admin poking at another department through dev tools) can call `GET /api/services` or `GET /api/admin/officers` directly and get every department's data, fully unfiltered. The department-scoped UI only stops a well-behaved browser session from *displaying* another department's data; it enforces nothing.
- Fixing this properly means: (a) adding `[Authorize]` to `AdminController`, `ServicesController`, and `TemplateController`; (b) adding a `Department` (or role) claim check server-side in `AdminService`/`ServiceCatalogService` for every department-sensitive query, not just the one that already accepts a `department` query param. Neither is done yet — this ADR exists specifically to make that gap visible rather than let "the dropdown is scoped now" be mistaken for "the data is protected now."
- Until fixed, treat department scoping in this app as a **display convenience for legitimate users**, not an access-control boundary.
