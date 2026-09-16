import { useEffect, useMemo, useState } from "react";
import jsPDF from "jspdf";
import { ContentSwitcher, Switch, Button, TableContainer, Table, TableHead, TableRow, TableHeader, TableBody, TableCell, InlineLoading, InlineNotification } from "@carbon/react";
import { DocumentPdf } from "@carbon/icons-react";
import FinanceShell from "./finance_shell";
import { fetchLogs, type LogBucket } from "./financeApi";
import { formatCurrency } from "./format";

type LedgerPeriod = "daily" | "weekly" | "monthly" | "yearly";

const PERIODS: { key: LedgerPeriod; label: string; description: string }[] = [
  { key: "daily", label: "Daily", description: "Last 14 days" },
  { key: "weekly", label: "Weekly", description: "Last 12 weeks" },
  { key: "monthly", label: "Monthly", description: "Last 12 months" },
  { key: "yearly", label: "Yearly", description: "Last 5 years" },
];

export default function FinanceLedger() {
  const [period, setPeriod] = useState<LedgerPeriod>("monthly");
  const [entries, setEntries] = useState<LogBucket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetchLogs(period)
      .then((data) => {
        if (!cancelled) setEntries(data);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Could not load the ledger.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [period]);

  const grandTotal = useMemo(() => entries.reduce((acc, e) => acc + e.total, 0), [entries]);
  const activePeriodMeta = PERIODS.find((p) => p.key === period)!;

  function exportPdf() {
    const doc = new jsPDF();
    const marginX = 15;
    let y = 20;

    doc.setFontSize(16);
    doc.text("Government Service Navigator - Payment Log / Account Ledger", marginX, y);
    y += 7;

    doc.setFontSize(10);
    doc.setTextColor(90);
    doc.text(
      `${activePeriodMeta.label} log (${activePeriodMeta.description}) - generated ${new Date().toLocaleString()}`,
      marginX,
      y
    );
    y += 10;

    doc.setDrawColor(200);
    doc.line(marginX, y, 195, y);
    y += 8;

    const columns = [
      { label: "Period", x: marginX },
      { label: "Bank Transfer", x: marginX + 42 },
      { label: "Stripe", x: marginX + 78 },
      { label: "Refunded", x: marginX + 108 },
      { label: "Payments", x: marginX + 140 },
      { label: "Total", x: marginX + 165 },
    ];

    doc.setFontSize(9);
    doc.setTextColor(0);
    doc.setFont("helvetica", "bold");
    columns.forEach((col) => doc.text(col.label, col.x, y));
    y += 5;
    doc.setDrawColor(220);
    doc.line(marginX, y, 195, y);
    y += 5;

    doc.setFont("helvetica", "normal");
    entries.forEach((entry) => {
      if (y > 275) {
        doc.addPage();
        y = 20;
      }
      doc.text(entry.label, columns[0].x, y);
      doc.text(entry.bankTransferTotal.toLocaleString(), columns[1].x, y);
      doc.text(entry.stripeTotal.toLocaleString(), columns[2].x, y);
      doc.text(entry.refundedTotal.toLocaleString(), columns[3].x, y);
      doc.text(String(entry.count), columns[4].x, y);
      doc.text(entry.total.toLocaleString(), columns[5].x, y);
      y += 6;
    });

    y += 2;
    doc.setDrawColor(0);
    doc.line(marginX, y, 195, y);
    y += 7;

    doc.setFont("helvetica", "bold");
    doc.setFontSize(11);
    doc.text(`Grand Total: ${formatCurrency(grandTotal)}`, marginX, y);

    doc.save(`payment_log_${period}_${new Date().toISOString().slice(0, 10)}.pdf`);
  }

  return (
    <FinanceShell active="ledger">
      <div
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}
      >
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Payment Logs &amp; Account Ledger</h1>
          <p style={{ color: '#525252', marginTop: '0.5rem' }}>
            Verified/Paid fee receipts booked by period, broken down by payment method, with refunds netted out.
          </p>
        </div>
        <Button renderIcon={DocumentPdf} onClick={exportPdf} disabled={loading || entries.length === 0}>
          Export PDF
        </Button>
      </div>

      {error && <InlineNotification kind="error" title="Could not load the ledger" subtitle={error} lowContrast style={{ marginBottom: '1rem' }} />}

      <div style={{ marginBottom: '1.5rem', maxWidth: '520px' }}>
        <ContentSwitcher
          selectedIndex={PERIODS.findIndex((p) => p.key === period)}
          onChange={({ index }) => setPeriod(PERIODS[index as number].key)}
        >
          {PERIODS.map((p) => (
            <Switch key={p.key} name={p.key} text={p.label} />
          ))}
        </ContentSwitcher>
        <p style={{ fontSize: '0.75rem', color: '#525252', marginTop: '0.5rem' }}>{activePeriodMeta.description}</p>
      </div>

      {loading ? (
        <InlineLoading description="Loading ledger..." />
      ) : (
        <TableContainer
          title={`${activePeriodMeta.label} Log`}
          description="Only Verified/Paid payments are recognized revenue and appear here."
        >
          <Table>
            <TableHead>
              <TableRow>
                <TableHeader>Period</TableHeader>
                <TableHeader>Bank Transfer</TableHeader>
                <TableHeader>Stripe</TableHeader>
                <TableHeader>Refunded</TableHeader>
                <TableHeader>Payments</TableHeader>
                <TableHeader>Total</TableHeader>
              </TableRow>
            </TableHead>
            <TableBody>
              {entries.map((entry) => (
                <TableRow key={entry.label}>
                  <TableCell>{entry.label}</TableCell>
                  <TableCell>{formatCurrency(entry.bankTransferTotal)}</TableCell>
                  <TableCell>{formatCurrency(entry.stripeTotal)}</TableCell>
                  <TableCell>{formatCurrency(entry.refundedTotal)}</TableCell>
                  <TableCell>{entry.count}</TableCell>
                  <TableCell style={{ fontWeight: 600 }}>{formatCurrency(entry.total)}</TableCell>
                </TableRow>
              ))}
              <TableRow>
                <TableCell style={{ fontWeight: 700 }}>Grand Total</TableCell>
                <TableCell style={{ fontWeight: 700 }}>
                  {formatCurrency(entries.reduce((acc, e) => acc + e.bankTransferTotal, 0))}
                </TableCell>
                <TableCell style={{ fontWeight: 700 }}>
                  {formatCurrency(entries.reduce((acc, e) => acc + e.stripeTotal, 0))}
                </TableCell>
                <TableCell style={{ fontWeight: 700 }}>
                  {formatCurrency(entries.reduce((acc, e) => acc + e.refundedTotal, 0))}
                </TableCell>
                <TableCell style={{ fontWeight: 700 }}>{entries.reduce((acc, e) => acc + e.count, 0)}</TableCell>
                <TableCell style={{ fontWeight: 700 }}>{formatCurrency(grandTotal)}</TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </FinanceShell>
  );
}
