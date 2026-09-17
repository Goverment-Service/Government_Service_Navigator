import { apiFetch } from "../utils/api";

// ── Types ────────────────────────────────────────────────────────────────────

export type RefundStatus =
  | "Pending"
  | "Approved"
  | "Rejected"
  | "Processing"
  | "Completed"
  | "Failed";

export interface RefundResponse {
  id: number;
  paymentId: number;
  refundAmount: number;
  reason: string;
  status: RefundStatus;
  refundTransactionRef: string | null;
  requestedByEmail: string;
  decidedByEmail: string | null;
  decisionNote: string | null;
  requestedDate: string;
  decidedDate: string | null;
  completedDate: string | null;
}

export interface RefundStatusResponse {
  id: number;
  status: RefundStatus;
}

// ── API functions ─────────────────────────────────────────────────────────────

// POST /api/refunds
export function createRefund(
  paymentId: number,
  refundAmount: number,
  reason: string
): Promise<RefundResponse> {
  return apiFetch("/api/refunds", {
    method: "POST",
    body: JSON.stringify({ paymentId, refundAmount, reason }),
  });
}

// GET /api/refunds/{id}
export function getRefundById(id: number): Promise<RefundResponse> {
  return apiFetch(`/api/refunds/${id}`);
}

// GET /api/refunds/{id}/status
export function getRefundStatus(id: number): Promise<RefundStatusResponse> {
  return apiFetch(`/api/refunds/${id}/status`);
}

// POST /api/refunds/{id}/approve
export function approveRefund(id: number, note?: string): Promise<RefundResponse> {
  return apiFetch(`/api/refunds/${id}/approve`, {
    method: "POST",
    body: JSON.stringify({ note: note ?? null }),
  });
}

// POST /api/refunds/{id}/reject
export function rejectRefund(id: number, note?: string): Promise<RefundResponse> {
  return apiFetch(`/api/refunds/${id}/reject`, {
    method: "POST",
    body: JSON.stringify({ note: note ?? null }),
  });
}

// POST /api/refunds/{id}/process
export function processRefund(
  id: number,
  transactionRef: string
): Promise<RefundResponse> {
  return apiFetch(`/api/refunds/${id}/process`, {
    method: "POST",
    body: JSON.stringify({ transactionRef }),
  });
}

// POST /api/refunds/{id}/complete
export function completeRefund(id: number): Promise<RefundResponse> {
  return apiFetch(`/api/refunds/${id}/complete`, { method: "POST" });
}
