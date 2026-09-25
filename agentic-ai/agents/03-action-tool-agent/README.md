# 3. Action/Tool Agent

**Responsibility:** Prepares the draft application: pre-fills form fields,
calculates fees, and proposes an appointment slot.

- **Input:** Eligibility result (`ActionDraftRequest` — applicant details + Agent 2's `EligibilityPlanResponse`)
- **Output:** Draft application object (`ActionDraftResponse` → `DraftApplication` for Agent 4)
- **Tools it may call:** `calculate_fee`, `find_appointment_slot`, `prefill_application`

## How it works

1. **Safe failure** — if Agent 2 says the citizen is not eligible, no draft is
   made; the response lists the reasons ("not eligible — missing X").
2. **Deterministic tools** (logged in `ToolCalls`):
   - `prefill_application` — maps the service's active form template fields to
     citizen data (falls back to a default template).
   - `calculate_fee` — sums the fee schedules in force; express/urgent fees only
     when requested.
   - `find_appointment_slot` — proposes (does not reserve) the earliest 30-min
     slot, Mon–Fri 09:00–15:00 Sri Lanka time, ≥2 working days ahead.
3. **RAG over the vector DB** — embeds a query with Gemini `text-embedding-004`,
   retrieves `ActionTool:*` chunks from `KnowledgeChunks` (pgvector, cosine),
   and asks Gemini to fill remaining fields *only* from citizen-supplied data
   and write officer notes. Model values not found in citizen data are discarded;
   fee and slot are never changed by the model.
4. If embedding/Gemini fails, a deterministic reasoning fallback is used.

The draft is `IsReadyForValidation` only when every required field is filled.

## Vectorizing the knowledge

`POST /api/RagSetup/seed-action-agent` embeds and stores (replacing only
`ActionTool:*` chunks):

| SourceCategory | Content |
|---|---|
| `ActionTool:Fees` | Fee schedule per service |
| `ActionTool:FormTemplate` | Active form template fields per service |
| `ActionTool:AppointmentPolicy` | Appointment policy |

Agents 1 and 2 ignore these chunks, and `POST /api/RagSetup/seed` no longer wipes them.

## API

- `POST /api/ActionAgent/draft` — run Agent 3 (runs Agent 2 first if `eligibility` is omitted)
- `POST /api/ActionAgent/orchestrate` — run the drafting stage and return `WorkflowExecutionState`
