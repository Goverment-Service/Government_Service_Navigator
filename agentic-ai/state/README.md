# Workflow State Persistence

Persists workflow execution state to a `WorkflowExecutions` (or similar)
PostgreSQL table — not in hidden reasoning (project plan §2). Fields:
workflow ID, objective, plan, each agent's output, tool call results,
validation results, approval decision, final outcome.

Not implemented yet — storage strategy (JSONB column vs normalized tables)
is tracked as an ADR (project plan §5.2, decision 4).
