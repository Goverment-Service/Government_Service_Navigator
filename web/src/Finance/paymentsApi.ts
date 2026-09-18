import { apiFetch } from "../utils/api";

// ── Types ────────────────────────────────────────────────────────────────────

export interface LedgerEntry {
  type: string;
  amount: number;
  date: string;
  description: string;
}

export interface PaymentLedger {
  paymentId: number;
  originalAmount: number;
  totalRefunded: number;
  runningBalance: number;
  status: string;
  entries: LedgerEntry[];
}

export interface InstallmentResponse {
  id: number;
  installmentNumber: number;
  amount: number;
  dueDate: string;
  status: string; // "Pending" | "Paid" | "Overdue"
  paidDate: string | null;
}

export interface InstallmentPlanResponse {
  id: number;
  paymentId: number;
  numberOfInstallments: number;
  totalAmount: number;
  status: string; // "Active" | "Completed" | "Cancelled"
  installments: InstallmentResponse[];
}

// ── Payments ──────────────────────────────────────────────────────────────────

// GET /api/payments/{id}/ledger
export function getPaymentLedger(paymentId: number): Promise<PaymentLedger> {
  return apiFetch(`/api/payments/${paymentId}/ledger`);
}

// POST /api/payments/{id}/verify
export function verifyPayment(
  paymentId: number,
  approved: boolean,
  note?: string
): Promise<unknown> {
  return apiFetch(`/api/payments/${paymentId}/verify`, {
    method: "POST",
    body: JSON.stringify({ approved, note: note ?? null }),
  });
}

// ── Installment Plans ─────────────────────────────────────────────────────────

// PUT /api/payments/{id}/installment-plan
export function createInstallmentPlan(
  paymentId: number,
  numberOfInstallments: number,
  intervalDays: number
): Promise<InstallmentPlanResponse> {
  return apiFetch(`/api/payments/${paymentId}/installment-plan`, {
    method: "PUT",
    body: JSON.stringify({ numberOfInstallments, intervalDays }),
  });
}

// GET /api/installment-plans/{id}
export function getInstallmentPlan(
  planId: number
): Promise<InstallmentPlanResponse> {
  return apiFetch(`/api/installment-plans/${planId}`);
}

// POST /api/installment-plans/installments/{installmentId}/pay
export function payInstallment(
  installmentId: number
): Promise<InstallmentResponse> {
  return apiFetch(
    `/api/installment-plans/installments/${installmentId}/pay`,
    { method: "POST" }
  );
}

// POST /api/installment-plans/{id}/cancel
export function cancelInstallmentPlan(
  planId: number
): Promise<InstallmentPlanResponse> {
  return apiFetch(`/api/installment-plans/${planId}/cancel`, {
    method: "POST",
  });
}
