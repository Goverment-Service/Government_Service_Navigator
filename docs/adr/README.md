# Architecture Decision Records

Each ADR documents one real decision made in this codebase — the context that forced it, the options actually considered, what was chosen, and the honest trade-offs accepted (including known gaps, not just upsides). They describe the system as built, not the aspirational design in `docs/Government_Service_Navigator_Project_Plan.md`.

| # | Decision |
|---|---|
| [0001](0001-jwt-auth-with-revocation-table.md) | Stateless JWT auth with a database revocation table for logout |
| [0002](0002-single-project-folder-layering.md) | Single ASP.NET Core project with folder-based layering |
| [0003](0003-separate-user-officer-admin-tables.md) | Separate `User` / `Officer` / `Admin` tables instead of one polymorphic identity table |
| [0004](0004-client-side-department-scoping.md) | Department scoping is enforced client-side, not server-side ⚠️ known security gap |
| [0005](0005-auto-apply-migrations-on-startup.md) | EF Core migrations are applied automatically on API startup |
| [0006](0006-optional-template-service-link.md) | Application Templates link to a Service Catalog entry via an optional FK |
| [0007](0007-carbon-and-tailwind-together.md) | Carbon Design System components + Tailwind CSS utilities, together |

New ADRs should follow the same template (Context / Options Considered / Decision / Consequences) and be numbered sequentially.
