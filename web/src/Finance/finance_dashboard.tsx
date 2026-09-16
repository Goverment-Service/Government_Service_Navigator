import { useEffect, useMemo, useState } from "react";
import {
  Grid,
  Column,
  Tile,
  DataTable,
  TableContainer,
  Table,
  TableHead,
  TableRow,
  TableHeader,
  TableBody,
  TableCell,
  TableToolbar,
  TableToolbarContent,
  TableToolbarSearch,
  ContentSwitcher,
  Switch,
  Select,
  SelectItem,
  Tag,
  Button,
  Modal,
  TextArea,
  InlineNotification,
  InlineLoading,
} from "@carbon/react";
import { Hourglass, CheckmarkOutline, MisuseOutline, Money } from "@carbon/icons-react";
import FinanceShell from "./finance_shell";
import {
  fetchPayments,
  verifyPayment,
  fetchSlipObjectUrl,
  PAYMENT_METHOD_LABELS,
  type Payment,
  type PaymentMethod,
  type PaymentStatus,
} from "./financeApi";
import { formatCurrency, formatDate, formatDateTime } from "./format";

const METHOD_FILTERS: { key: "All" | PaymentMethod; label: string }[] = [
  { key: "All", label: "All Methods" },
  { key: "BankTransfer", label: "Bank Transfer" },
  { key: "Stripe", label: "Online (Stripe)" },
];

const headers = [
  { key: "id", header: "Payment ID" },
  { key: "reference", header: "Reference" },
  { key: "user", header: "Citizen" },
  { key: "method", header: "Method" },
  { key: "amount", header: "Amount" },
  { key: "status", header: "Status" },
  { key: "submitted", header: "Submitted" },
  { key: "actions", header: "" },
];

function statusTagType(status: PaymentStatus): "blue" | "green" | "red" | "purple" | "gray" {
  if (status === "Verified" || status === "Paid") return "green";
  if (status === "Rejected" || status === "Failed") return "red";
  if (status === "Refunded" || status === "PartiallyRefunded") return "purple";
  if (status === "Pending") return "blue";
  return "gray";
}

function methodTagType(method: PaymentMethod): "purple" | "teal" {
  return method === "BankTransfer" ? "teal" : "purple";
}

