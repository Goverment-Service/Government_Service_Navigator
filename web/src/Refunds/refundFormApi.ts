import { API_BASE } from "../lib/apiBase";

export interface RefundFormView {
  transactionReference: string;
  amount: number;
  currency: string;
  status: string;
  alreadySubmitted: boolean;
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

export async function fetchRefundForm(token: string): Promise<RefundFormView> {
  const res = await fetch(`${API_BASE}/payments/refunds/form/${token}`);
  return handle<RefundFormView>(res);
}

export async function submitRefundForm(
  token: string,
  form: { accountHolderName: string; bankName: string; branchName: string; accountNumber: string; reason: string }
): Promise<void> {
  const res = await fetch(`${API_BASE}/payments/refunds/form/${token}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(form),
  });
  await handle(res);
}
