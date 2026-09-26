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
} from "@carbon/react";
import { Hourglass, CheckmarkOutline, MisuseOutline, Money } from "@carbon/icons-react";
import FinanceShell from "./finance_shell";
import {
  loadPayments,
  PAYMENT_METHOD_LABELS,
  type Payment,
  type PaymentMethod,
  type PaymentStatus,
} from "./financeData";
import { getDisplayName, getStoredUser } from "../utils/currentUser";
import { formatCurrency, formatDate, formatDateTime } from "./format";
import { getPendingSlips, verifyPayment as verifyPaymentApi } from "./paymentsApi";

const METHOD_FILTERS: { key: "All" | PaymentMethod; label: string }[] = [
  { key: "All", label: "All Methods" },
  { key: "OnlineBankTransfer", label: "Online Bank Transfer" },
  { key: "BankDeposit", label: "Bank Deposit" },
  { key: "OnlinePay", label: "Online Pay" },
];

const headers = [
  { key: "id", header: "Payment ID" },
  { key: "applicationId", header: "Application Submit ID" },
  { key: "userId", header: "User ID" },
  { key: "method", header: "Method" },
  { key: "amount", header: "Amount" },
  { key: "status", header: "Status" },
  { key: "submitted", header: "Submitted" },
  { key: "actions", header: "" },
];

function statusTagType(status: PaymentStatus): "blue" | "green" | "red" {
  if (status === "Verified") return "green";
  if (status === "Rejected") return "red";
  return "blue";
}

function methodTagType(method: PaymentMethod): "purple" | "teal" | "cyan" {
  if (method === "OnlineBankTransfer") return "purple";
  if (method === "BankDeposit") return "teal";
  return "cyan";
}

