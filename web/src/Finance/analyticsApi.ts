import { apiFetch } from "../utils/api";

// ── Types ─────────────────────────────────────────────────────────────────────

// All four analytics endpoints (daily / weekly / monthly / yearly) return the
// same UsageAggregateDto shape from the backend.
export interface UsageAggregate {
  period: string;             // e.g. "2026-09-17", "Week of 2026-09-11", "2026-09", "2026"
  totalApplications: number;
  approvedCount: number;
  rejectedCount: number;
  averageProcessingHours: number;
}

export interface ReportSnapshot {
  id: number;
  title: string;
  period: string;
  generatedDate: string;  // ISO 8601
  dataJson: string;       // serialised JSON blob
  generatedByEmail: string;
}

export interface AnomalyFlag {
  id: number;
  paymentId: number | null;
  anomalyType: string;
  description: string;
  status: string; // "Open" | "Reviewed" | "Dismissed"
  detectedDate: string;
  reviewedByEmail: string | null;
  reviewedDate: string | null;
}

// ── Analytics ─────────────────────────────────────────────────────────────────

// GET /api/analytics/daily?date=YYYY-MM-DD
export function getDailyAnalytics(date: string): Promise<UsageAggregate> {
  return apiFetch(`/api/analytics/daily?date=${encodeURIComponent(date)}`);
}

// GET /api/analytics/weekly?weekStart=YYYY-MM-DD
export function getWeeklyAnalytics(weekStart: string): Promise<UsageAggregate> {
  return apiFetch(
    `/api/analytics/weekly?weekStart=${encodeURIComponent(weekStart)}`
  );
}

// GET /api/analytics/monthly?year=YYYY&month=M
export function getMonthlyAnalytics(year: number, month: number): Promise<UsageAggregate> {
  return apiFetch(`/api/analytics/monthly?year=${year}&month=${month}`);
}

// GET /api/analytics/yearly?year=YYYY
export function getYearlyAnalytics(year: number): Promise<UsageAggregate> {
  return apiFetch(`/api/analytics/yearly?year=${year}`);
}

// ── Report Snapshots ──────────────────────────────────────────────────────────

// POST /api/report-snapshots  —  body: { title, period, dataJson }
export function createReportSnapshot(
  title: string,
  period: string,
  data: object
): Promise<ReportSnapshot> {
  return apiFetch("/api/report-snapshots", {
    method: "POST",
    body: JSON.stringify({ title, period, dataJson: JSON.stringify(data) }),
  });
}

// GET /api/report-snapshots
export function getReportSnapshots(): Promise<ReportSnapshot[]> {
  return apiFetch("/api/report-snapshots");
}

// DELETE /api/report-snapshots/{id}
export function deleteReportSnapshot(id: number): Promise<void> {
  return apiFetch(`/api/report-snapshots/${id}`, { method: "DELETE" });
}

// ── Anomaly Detection ─────────────────────────────────────────────────────────

// POST /api/anomalies/scan
export function runAnomalyScan(): Promise<AnomalyFlag[]> {
  return apiFetch("/api/anomalies/scan", { method: "POST" });
}

// GET /api/anomalies/open
export function getOpenAnomalyFlags(): Promise<AnomalyFlag[]> {
  return apiFetch("/api/anomalies/open");
}

// POST /api/anomalies/{id}/resolve  — body: { status }
export function resolveAnomalyFlag(
  id: number,
  status: "Reviewed" | "Dismissed"
): Promise<AnomalyFlag> {
  return apiFetch(`/api/anomalies/${id}/resolve`, {
    method: "POST",
    body: JSON.stringify({ status }),
  });
}