export default function FinanceDashboard() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [methodFilter, setMethodFilter] = useState<"All" | PaymentMethod>("All");
  const [statusFilter, setStatusFilter] = useState<"All" | PaymentStatus>("All");
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);
  const [notes, setNotes] = useState("");
  const [banner, setBanner] = useState<{ kind: "success" | "error"; message: string } | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [slipUrl, setSlipUrl] = useState<string | null>(null);
  const [slipLoading, setSlipLoading] = useState(false);

  async function reload() {
    setLoading(true);
    setLoadError(null);
    try {
      const data = await fetchPayments({});
      setPayments(data);
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : "Could not load payments.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    reload();
  }, []);

  const stats = useMemo(() => {
    const pending = payments.filter((p) => p.status === "Pending").length;
    const verifiedToday = payments.filter(
      (p) =>
        (p.status === "Verified" || p.status === "Paid") &&
        p.verifiedAt &&
        new Date(p.verifiedAt).toDateString() === new Date().toDateString()
    ).length;
    const rejected = payments.filter((p) => p.status === "Rejected" || p.status === "Failed").length;
    const collectedThisMonth = payments
      .filter((p) => {
        if ((p.status !== "Verified" && p.status !== "Paid") || !p.verifiedAt) return false;
        const d = new Date(p.verifiedAt);
        const now = new Date();
        return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
      })
      .reduce((acc, p) => acc + p.amount, 0);
    return { pending, verifiedToday, rejected, collectedThisMonth };
  }, [payments]);

  const filteredPayments = useMemo(() => {
    return payments
      .filter((p) => methodFilter === "All" || p.method === methodFilter)
      .filter((p) => statusFilter === "All" || p.status === statusFilter)
      .filter((p) => {
        if (!searchTerm.trim()) return true;
        const term = searchTerm.trim().toLowerCase();
        return (
          p.transactionReference.toLowerCase().includes(term) ||
          (p.applicationId || "").toLowerCase().includes(term) ||
          p.userEmail.toLowerCase().includes(term) ||
          p.userFullName.toLowerCase().includes(term)
        );
      })
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }, [payments, methodFilter, statusFilter, searchTerm]);

  const rows = filteredPayments.map((p) => ({
    id: String(p.id),
    reference: p.transactionReference,
    user: `${p.userFullName} (${p.userEmail})`,
    method: p.method,
    amount: formatCurrency(p.amount, p.currency),
    status: p.status,
    submitted: formatDateTime(p.createdAt),
    actions: "",
  }));

  async function openDetails(paymentId: string) {
    const payment = payments.find((p) => String(p.id) === paymentId) || null;
    setSelectedPayment(payment);
    setNotes(payment?.verificationNotes || "");
    setBanner(null);
    setSlipUrl(null);

    if (payment?.method === "BankTransfer" && payment.hasSlip) {
      setSlipLoading(true);
      try {
        const url = await fetchSlipObjectUrl(payment.id);
        setSlipUrl(url);
      } catch {
        setSlipUrl(null);
      } finally {
        setSlipLoading(false);
      }
    }
  }

  function closeDetails() {
    setSelectedPayment(null);
    setNotes("");
    if (slipUrl) URL.revokeObjectURL(slipUrl);
    setSlipUrl(null);
  }

  async function handleDecision(decision: "Verified" | "Rejected") {
    if (!selectedPayment) return;
    setSubmitting(true);
    try {
      const updated = await verifyPayment(selectedPayment.id, decision, notes);
      setPayments((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
      setSelectedPayment(updated);
      setBanner({
        kind: decision === "Verified" ? "success" : "error",
        message:
          decision === "Verified"
            ? "Payment verified, posted to the ledger, and a receipt email was sent to the citizen."
            : "Payment rejected.",
      });
    } catch (err) {
      setBanner({ kind: "error", message: err instanceof Error ? err.message : "Could not update payment." });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <FinanceShell active="dashboard">
      <div style={{ marginBottom: '1.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Payment Verification</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>
          Review fee payments submitted by bank transfer/deposit or Stripe, and verify each bank payment against
          its uploaded slip before it is posted to the account ledger.
        </p>
      </div>

      {loadError && (
        <InlineNotification kind="error" title="Could not load payments" subtitle={loadError} lowContrast style={{ marginBottom: '1rem' }} />
      )}

      <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
        <Column sm={4} md={4} lg={4}>
          <Tile style={{ borderTop: '4px solid #0f62fe' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Pending Verification</p>
              <Hourglass size={20} color="#0f62fe" />
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{stats.pending}</h3>
            <p style={{ color: '#0f62fe', fontSize: '0.875rem', marginTop: '1rem' }}>Awaiting your review</p>
          </Tile>
        </Column>
        <Column sm={4} md={4} lg={4}>
          <Tile style={{ borderTop: '4px solid #24a148' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Verified/Paid Today</p>
              <CheckmarkOutline size={20} color="#24a148" />
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{stats.verifiedToday}</h3>
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Posted to ledger</p>
          </Tile>
        </Column>
        <Column sm={4} md={4} lg={4}>
          <Tile style={{ borderTop: '4px solid #da1e28' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Rejected / Failed</p>
              <MisuseOutline size={20} color="#da1e28" />
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{stats.rejected}</h3>
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Did not pass verification</p>
          </Tile>
        </Column>
        <Column sm={4} md={4} lg={4}>
          <Tile style={{ borderTop: '4px solid #6929c4' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Collected This Month</p>
              <Money size={20} color="#6929c4" />
            </div>
            <h3 style={{ fontSize: '1.75rem', fontWeight: 300, margin: '0.5rem 0' }}>
              {formatCurrency(stats.collectedThisMonth)}
            </h3>
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Verified/Paid receipts</p>
          </Tile>
        </Column>
      </Grid>

      <div style={{ marginBottom: '1rem', maxWidth: '480px' }}>
        <ContentSwitcher
          selectedIndex={METHOD_FILTERS.findIndex((m) => m.key === methodFilter)}
          onChange={({ index }) => setMethodFilter(METHOD_FILTERS[index as number].key)}
        >
          {METHOD_FILTERS.map((m) => (
            <Switch key={m.key} name={m.key} text={m.label} />
          ))}
        </ContentSwitcher>
      </div>

      {loading ? (
        <InlineLoading description="Loading payments..." />
      ) : (
        <DataTable rows={rows} headers={headers}>
          {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
            <TableContainer
              title="Fee Payments"
              description="Every payment awaiting or already reviewed, from citizens across all services."
            >
              <TableToolbar>
                <TableToolbarContent>
                  <Select
                    id="status-filter"
                    labelText=""
                    hideLabel
                    size="lg"
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value as "All" | PaymentStatus)}
                    style={{ maxWidth: '220px' }}
                  >
                    <SelectItem value="All" text="All Statuses" />
                    <SelectItem value="Pending" text="Pending" />
                    <SelectItem value="Verified" text="Verified" />
                    <SelectItem value="Paid" text="Paid" />
                    <SelectItem value="Rejected" text="Rejected" />
                    <SelectItem value="Failed" text="Failed" />
                    <SelectItem value="Refunded" text="Refunded" />
                    <SelectItem value="PartiallyRefunded" text="Partially Refunded" />
                  </Select>
                  <TableToolbarSearch
                    persistent
                    placeholder="Search reference, application, or citizen..."
                    onChange={(_event, value) => setSearchTerm(value || "")}
                  />
                </TableToolbarContent>
              </TableToolbar>
              <Table {...getTableProps()}>
                <TableHead>
                  <TableRow>
                    {headers.map((header) => (
                      <TableHeader {...getHeaderProps({ header })} key={header.key}>
                        {header.header}
                      </TableHeader>
                    ))}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {rows.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={headers.length} style={{ textAlign: 'center', padding: '2rem' }}>
                        No payments match the current filters.
                      </TableCell>
                    </TableRow>
                  ) : (
                    rows.map((row) => (
                      <TableRow {...getRowProps({ row })} key={row.id}>
                        {row.cells.map((cell) => {
                          if (cell.info.header === "method") {
                            return (
                              <TableCell key={cell.id}>
                                <Tag type={methodTagType(cell.value as PaymentMethod)}>
                                  {PAYMENT_METHOD_LABELS[cell.value as PaymentMethod]}
                                </Tag>
                              </TableCell>
                            );
                          }
                          if (cell.info.header === "status") {
                            return (
                              <TableCell key={cell.id}>
                                <Tag type={statusTagType(cell.value as PaymentStatus)}>{cell.value}</Tag>
                              </TableCell>
                            );
                          }
                          if (cell.info.header === "actions") {
                            return (
                              <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                <Button size="sm" kind="tertiary" onClick={() => openDetails(row.id)}>
                                  Details
                                </Button>
                              </TableCell>
                            );
                          }
                          return <TableCell key={cell.id}>{cell.value}</TableCell>;
                        })}
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </DataTable>
      )}

      <Modal
        open={selectedPayment !== null}
        modalHeading={selectedPayment ? `Payment ${selectedPayment.transactionReference}` : ""}
        modalLabel="Payment Details"
        passiveModal
        onRequestClose={closeDetails}
        size="md"
      >
        {selectedPayment && (
          <div style={{ paddingBottom: '1rem' }}>
            {banner && (
              <InlineNotification
                kind={banner.kind}
                title={banner.message}
                lowContrast
                hideCloseButton
                style={{ marginBottom: '1rem' }}
              />
            )}

            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '1rem' }}>
              <Column sm={4} md={4} lg={8}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Service / Application</p>
                <p style={{ fontWeight: 600 }}>{selectedPayment.serviceName} {selectedPayment.applicationId ? `(${selectedPayment.applicationId})` : ""}</p>
              </Column>
              <Column sm={4} md={4} lg={8}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Citizen</p>
                <p style={{ fontWeight: 600 }}>{selectedPayment.userFullName}</p>
                <p style={{ fontSize: '0.75rem', color: '#525252' }}>{selectedPayment.userEmail}</p>
              </Column>
            </Grid>

            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '1.5rem' }}>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Method</p>
                <Tag type={methodTagType(selectedPayment.method)}>{PAYMENT_METHOD_LABELS[selectedPayment.method]}</Tag>
              </Column>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Amount</p>
                <p style={{ fontWeight: 600 }}>{formatCurrency(selectedPayment.amount, selectedPayment.currency)}</p>
              </Column>
              <Column sm={4} md={4} lg={6}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Status</p>
                <Tag type={statusTagType(selectedPayment.status)}>{selectedPayment.status}</Tag>
              </Column>
            </Grid>

            {selectedPayment.method === "BankTransfer" && (
              <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', marginBottom: '1.5rem' }}>
                <p style={{ fontWeight: 600, marginBottom: '0.75rem' }}>Bank Transfer / Deposit Details</p>
                <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Bank / Branch</p>
                    <p>{selectedPayment.bankName} &middot; {selectedPayment.branchName}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Account Number</p>
                    <p>{selectedPayment.accountNumber}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Reference Number</p>
                    <p>{selectedPayment.referenceNumber}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Payment Date</p>
                    <p>{formatDate(selectedPayment.paymentDate)}</p>
                  </Column>
                </Grid>

                <div style={{ marginTop: '0.5rem' }}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', marginBottom: '0.5rem' }}>Payment Slip</p>
                  {slipLoading ? (
                    <InlineLoading description="Loading slip..." />
                  ) : slipUrl ? (
                    <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '0.5rem', backgroundColor: '#f4f4f4' }}>
                      {selectedPayment.slipFileName?.toLowerCase().endsWith(".pdf") ? (
                        <a href={slipUrl} target="_blank" rel="noreferrer">Open uploaded PDF slip</a>
                      ) : (
                        <img src={slipUrl} alt="Payment slip" style={{ maxWidth: '100%', maxHeight: '320px', display: 'block', margin: '0 auto' }} />
                      )}
                      <p style={{ fontSize: '0.75rem', color: '#525252', marginTop: '0.5rem' }}>
                        {selectedPayment.slipFileName} &middot; Uploaded {formatDateTime(selectedPayment.slipUploadedAt)}
                      </p>
                    </div>
                  ) : (
                    <p style={{ fontSize: '0.875rem', color: '#525252' }}>No slip attached</p>
                  )}
                </div>
              </div>
            )}

            {selectedPayment.method === "Stripe" && (
              <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', marginBottom: '1.5rem' }}>
                <p style={{ fontWeight: 600, marginBottom: '0.75rem' }}>Stripe Payment Details</p>
                <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Payment Intent</p>
                    <p>{selectedPayment.stripePaymentIntentId || "-"}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Confirmed At</p>
                    <p>{formatDateTime(selectedPayment.verifiedAt)}</p>
                  </Column>
                </Grid>
                {selectedPayment.stripeReceiptUrl && (
                  <a href={selectedPayment.stripeReceiptUrl} target="_blank" rel="noreferrer">View Stripe receipt</a>
                )}
              </div>
            )}

            {selectedPayment.method === "BankTransfer" && selectedPayment.status === "Pending" ? (
              <>
                <TextArea
                  id="verification-notes"
                  labelText="Verification Notes"
                  placeholder="Add a note about this verification decision..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                />
                <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1rem' }}>
                  <Button kind="danger--tertiary" disabled={submitting} onClick={() => handleDecision("Rejected")}>
                    Reject Payment
                  </Button>
                  <Button kind="primary" disabled={submitting} onClick={() => handleDecision("Verified")}>
                    Verify Payment
                  </Button>
                </div>
              </>
            ) : (
              <div style={{ marginTop: '1rem', fontSize: '0.875rem', color: '#525252' }}>
                {selectedPayment.verifiedByOfficerName
                  ? <>{selectedPayment.status} by {selectedPayment.verifiedByOfficerName} on {formatDateTime(selectedPayment.verifiedAt)}</>
                  : <>Status: {selectedPayment.status}</>}
                {selectedPayment.verificationNotes && <p style={{ marginTop: '0.5rem' }}>Note: {selectedPayment.verificationNotes}</p>}
              </div>
            )}
          </div>
        )}
      </Modal>
    </FinanceShell>
  );
}
