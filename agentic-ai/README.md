# Agentic AI Service — Navigator Agent Workflow

Scaffolding for the four-agent "Navigator Agent Workflow" described in
`/docs/Government_Service_Navigator_Project_Plan.md` (§2). This service runs
as its own deployable, wired into the ASP.NET Core backend, and is started
after the API and database (see startup order in §5.1 of the project plan).

## Objective

> "Help this citizen complete [X] procedure."

## Pipeline

1. **Intake & Planning Agent** — parses the citizen's free-text need into a
   structured plan.
2. **Eligibility & Document Analysis Agent** — checks eligibility rules and
   missing documents against the plan.
3. **Action/Tool Agent** — drafts the application: pre-fills fields,
   calculates fees, proposes an appointment slot.
4. **Validation & Safety Agent** — runs deterministic checks and prepares
   the case for human approval.

Final submission into the officer's queue requires human approval from a
Verifying Officer (see §2 of the project plan, "High-impact action requiring
human approval").

## Layout

- `agents/` — one folder per agent in the pipeline above.
- `tools/` — the tool functions agents call (catalog search, eligibility
  rules, fee calculation, appointment lookup, schema validation, etc).
- `orchestration/` — wires the agents into the plan → approve pipeline.
- `schemas/` — shared data contracts passed between agents.
- `state/` — persistence for workflow execution state (`WorkflowExecutions`).
- `config/` — environment and provider configuration.
- `tests/` — golden-case and unit tests for agent evaluation.

No implementation yet — framework/language choice is tracked as an ADR
(project plan §5.2, decision 3) and build-out is scheduled for Week 4
(project plan §4).
