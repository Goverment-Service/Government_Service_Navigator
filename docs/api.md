# API Reference

Base URL: `http://localhost:5119` (hardcoded on both clients — see `docs/diagrams/system-architecture.md`). Swagger UI is available at `/swagger` when `ASPNETCORE_ENVIRONMENT=Development`.

All request/response bodies are JSON. ASP.NET Core's default `System.Text.Json` camelCases property names in responses (e.g. the C# `FormName` property serializes as `"formName"`), which is reflected below.

**Read this before trusting "Auth" below at face value:** ASP.NET Core's JWT middleware is registered globally, but that only makes `Authorization: Bearer <token>` *available* to check — it does not require it. A route only actually rejects unauthenticated requests if its controller/action is decorated `[Authorize]`. As of 2026-09-15, that's `VerificationController` (every action) and `AuthController.Logout` only. Every other endpoint below marked "None" is genuinely, currently, callable without any token at all. See `docs/adr/0004-client-side-department-scoping.md` for why this matters beyond just auth.

---

## Auth — `AuthController`, `api/auth`

| Method | Path | Auth | Body → Response |
|---|---|---|---|
| POST | `/api/auth/register` | None | [`RegisterRequest`](#registerrequest) → [`AuthResponse`](#authresponse) with `user` |
| POST | `/api/auth/login` | None | [`LoginRequest`](#loginrequest) → `AuthResponse` with `user` |
| POST | `/api/auth/officer-login` | None | `LoginRequest` → `AuthResponse` with `officer` |
| POST | `/api/auth/admin-login` | None | `LoginRequest` → `AuthResponse` with `admin` |
| POST | `/api/auth/logout` | **Bearer required** | *(no body)* → `AuthResponse { success: true }` |

### `LoginRequest`
```json
{ "email": "string (required, email format)", "password": "string (required)" }
```

### `RegisterRequest`
```json
{ "fullName": "string", "email": "string (email)", "password": "string (min 6 chars)", "nicNumber": "string" }
```
Creates a `User` row (citizen). Fails with `{ success: false, errorMessage: "User with this email already exists." }` (still `200 OK`, not `409`) if the email is taken.

### `AuthResponse`
```json
{
  "success": true,
  "token": "eyJ...",
  "errorMessage": null,
  "user": { "email": "", "fullName": "", "nicNumber": "", "role": "" },
  "officer": { "email": "", "fullName": "", "department": "", "role": "" },
  "admin": { "email": "", "role": "" }
}
```
Only one of `user`/`officer`/`admin` is populated depending on which login endpoint was called; the other two are `null`. **Every controller action here returns `200 OK` even on failure** — check `success`/`errorMessage`, not the HTTP status code, for `register`/`login`/`officer-login`/`admin-login`.

The issued JWT is HMAC-SHA256-signed (`JWT_KEY`), expires in **7 days** (hardcoded `DateTime.UtcNow.AddDays(7)` in `AuthService` — the `.env`'s `JWT_EXPIRY_HOURS=24` is **not actually read anywhere in the code**, it's a stale/aspirational setting), and carries a `jti` claim used for the revocation check (`docs/adr/0001-jwt-auth-with-revocation-table.md`). Officer/Admin tokens carry a `role`/`department` claim; none of the three token types carry a role *scope* the backend actually checks against `[Authorize(Roles=...)]` anywhere — role gating today is entirely client-side (see `docs/adr/0004-client-side-department-scoping.md`).

### `POST /api/auth/logout`
Requires `Authorization: Bearer <token>`. Reads the caller's `jti`/`exp` claims and inserts a `RevokedToken` row so that exact token is rejected on every subsequent request (regardless of its 7-day expiry). Always returns `{ success: true, errorMessage: "Logged out successfully" }` if a `jti` was present; silently does nothing (but still returns success) if it wasn't.

---

## Admin — `AdminController`, `api/admin`

**Auth: None** on any action — see the warning at the top of this document.

| Method | Path | Body → Response |
|---|---|---|
| GET | `/api/admin/officers?department=X` (optional) | → `OfficerDetailsDto[]` |
| POST | `/api/admin/officers` | [`CreateOfficerRequest`](#createofficerrequest) → `200` with `OfficerDto`, or `400 { message }` |
| PUT | `/api/admin/officers/{id}` | [`UpdateOfficerRequest`](#updateofficerrequest) → `200 { message }` or `404` |
| POST | `/api/admin/officers/{id}/reset-password` | `{ "newPassword": "string (min 6)" }` → `200 { message }` or `404` |
| PATCH | `/api/admin/officers/{id}/suspend` | *(no body)* → `200 { message }` or `404` (sets `Status = "Suspended"`) |
| PATCH | `/api/admin/officers/{id}/activate` | *(no body)* → `200 { message }` or `404` (sets `Status = "Active"`) |

### `OfficerDetailsDto` (GET response shape)
```json
{ "id": "string", "name": "", "email": "", "role": "", "department": "", "status": "" }
```

### `CreateOfficerRequest`
```json
{ "fullName": "", "email": "", "password": "", "department": "", "role": "" }
```
`role` is a free-form string — nothing validates it against an allowed list server-side; the frontend's dropdown is the only thing constraining it to `Verifying Officer` / `Department Admin` / `Auditor` / `Finance Officer` (the last only offered when `Department Department` is selected — see the Manage Officers UI).

### `UpdateOfficerRequest`
```json
{ "fullName": "", "department": "", "role": "" }
```
Note: **cannot** update `email` or `status` through this endpoint — status changes only via the separate suspend/activate routes, email isn't changeable at all once created.

---

## Services / Eligibility — `ServicesController`, `api/services`

**Auth: None** on any action.

| Method | Path | Body → Response |
|---|---|---|
| GET | `/api/services` | → `ServiceProcedure[]` (excludes `Status == "Retired"`; includes documents + fees, **not** eligibility rules) |
| GET | `/api/services/{id}` | → `ServiceProcedure` (includes eligibility rules, documents, and fees) or `404` |
| POST | `/api/services` | raw [`ServiceProcedure`](#serviceprocedure-entity) → `201` with created entity, or `500` |
| PUT | `/api/services/{id}` | raw `ServiceProcedure` (only `serviceId`/`name`/`category`/`status` are applied) → `200` or `404` |
| DELETE | `/api/services/{id}` | *(no body)* → `204` or `404` — **soft delete**: sets `Status = "Retired"`, does not remove the row |
| PUT | `/api/services/{id}/eligibility-rules` | `EligibilityRule[]` (full replace) → updated `ServiceProcedure` or `404` |
| PUT | `/api/services/{id}/documents` | `DocumentRequirement[]` (diffed: new/updated/removed by `id`, `id: 0` = new) → updated `ServiceProcedure` or `404` |
| DELETE | `/api/services/documents/{documentId}` | → `204` or `404` |
| PUT | `/api/services/{id}/fees` | `FeeSchedule[]` (diffed the same way as documents) → updated `ServiceProcedure` or `404` |
| DELETE | `/api/services/fees/{feeId}` | → `204` or `404` |
| POST | `/api/services/eligibility-score` | [`EligibilityRequestDto`](#eligibilityrequestdto) → [`EligibilityScoreResultDto`](#eligibilityscoreresultdto) or `404` |

### `ServiceProcedure` entity
```json
{ "id": 0, "serviceId": "GSN-SRV-001", "name": "", "category": "", "status": "Draft | Active | Retired",
  "eligibilityRules": [...], "documentRequirements": [...], "feeSchedules": [...] }
```
`serviceId` is **server-generated** on create (`GenerateNextServiceIdAsync` — scans all existing `ServiceId`s, including retired ones, for the highest `GSN-SRV-NNN` suffix and increments it), so whatever `serviceId` you send in a `POST` body is ignored/overwritten. `category` must match one of the four department labels in `web/src/constants/departments.ts` (`Police Department`, `Finance Department`, `Transport Department`, `Civil Department`'s mapped category) for the web app's department-scoping filters to work — the backend does not validate or constrain this value at all.

### `EligibilityRule`
```json
{ "id": 0, "serviceProcedureId": 0, "field": "Age | Citizenship", "operator": ">= | == | <= | !=", "value": "", "isStrict": true }
```
**Only `Age` and `Citizenship` are actually evaluated** by `CalculateEligibilityScoreAsync` (`Age` supports `>=`/`==`, `Citizenship` supports `==` only) — any other `field` value always fails evaluation (`EvaluateRule` returns `false` for unrecognized fields). `isStrict` is stored but not read by the scoring logic at all.

### `DocumentRequirement`
```json
{ "id": 0, "serviceProcedureId": 0, "documentName": "", "description": "", "isMandatory": true }
```

### `FeeSchedule`
```json
{ "id": 0, "serviceProcedureId": 0, "feeType": "", "amount": 0, "effectiveDate": "2026-01-01T00:00:00Z" }
```

### `EligibilityRequestDto` / `EligibilityScoreResultDto`
```json
// Request
{ "serviceId": 0, "citizenProfile": { "age": 0, "citizenship": "", "monthlyIncome": 0 } }
// Response
{ "matchPercentage": 0.0, "isEligible": true, "missingCriteria": ["Failed requirement: Age >= 18"] }
```
`monthlyIncome` is accepted but never used by `EvaluateRule` — there is no income-based eligibility rule support despite the field existing.

---

## Templates — `TemplateController`, `api/templates`

**Auth: None** on any action (officer-created dynamic application forms — see `docs/adr/0006-optional-template-service-link.md`).

| Method | Path | Body → Response |
|---|---|---|
| POST | `/api/templates/create` | [`CreateTemplateRequest`](#createtemplaterequest) → `201` with `Template` |
| GET | `/api/templates/all` | → `Template[]` (each with `fields` ordered by `orderIndex`, and `serviceProcedure` if linked) |
| GET | `/api/templates/{id}` | → `Template` or `404` |
| PUT | `/api/templates/update/{id}` | `CreateTemplateRequest` (full replace, including all fields) → `Template` or `500` |
| PATCH | `/api/templates/{id}/status` | `{ "status": "Active" \| "Inactive" \| "Draft" }` → `Template` or `400` |
| DELETE | `/api/templates/{id}` | → `204` or `404` |

### `CreateTemplateRequest`
```json
{
  "formName": "string",
  "subTitle": "string | null",
  "lawText": "string | null",
  "serviceProcedureId": 0,
  "fields": [ { "label": "", "type": "", "options": null, "required": false } ]
}
```
`fields` is a **full replace** on update — there's no per-field patch; the frontend always sends the complete current field list. `serviceProcedureId` may be `null` to leave the template unlinked from the Service Catalog.

`type` is a free-form string on the backend; the frontend (`TemplateBuilder.tsx`) constrains it to one of: `text`, `textarea`, `number`, `select`, `multiselect`, `date`, `file`, `heading`, `paragraph`, `table`.

---

## Verification — `VerificationController`, `api/verification`

**Auth: `[Authorize]` on every action** — the only controller that actually enforces this. "Current officer" is read from the JWT's `sub` claim (inbound-mapped by ASP.NET Core to `ClaimTypes.NameIdentifier`) — there is no role check beyond "has a valid, non-revoked token."

| Method | Path | Body → Response |
|---|---|---|
| GET | `/api/verification/tasks/pending` | → `VerificationTask[]` where `Status == "Pending"`, oldest first |
| GET | `/api/verification/stats` | → [`OfficerStatsDto`](#officerstatsdto) for the calling officer |
| POST | `/api/verification/tasks` | `{ "applicationId": 0 }` → created `VerificationTask` |
| GET | `/api/verification/audit-logs?applicationId=X` | → `AuditLog[]` for that application, newest first |
| GET | `/api/verification/audit-logs/all` | → all `AuditLog[]`, newest first |
| PUT | `/api/verification/tasks/{id}/decision` | [`VerificationDecisionRequest`](#verificationdecisionrequest) → `200` or `404` |
| DELETE | `/api/verification/tasks/{id}` | → `204` or `404` |
| POST | `/api/verification/tasks/bulk-verify` | [`BulkVerifyRequest`](#bulkverifyrequest) → `200` or `400` |

### `VerificationDecisionRequest`
```json
{ "status": "Approved | Rejected | Revised", "comments": "string | null", "rejectionReasonId": 0 }
```
Recording a decision writes an `OfficerReview` row (with the caller's officer ID and timestamp) and an `AuditLog` row in the same DB transaction as the status update.

### `BulkVerifyRequest`
```json
{ "taskIds": [1, 2, 3], "status": "Approved | Rejected | Revised", "comments": "string | null" }
```
Applies the same status + `OfficerReview` + `AuditLog` write to every task ID in one transaction; **silently skips IDs that don't exist** rather than failing the whole batch (no per-ID error reporting).

### `OfficerStatsDto`
```json
{ "reviewedToday": 0, "reviewedYesterday": 0, "approvedThisMonth": 0, "approvalRate": 66.7 }
```
`approvalRate` is `null` when the officer has no `Approved`/`Rejected` decisions yet (avoids a division-by-zero rather than reporting a misleading `0`).

### What's *not* here
`VerificationTask.ApplicationId` doesn't reference a real `Application` entity — see `docs/diagrams/er-diagram.md`'s "Notes on real gaps." A verification task today is created directly against an arbitrary integer ID, not a citizen-submitted case, because Component B (Application & Case Management) isn't built yet.
