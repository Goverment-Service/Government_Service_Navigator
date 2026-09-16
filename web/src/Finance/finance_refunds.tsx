import { useEffect, useState } from "react";
import {
  Tabs,
  TabList,
  Tab,
  TabPanels,
  TabPanel,
  TableContainer,
  Table,
  TableHead,
  TableRow,
  TableHeader,
  TableBody,
  TableCell,
  Tag,
  Button,
  Modal,
  TextArea,
  NumberInput,
  InlineNotification,
  InlineLoading,
} from "@carbon/react";
import FinanceShell from "./finance_shell";
import { fetchRefundRequests, fetchRefundHistory, processRefund, type RefundInfo } from "./financeApi";
import { formatCurrency, formatDateTime } from "./format";

function statusTagType(status: string): "blue" | "green" | "red" | "gray" {
  if (status === "Approved") return "green";
  if (status === "Rejected") return "red";
  if (status === "FormSubmitted") return "blue";
  return "gray";
}

export default function FinanceRefunds() {
  const [pending, setPending] = useState<RefundInfo[]>([]);
  const [history, setHistory] = useState<RefundInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<RefundInfo | null>(null);
  const [refundAmount, setRefundAmount] = useState<number>(0);
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [banner, setBanner] = useState<{ kind: "success" | "error"; message: string } | null>(null);

  async function reload() {
    setLoading(true);
    setError(null);
    try {
      const [p, h] = await Promise.all([fetchRefundRequests(), fetchRefundHistory()]);
      setPending(p);
      setHistory(h);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not load refund requests.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    reload();
  }, []);

  function openReview(refund: RefundInfo) {
    setSelected(refund);
    setRefundAmount(refund.paymentAmount);
    setNotes("");
    setBanner(null);
  }

  async function handleDecision(decision: "Approved" | "Rejected") {
    if (!selected) return;
    setSubmitting(true);
    try {
      await processRefund(selected.id, decision, decision === "Approved" ? refundAmount : undefined, notes);
      setBanner({
        kind: "success",
        message: decision === "Approved" ? "Refund processed and the citizen has been notified by email." : "Refund request rejected.",
      });
      await reload();
      setTimeout(() => setSelected(null), 900);
    } catch (err) {
      setBanner({ kind: "error", message: err instanceof Error ? err.message : "Could not process this refund." });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <FinanceShell active="refunds">
      <div style={{ marginBottom: '1.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Refund Requests</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>
          Citizens can request a refund within 3 days of a payment being verified/paid. Review the bank details
          they submitted through the emailed refund form, then approve or reject.
        </p>
      </div>

      {error && <InlineNotification kind="error" title="Could not load refunds" subtitle={error} lowContrast style={{ marginBottom: '1rem' }} />}

      {loading ? (
        <InlineLoading description="Loading refunds..." />
      ) : (
        <Tabs>
          <TabList aria-label="Refund tabs">
            <Tab>Pending ({pending.length})</Tab>
            <Tab>History ({history.length})</Tab>
          </TabList>
          <TabPanels>
            <TabPanel>
              <RefundTable refunds={pending} onReview={openReview} showReview />
            </TabPanel>
            <TabPanel>
              <RefundTable refunds={history} onReview={openReview} showReview={false} />
            </TabPanel>
          </TabPanels>
        </Tabs>
      )}

      <Modal
        open={selected !== null}
        modalHeading={selected ? `Refund Request - ${selected.transactionReference}` : ""}
        modalLabel="Process Refund"
        passiveModal
        onRequestClose={() => setSelected(null)}
        size="md"
      >
        {selected && (
          <div style={{ paddingBottom: '1rem' }}>
            {banner && (
              <InlineNotification kind={banner.kind} title={banner.message} lowContrast hideCloseButton style={{ marginBottom: '1rem' }} />
            )}

            <p><strong>Citizen:</strong> {selected.userFullName} ({selected.userEmail})</p>
            <p><strong>Original Payment:</strong> {formatCurrency(selected.paymentAmount, selected.currency)}</p>
            <p><strong>Requested:</strong> {formatDateTime(selected.requestedAt)}</p>
            <p><strong>Reason (request):</strong> {selected.reason || "-"}</p>

            <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', margin: '1rem 0' }}>
              <p style={{ fontWeight: 600, marginBottom: '0.5rem' }}>Refund Bank Details (from citizen's form)</p>
              {selected.formSubmittedAt ? (
                <>
                  <p>{selected.accountHolderName}</p>
                  <p>{selected.bankName} &middot; {selected.branchName}</p>
                  <p>Account: {selected.accountNumber}</p>
                </>
              ) : (
                <p style={{ color: '#da1e28' }}>The citizen has not yet submitted the refund form.</p>
              )}
            </div>

            {(selected.status === "Requested" || selected.status === "FormSubmitted") ? (
              <>
                <NumberInput
                  id="refund-amount"
                  label="Refund Amount"
                  min={0}
                  max={selected.paymentAmount}
                  step={0.01}
                  value={refundAmount}
                  onChange={(_e, { value }) => setRefundAmount(Number(value) || 0)}
                />
                <TextArea
                  id="refund-notes"
                  labelText="Processing Notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                  style={{ marginTop: '1rem' }}
                />
                <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1rem' }}>
                  <Button kind="danger--tertiary" disabled={submitting} onClick={() => handleDecision("Rejected")}>
                    Reject
                  </Button>
                  <Button
                    kind="primary"
                    disabled={submitting || !selected.formSubmittedAt}
                    onClick={() => handleDecision("Approved")}
                  >
                    Approve &amp; Process Refund
                  </Button>
                </div>
              </>
            ) : (
              <div style={{ marginTop: '1rem' }}>
                <Tag type={statusTagType(selected.status)}>{selected.status}</Tag>
                <p style={{ marginTop: '0.5rem', color: '#525252' }}>
                  {selected.processedByOfficerName} on {formatDateTime(selected.processedAt)}
                </p>
                {selected.processingNotes && <p>{selected.processingNotes}</p>}
              </div>
            )}
          </div>
        )}
      </Modal>
    </FinanceShell>
  );
}

function RefundTable({
  refunds,
  onReview,
  showReview,
}: {
  refunds: RefundInfo[];
  onReview: (r: RefundInfo) => void;
  showReview: boolean;
}) {
  return (
    <TableContainer>
      <Table>
        <TableHead>
          <TableRow>
            <TableHeader>Reference</TableHeader>
            <TableHeader>Citizen</TableHeader>
            <TableHeader>Amount</TableHeader>
            <TableHeader>Status</TableHeader>
            <TableHeader>Requested</TableHeader>
            <TableHeader></TableHeader>
          </TableRow>
        </TableHead>
        <TableBody>
          {refunds.length === 0 ? (
            <TableRow>
              <TableCell colSpan={6} style={{ textAlign: 'center', padding: '2rem' }}>No refund requests.</TableCell>
            </TableRow>
          ) : (
            refunds.map((r) => (
              <TableRow key={r.id}>
                <TableCell>{r.transactionReference}</TableCell>
                <TableCell>{r.userFullName}</TableCell>
                <TableCell>{formatCurrency(r.refundAmount ?? r.paymentAmount, r.currency)}</TableCell>
                <TableCell><Tag type={statusTagType(r.status)}>{r.status}</Tag></TableCell>
                <TableCell>{formatDateTime(r.requestedAt)}</TableCell>
                <TableCell style={{ textAlign: 'right' }}>
                  <Button size="sm" kind="tertiary" onClick={() => onReview(r)}>
                    {showReview ? "Review" : "View"}
                  </Button>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
