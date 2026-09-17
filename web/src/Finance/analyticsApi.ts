import { apiFetch } from "../utils/api";

// ── Types ────────────────────────────────────────────────────────────────────

export interface DailyAnalytics {
  date: string;
  totalPayments: number;
  totalAmount: number;
  pendingCount: number;
  failedCount: number;
}

export interface WeeklyAnalytics {
  weekStart: string;
  totalPayments: number;
  totalAmount: number;
  pendingCount: number;
  failedCount: number;
}

export interface MonthlyAnalytics {
  year: number;
  month: number;
  totalPayments: number;
  totalAmount: number;
  pendingCount: number;
  failedCount: number;
}

export interface YearlyAnalytics {
  year: number;
  totalPayments: number;
  totalAmount: number;
  pendingCount: number;
  failedCount: number;
}

export interface ReportSnapshot {
  id: number;
  period: string;
  generatedDate: string;
  data: string; // raw JSON blob stored by the backend
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
export function getDailyAnalytics(date: string): Promise<DailyAnalytics> {
  return apiFetch(`/api/analytics/daily?date=${encodeURIComponent(date)}`);
}

// GET /api/analytics/weekly?weekStart=YYYY-MM-DD
export function getWeeklyAnalytics(weekStart: string): Promise<WeeklyAnalytics> {
  return apiFetch(
    `/api/analytics/weekly?weekStart=${encodeURIComponent(weekStart)}`
  );
}

// GET /api/analytics/monthly?year=YYYY&month=M
export function getMonthlyAnalytics(
  year: number,
  month: number
): Promise<MonthlyAnalytics> {
  return apiFetch(`/api/analytics/monthly?year=${year}&month=${month}`);
}

// GET /api/analytics/yearly?year=YYYY
export function getYearlyAnalytics(year: number): Promise<YearlyAnalytics> {
  return apiFetch(`/api/analytics/yearly?year=${year}`);
}

// ── Report Snapshots ──────────────────────────────────────────────────────────

// POST /api/report-snapshots
export function createReportSnapshot(
  period: string,
  data: object
): Promise<ReportSnapshot> {
  return apiFetch("/api/report-snapshots", {
    method: "POST",
    body: JSON.stringify({ period, data: JSON.stringify(data) }),
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

// POST /api/anomalies/scan  (triggers rule-based scan)
export function runAnomalyScan(): Promise<AnomalyFlag[]> {
  return apiFetch("/api/anomalies/scan", { method: "POST" });
}

// GET /api/anomalies/open
export function getOpenAnomalyFlags(): Promise<AnomalyFlag[]> {
  return apiFetch("/api/anomalies/open");
}

// POST /api/anomalies/{id}/resolve
export function resolveAnomalyFlag(
  id: number,
  status: "Reviewed" | "Dismissed"
): Promise<AnomalyFlag> {
  return apiFetch(`/api/anomalies/${id}/resolve`, {
    method: "POST",
    body: JSON.stringify({ status }),
  });
}