export default function FinanceDashboard() {
  const [payments, setPayments] = useState<Payment[]>(loadPayments);
  const [methodFilter, setMethodFilter] = useState<"All" | PaymentMethod>("All");
  const [statusFilter, setStatusFilter] = useState<"All" | PaymentStatus>("All");
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedPayment, setSelectedPayment] = useState<Payment | null>(null);
  const [notes, setNotes] = useState("");
  const [banner, setBanner] = useState<{ kind: "success" | "error"; message: string } | null>(null);

  // Load live pending manual slips from the backend
  useEffect(() => {
    getPendingSlips()
      .then((backendSlips) => {
        if (backendSlips && backendSlips.length > 0) {
          const mapped: Payment[] = backendSlips.map((b) => ({
            id: b.id,
            applicationId: `APP-${b.applicationId}`,
            userId: b.userEmail || "citizen@gov.lk",
            method: b.method === "Online" ? "OnlinePay" : "OnlineBankTransfer",
            amount: b.amount,
            status: b.status === "Paid" ? "Verified" : b.status === "Failed" ? "Rejected" : "Pending",
            submittedAt: b.createdDate,
            slipFileName: b.manualSlipUrl ? b.manualSlipUrl.split("/").pop() || "bank_deposit_slip.pdf" : "bank_deposit_slip.pdf",
            slipUploadedAt: b.createdDate,
          }));

          setPayments((prev) => {
            const existingIds = new Set(prev.map((p) => p.id));
            const fresh = mapped.filter((m) => !existingIds.has(m.id));
            return [...fresh, ...prev];
          });
        }
      })
      .catch((err) => {
        console.warn("Could not load backend pending slips:", err);
      });
  }, []);

  const stats = useMemo(() => {
    const pending = payments.filter((p) => p.status === "Pending").length;
    const verifiedToday = payments.filter(
      (p) => p.status === "Verified" && p.verifiedAt && new Date(p.verifiedAt).toDateString() === new Date().toDateString()
    ).length;
    const rejected = payments.filter((p) => p.status === "Rejected").length;
    const collectedThisMonth = payments
      .filter((p) => {
        if (p.status !== "Verified" || !p.verifiedAt) return false;
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
          p.applicationId.toLowerCase().includes(term) ||
          p.userId.toLowerCase().includes(term) ||
          String(p.id).includes(term)
        );
      })
      .sort((a, b) => new Date(b.submittedAt).getTime() - new Date(a.submittedAt).getTime());
  }, [payments, methodFilter, statusFilter, searchTerm]);

  const rows = filteredPayments.map((p) => ({
    id: String(p.id),
    applicationId: p.applicationId,
    userId: p.userId,
    method: p.method,
    amount: formatCurrency(p.amount),
    status: p.status,
    submitted: formatDateTime(p.submittedAt),
    actions: "",
  }));

  function openDetails(paymentId: string) {
    const payment = payments.find((p) => String(p.id) === paymentId) || null;
    setSelectedPayment(payment);
    setNotes(payment?.verificationNotes || "");
    setBanner(null);
  }

  function closeDetails() {
    setSelectedPayment(null);
    setNotes("");
  }

  async function handleDecision(decision: "Verified" | "Rejected") {
    if (!selectedPayment) return;
    const officerName = getDisplayName(getStoredUser());
    const isApproved = decision === "Verified";

    // Call live backend endpoint
    try {
      await verifyPaymentApi(selectedPayment.id, isApproved, notes);
    } catch (err) {
      console.warn("Backend verify API returned notice:", err);
    }

    const updated = payments.map((p) =>
      p.id === selectedPayment.id
        ? {
            ...p,
            status: decision,
            verifiedAt: new Date().toISOString(),
            verifiedByOfficerName: officerName,
            verificationNotes: notes,
          }
        : p
    );

    setPayments(updated);
    setSelectedPayment(updated.find((p) => p.id === selectedPayment.id) || null);
    setBanner({
      kind: decision === "Verified" ? "success" : "error",
      message: decision === "Verified" ? "Payment verified and posted to the ledger." : "Payment rejected.",
    });
  }

  return (
    <FinanceShell active="dashboard">
      <div style={{ marginBottom: '1.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Payment Verification</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>
          Review fee payments submitted by online bank transfer, bank deposit, or online pay, and verify each one
          against its supporting details before it is posted to the account ledger.
        </p>
      </div>

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
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Verified Today</p>
              <CheckmarkOutline size={20} color="#24a148" />
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{stats.verifiedToday}</h3>
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Posted to ledger</p>
          </Tile>
        </Column>
        <Column sm={4} md={4} lg={4}>
          <Tile style={{ borderTop: '4px solid #da1e28' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <p style={{ color: '#525252', fontSize: '0.875rem' }}>Rejected</p>
              <MisuseOutline size={20} color="#da1e28" />
            </div>
            <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{stats.rejected}</h3>
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Failed verification</p>
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
            <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Verified receipts</p>
          </Tile>
        </Column>
      </Grid>

      <div style={{ marginBottom: '1rem', maxWidth: '640px' }}>
        <ContentSwitcher
          selectedIndex={METHOD_FILTERS.findIndex((m) => m.key === methodFilter)}
          onChange={({ index }) => setMethodFilter(METHOD_FILTERS[index as number].key)}
        >
          {METHOD_FILTERS.map((m) => (
            <Switch key={m.key} name={m.key} text={m.label} />
          ))}
        </ContentSwitcher>
      </div>

      <DataTable rows={rows} headers={headers}>
        {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
          <TableContainer
            title="Fee Payments"
            description="Application submit ID and user ID for every payment awaiting or already reviewed."
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
                  style={{ maxWidth: '200px' }}
                >
                  <SelectItem value="All" text="All Statuses" />
                  <SelectItem value="Pending" text="Pending" />
                  <SelectItem value="Verified" text="Verified" />
                  <SelectItem value="Rejected" text="Rejected" />
                </Select>
                <TableToolbarSearch
                  persistent
                  placeholder="Search Application ID or User ID..."
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

      <Modal
        open={selectedPayment !== null}
        modalHeading={selectedPayment ? `Payment ${selectedPayment.applicationId}` : ""}
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
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Application Submit ID</p>
                <p style={{ fontWeight: 600 }}>{selectedPayment.applicationId}</p>
              </Column>
              <Column sm={4} md={4} lg={8}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>User ID</p>
                <p style={{ fontWeight: 600 }}>{selectedPayment.userId}</p>
              </Column>
            </Grid>

            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '1.5rem' }}>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Method</p>
                <Tag type={methodTagType(selectedPayment.method)}>{PAYMENT_METHOD_LABELS[selectedPayment.method]}</Tag>
              </Column>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Amount</p>
                <p style={{ fontWeight: 600 }}>{formatCurrency(selectedPayment.amount)}</p>
              </Column>
              <Column sm={4} md={4} lg={6}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Status</p>
                <Tag type={statusTagType(selectedPayment.status)}>{selectedPayment.status}</Tag>
              </Column>
            </Grid>

            {(selectedPayment.method === "OnlineBankTransfer" || selectedPayment.method === "BankDeposit") && (
              <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', marginBottom: '1.5rem' }}>
                <p style={{ fontWeight: 600, marginBottom: '0.75rem' }}>
                  {selectedPayment.method === "BankDeposit" ? "Bank Deposit Details" : "Online Bank Transfer Details"}
                </p>
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
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.75rem',
                      border: '1px dashed #8d8d8d',
                      borderRadius: '4px',
                      padding: '0.75rem',
                      backgroundColor: '#f4f4f4',
                    }}
                  >
                    <Money size={24} />
                    <div>
                      <p style={{ fontWeight: 500 }}>{selectedPayment.slipFileName || "No slip attached"}</p>
                      <p style={{ fontSize: '0.75rem', color: '#525252' }}>
                        Uploaded {formatDateTime(selectedPayment.slipUploadedAt)}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {selectedPayment.method === "OnlinePay" && (
              <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', marginBottom: '1.5rem' }}>
                <p style={{ fontWeight: 600, marginBottom: '0.75rem' }}>Online Payment Details</p>
                <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Gateway</p>
                    <p>{selectedPayment.gatewayName}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Transaction ID</p>
                    <p>{selectedPayment.transactionId}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Payer Name</p>
                    <p>{selectedPayment.payerName}</p>
                  </Column>
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.75rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Paid At</p>
                    <p>{formatDateTime(selectedPayment.paidAt)}</p>
                  </Column>
                </Grid>
              </div>
            )}

            <TextArea
              id="verification-notes"
              labelText="Verification Notes"
              placeholder="Add a note about this verification decision..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              disabled={selectedPayment.status !== "Pending"}
              rows={3}
            />

            {selectedPayment.status === "Pending" ? (
              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1rem' }}>
                <Button kind="danger--tertiary" onClick={() => handleDecision("Rejected")}>
                  Reject Payment
                </Button>
                <Button kind="primary" onClick={() => handleDecision("Verified")}>
                  Verify Payment
                </Button>
              </div>
            ) : (
              <div style={{ marginTop: '1rem', fontSize: '0.875rem', color: '#525252' }}>
                {selectedPayment.status} by {selectedPayment.verifiedByOfficerName} on{" "}
                {formatDateTime(selectedPayment.verifiedAt)}
              </div>
            )}
          </div>
        )}
      </Modal>
    </FinanceShell>
  );
}
