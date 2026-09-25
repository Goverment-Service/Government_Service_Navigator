# Tool: prefill_application

Used by: Action/Tool Agent.

`PrefillApplicationTool` — maps the active form template's fields for the
service (`IApplicationTemplateRepository`, backend: `ApplicationTemplateRepository`)
to citizen data by label. Never invents values; unmatched required fields are
reported as `UnfilledRequiredFields`.
