import type { Payment } from "./financeData";

export type LedgerPeriod = "daily" | "weekly" | "monthly" | "yearly";

export interface LedgerEntry {
  label: string;
  start: Date;
  end: Date;
  count: number;
  onlineBankTransferTotal: number;
  bankDepositTotal: number;
  onlinePayTotal: number;
  total: number;
}

function startOfWeek(date: Date): Date {
  const d = new Date(date);
  const diff = (7 + (d.getDay() - 1)) % 7; // Monday = start of week
  d.setDate(d.getDate() - diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function endOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(23, 59, 59, 999);
  return d;
}

interface Bucket {
  label: string;
  start: Date;
  end: Date;
}

function buildBuckets(period: LedgerPeriod, referenceDate: Date): Bucket[] {
  const buckets: Bucket[] = [];
  const ref = startOfDay(referenceDate);

  if (period === "daily") {
    for (let i = 13; i >= 0; i--) {
      const day = new Date(ref);
      day.setDate(day.getDate() - i);
      buckets.push({
        label: day.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }),
        start: startOfDay(day),
        end: endOfDay(day),
      });
    }
  } else if (period === "weekly") {
    const currentWeekStart = startOfWeek(ref);
    for (let i = 11; i >= 0; i--) {
      const weekStart = new Date(currentWeekStart);
      weekStart.setDate(weekStart.getDate() - 7 * i);
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekEnd.getDate() + 6);
      buckets.push({
        label: `${weekStart.toLocaleDateString(undefined, { month: "short", day: "numeric" })} - ${weekEnd.toLocaleDateString(
          undefined,
          { month: "short", day: "numeric" }
        )}`,
        start: startOfDay(weekStart),
        end: endOfDay(weekEnd),
      });
    }
  } else if (period === "yearly") {
    for (let i = 4; i >= 0; i--) {
      const year = ref.getFullYear() - i;
      buckets.push({
        label: `${year}`,
        start: new Date(year, 0, 1, 0, 0, 0, 0),
        end: new Date(year, 11, 31, 23, 59, 59, 999),
      });
    }
  } else {
    const anchor = new Date(ref.getFullYear(), ref.getMonth(), 1);
    for (let i = 11; i >= 0; i--) {
      const monthStart = new Date(anchor.getFullYear(), anchor.getMonth() - i, 1);
      const monthEnd = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0, 23, 59, 59, 999);
      buckets.push({
        label: monthStart.toLocaleDateString(undefined, { month: "short", year: "numeric" }),
        start: monthStart,
        end: monthEnd,
      });
    }
  }

  return buckets;
}

// The ledger only ever books payments the Finance Officer has verified - a
// Pending or Rejected payment isn't recognized revenue yet.
export function buildLedger(payments: Payment[], period: LedgerPeriod, referenceDate: Date = new Date()): LedgerEntry[] {
  const verified = payments.filter((p) => p.status === "Verified" && p.verifiedAt);
  const buckets = buildBuckets(period, referenceDate);

  return buckets.map((bucket) => {
    const inBucket = verified.filter((p) => {
      const verifiedAt = new Date(p.verifiedAt as string);
      return verifiedAt >= bucket.start && verifiedAt <= bucket.end;
    });

    return {
      label: bucket.label,
      start: bucket.start,
      end: bucket.end,
      count: inBucket.length,
      onlineBankTransferTotal: sumByMethod(inBucket, "OnlineBankTransfer"),
      bankDepositTotal: sumByMethod(inBucket, "BankDeposit"),
      onlinePayTotal: sumByMethod(inBucket, "OnlinePay"),
      total: inBucket.reduce((acc, p) => acc + p.amount, 0),
    };
  });
}

function sumByMethod(payments: Payment[], method: Payment["method"]): number {
  return payments.filter((p) => p.method === method).reduce((acc, p) => acc + p.amount, 0);
}
