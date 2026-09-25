# Tool: calculate_fee

Used by: Action/Tool Agent.

`CalculateFeeTool` — sums the service's `FeeSchedules` in force (latest revision
per fee type). Express/urgent/one-day fees are only applied when requested.
Data comes from `IFeeScheduleRepository` (backend: `FeeScheduleRepository`).
