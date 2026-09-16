import { API_BASE } from "../lib/apiBase";

export type PaymentMethod = "BankTransfer" | "Stripe";
export type PaymentStatus =
  | "Pending"
  | "Verified"
  | "Paid"
  | "Rejected"
  | "Failed"
  | "Refunded"
  | "PartiallyRefunded";

export const PAYMENT_METHOD_LABELS: Record<PaymentMethod, string> = {
  BankTransfer: "Bank Transfer / Deposit",
  Stripe: "Online Payment (Stripe)",
};

export interface RefundInfo {
  id: number;
  paymentId: number;
  transactionReference: string;
  userFullName: string;
  userEmail: string;
  paymentAmount: number;
  currency: string;
  status: string;
  requestedAt: string;
  accountHolderName?: string;
  bankName?: string;
  branchName?: string;
  accountNumber?: string;
  reason?: string;
  formSubmittedAt?: string;
  processedByOfficerName?: string;
  processedAt?: string;
  processingNotes?: string;
  refundAmount?: number;
}

export interface Payment {
  id: number;
  transactionReference: string;
  userId: number;
  userFullName: string;
  userEmail: string;
  applicationId?: string;
  serviceName: string;
  method: PaymentMethod;
  amount: number;
  currency: string;
  status: PaymentStatus;
  bankName?: string;
  branchName?: string;
  accountNumber?: string;
  referenceNumber?: string;
  paymentDate?: string;
  slipFileName?: string;
  slipUploadedAt?: string;
  hasSlip: boolean;
  stripePaymentIntentId?: string;
  stripeReceiptUrl?: string;
  verifiedByOfficerName?: string;
  verifiedAt?: string;
  verificationNotes?: string;
  createdAt: string;
  refundEligible: boolean;
  refund?: RefundInfo | null;
}

export interface LogBucket {
  label: string;
  periodStart: string;
  periodEnd: string;
  count: number;
  bankTransferTotal: number;
  stripeTotal: number;
  refundedTotal: number;
  total: number;
}

function authHeaders(): HeadersInit {
  const token = localStorage.getItem("officerToken");
  return token ? { Authorization: `Bearer ${token}` } : {};
}

async function handle<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let message = `Request failed (${res.status})`;
    try {
      const body = await res.json();
      message = body.message || message;
    } catch {
      // ignore
    }
    throw new Error(message);
  }
  return res.json();
}

export async function fetchPayments(filters: { status?: string; method?: string; search?: string }): Promise<Payment[]> {
  const params = new URLSearchParams();
  if (filters.status && filters.status !== "All") params.set("status", filters.status);
  if (filters.method && filters.method !== "All") params.set("method", filters.method);
  if (filters.search) params.set("search", filters.search);

  const res = await fetch(`${API_BASE}/finance/payments?${params.toString()}`, { headers: authHeaders() });
  return handle<Payment[]>(res);
}

export async function verifyPayment(id: number, decision: "Verified" | "Rejected", notes: string): Promise<Payment> {
  const res = await fetch(`${API_BASE}/finance/payments/${id}/verify`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify({ decision, notes }),
  });
  return handle<Payment>(res);
}

export async function fetchSlipObjectUrl(paymentId: number): Promise<string> {
  const res = await fetch(`${API_BASE}/finance/payments/${paymentId}/slip`, { headers: authHeaders() });
  if (!res.ok) throw new Error("Could not load payment slip.");
  const blob = await res.blob();
  return URL.createObjectURL(blob);
}

export async function fetchLogs(period: "daily" | "weekly" | "monthly" | "yearly"): Promise<LogBucket[]> {
  const res = await fetch(`${API_BASE}/finance/payments/logs?period=${period}`, { headers: authHeaders() });
  return handle<LogBucket[]>(res);
}

export async function fetchRefundRequests(status?: string): Promise<RefundInfo[]> {
  const params = status ? `?status=${status}` : "";
  const res = await fetch(`${API_BASE}/finance/refunds${params}`, { headers: authHeaders() });
  return handle<RefundInfo[]>(res);
}

export async function fetchRefundHistory(): Promise<RefundInfo[]> {
  const res = await fetch(`${API_BASE}/finance/refunds/history/all`, { headers: authHeaders() });
  return handle<RefundInfo[]>(res);
}

export async function processRefund(
  id: number,
  decision: "Approved" | "Rejected",
  refundAmount: number | undefined,
  notes: string
): Promise<RefundInfo> {
  const res = await fetch(`${API_BASE}/finance/refunds/${id}/process`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", ...authHeaders() },
    body: JSON.stringify({ decision, refundAmount, notes }),
  });
  return handle<RefundInfo>(res);
}
