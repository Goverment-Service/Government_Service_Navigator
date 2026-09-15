# ADR-0005: EF Core migrations are applied automatically on API startup

**Status:** Accepted
**Date:** 2026-08-07 (initial setup) — recorded 2026-09-15

## Context

The database schema changes frequently during active development (16 migrations as of 2026-09-15, most recently `AddRevokedTokens` and `AddTemplateServiceProcedureLink`), across a team of four working against one shared/dev PostgreSQL instance (Neon, per `backend/src/.env`'s `DATABASE_URL`). Forgetting to run `dotnet ef database update` after pulling new migrations is a common source of "works on my machine" / 500-errors-on-missing-column friction.

## Options Considered

1. **Manual migration step.** Developers/deployers run `dotnet ef database update` explicitly before starting the API. Standard practice, but easy to forget, and this project's `BackendRun.md` shows it was already a documented-but-skippable step.
2. **Auto-apply on startup.** Call `context.Database.Migrate()` in `Program.cs` right after building the app, wrapped in a try/catch that logs but doesn't crash the process on failure.

## Decision

Option 2 (`Program.cs`, step 6: "Automatically Apply Migrations at Startup"). Every `dotnet run` brings the connected database's schema up to date before the app starts serving requests.

## Consequences

- Removes an entire class of "I forgot to migrate" bugs for a small team sharing one dev database — `git pull && dotnet run` is enough.
- The migration failure path is swallowed to a `Console.WriteLine` and the app **still starts** even if migrations failed — meaning the API can come up successfully against a schema that's out of date with the code's expectations, and the first real symptom will be a runtime SQL error on whatever endpoint touches the missing column/table, not a clear startup failure. This is an accepted trade-off for dev convenience, not appropriate as-is for a production deployment with real uptime requirements.
- No safety net for concurrent instances: if this API is ever scaled to more than one running instance, multiple processes could race to apply the same migration on startup simultaneously. EF Core's migration history table provides some protection (it acquires a lock during migration application — visible in the `dotnet ef database update` output as "Acquiring an exclusive lock for migration application"), but this hasn't been tested under real concurrent-instance conditions and isn't a design this ADR is claiming to have solved.
- No rollback strategy: a bad migration is bad in production the moment that instance restarts, with no manual gate to catch it first. Acceptable for coursework/dev; would need a deploy-time migration step (separate from app startup) before this could be called production-ready.
