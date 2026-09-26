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
import { Hourglass, CheckmarkOutline, MisuseOutline, Money, Launch, Edit } from "@carbon/icons-react";
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
import {
  getDepartmentPayments,
  getPendingSlips,
  verifyPayment as verifyPaymentApi,
  updatePaymentStatus as updatePaymentStatusApi,
} from "./paymentsApi";

const METHOD_FILTERS: { key: "All" | PaymentMethod; label: string }[] = [
  { key: "All", label: "All Methods" },
  { key: "OnlineBankTransfer", label: "Online Bank Transfer" },
  { key: "BankDeposit", label: "Bank Deposit" },
  { key: "OnlinePay", label: "Online Pay" },
];

const headers = [
  { key: "id", header: "Payment ID" },
  { key: "applicationId", header: "Application & Service" },
  { key: "citizen", header: "Citizen (NIC & Name)" },
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

  // Load live payments for this department from the backend with citizen details
  useEffect(() => {
    getDepartmentPayments()
      .then((backendPayments) => {
        if (backendPayments && backendPayments.length > 0) {
          const mapped: Payment[] = backendPayments.map((b) => ({
            id: b.id,
            applicationId: b.referenceNumber || `APP-${b.applicationId}`,
            userId: b.userEmail || "citizen@gov.lk",
            citizenNic: b.citizenNic || "",
            citizenName: b.citizenName || "",
            serviceName: b.serviceName || "Government Service",
            stageNumber: b.stageNumber || 1,
            department: b.department || "",
            method: (b.method === "Online" || b.method === "OnlinePay")
              ? "OnlinePay"
              : (b.method === "Bank Deposit" ? "BankDeposit" : "OnlineBankTransfer"),
            amount: b.amount,
            status: b.status === "Paid" ? "Verified" : b.status === "Failed" ? "Rejected" : "Pending",
            submittedAt: b.submittedAt || b.createdDate,
            slipFileName: b.manualSlipUrl ? b.manualSlipUrl.split("/").pop() || "bank_deposit_slip.pdf" : "bank_deposit_slip.pdf",
            slipUploadedAt: b.submittedAt || b.createdDate,
            manualSlipUrl: b.manualSlipUrl,
            referenceNumber: b.referenceNumberOrId,
            transactionId: b.referenceNumberOrId,
            paidAt: b.paidDate || undefined,
            verifiedAt: b.paidDate || undefined,
          }));

          setPayments(mapped);
        }
      })
      .catch((err) => {
        console.warn("Could not load backend department payments:", err);
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
          (p.citizenNic && p.citizenNic.toLowerCase().includes(term)) ||
          (p.citizenName && p.citizenName.toLowerCase().includes(term)) ||
          (p.serviceName && p.serviceName.toLowerCase().includes(term)) ||
          (p.referenceNumber && p.referenceNumber.toLowerCase().includes(term)) ||
          (p.transactionId && p.transactionId.toLowerCase().includes(term)) ||
          String(p.id).includes(term)
        );
      })
      .sort((a, b) => new Date(b.submittedAt).getTime() - new Date(a.submittedAt).getTime());
  }, [payments, methodFilter, statusFilter, searchTerm]);

  const rows = filteredPayments.map((p) => ({
    id: String(p.id),
    applicationId: p.applicationId,
    citizen: p.citizenName ? `${p.citizenName}` : (p.citizenNic || p.userId),
    method: p.method,
    amount: formatCurrency(p.amount),
    status: p.status,
    submitted: formatDateTime(p.submittedAt),
    actions: "",
  }));

  const [isEditingStatus, setIsEditingStatus] = useState(false);
  const [editStatusValue, setEditStatusValue] = useState<PaymentStatus>("Verified");

  function openDetails(paymentId: string) {
    const payment = payments.find((p) => String(p.id) === paymentId) || null;
    setSelectedPayment(payment);
    setNotes(payment?.verificationNotes || "");
    setIsEditingStatus(false);
    setEditStatusValue(payment?.status || "Verified");
    setBanner(null);
  }

  function openEditStatus(paymentId: string) {
    const payment = payments.find((p) => String(p.id) === paymentId) || null;
    setSelectedPayment(payment);
    setNotes(payment?.verificationNotes || "");
    setIsEditingStatus(true);
    setEditStatusValue(payment?.status || "Verified");
    setBanner(null);
  }

  function closeDetails() {
    setSelectedPayment(null);
    setNotes("");
    setIsEditingStatus(false);
  }

  async function handleSaveEditedStatus() {
    if (!selectedPayment) return;
    const officerName = getDisplayName(getStoredUser());
    const backendStatus = editStatusValue === "Verified" ? "Paid" : editStatusValue === "Rejected" ? "Failed" : "PendingVerification";

    try {
      await updatePaymentStatusApi(selectedPayment.id, backendStatus, notes);
    } catch (err) {
      console.warn("Backend updatePaymentStatus API notice:", err);
    }

    const updated = payments.map((p) =>
      p.id === selectedPayment.id
        ? {
            ...p,
            status: editStatusValue,
            verifiedAt: editStatusValue !== "Pending" ? new Date().toISOString() : undefined,
            verifiedByOfficerName: editStatusValue !== "Pending" ? officerName : undefined,
            verificationNotes: notes,
          }
        : p
    );

    setPayments(updated);
    setSelectedPayment(updated.find((p) => p.id === selectedPayment.id) || null);
    setIsEditingStatus(false);
    setBanner({
      kind: editStatusValue === "Verified" ? "success" : "info",
      message: `Payment status successfully updated to "${editStatusValue}".`,
    });
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
                        if (cell.info.header === "applicationId") {
                          const payment = filteredPayments.find((p) => String(p.id) === row.id);
                          return (
                            <TableCell key={cell.id}>
                              <div style={{ fontWeight: 600, color: '#161616' }}>{cell.value}</div>
                              {payment?.serviceName && (
                                <div style={{ fontSize: '0.75rem', color: '#525252', marginTop: '2px' }}>
                                  {payment.serviceName} {payment.stageNumber ? `· Stage ${payment.stageNumber}` : ''}
                                </div>
                              )}
                            </TableCell>
                          );
                        }
                        if (cell.info.header === "citizen") {
                          const payment = filteredPayments.find((p) => String(p.id) === row.id);
                          return (
                            <TableCell key={cell.id}>
                              <div style={{ fontWeight: 600, color: '#161616' }}>
                                {payment?.citizenName || cell.value || "Citizen"}
                              </div>
                              <div style={{ fontSize: '0.75rem', color: '#0f62fe', fontWeight: 600, marginTop: '2px' }}>
                                NIC: {payment?.citizenNic || "Not Provided"}
                              </div>
                            </TableCell>
                          );
                        }
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
                            <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right', whiteSpace: 'nowrap' }}>
                              <Button
                                size="sm"
                                kind="ghost"
                                renderIcon={Edit}
                                onClick={() => openEditStatus(row.id)}
                                style={{ marginRight: '0.5rem' }}
                              >
                                Edit Status
                              </Button>
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
        modalHeading={selectedPayment ? `Payment Verification — ${selectedPayment.applicationId}` : ""}
        modalLabel="Statutory Fee Verification"
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

            {/* Citizen Identity & Application Information Card */}
            <div
              style={{
                backgroundColor: '#f4f4f4',
                padding: '1rem',
                borderRadius: '6px',
                borderLeft: '4px solid #0f62fe',
                marginBottom: '1.25rem',
              }}
            >
              <h4 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616', marginBottom: '0.75rem' }}>
                Citizen Identity &amp; Application Reference
              </h4>
              <Grid style={{ paddingLeft: 0, paddingRight: 0, rowGap: '0.75rem' }}>
                <Column sm={4} md={4} lg={8}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Citizen Full Name</p>
                  <p style={{ fontWeight: 600, fontSize: '1rem', color: '#161616' }}>
                    {selectedPayment.citizenName || "Not Recorded"}
                  </p>
                </Column>
                <Column sm={4} md={4} lg={8}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Citizen NIC Number</p>
                  <p style={{ fontWeight: 600, fontSize: '1rem', color: '#0f62fe' }}>
                    {selectedPayment.citizenNic || "Not Recorded"}
                  </p>
                </Column>
                <Column sm={4} md={4} lg={8}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Government Service</p>
                  <p style={{ fontWeight: 500, color: '#161616' }}>
                    {selectedPayment.serviceName || "Government Service"}
                    {selectedPayment.stageNumber ? ` (Stage ${selectedPayment.stageNumber})` : ""}
                  </p>
                </Column>
                <Column sm={4} md={4} lg={8}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Department / Reference ID</p>
                  <p style={{ fontWeight: 500, color: '#161616' }}>
                    {selectedPayment.department ? `${selectedPayment.department} · ` : ""}
                    {selectedPayment.applicationId}
                  </p>
                </Column>
              </Grid>
            </div>

            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '1.25rem' }}>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Payment Method</p>
                <Tag type={methodTagType(selectedPayment.method)}>{PAYMENT_METHOD_LABELS[selectedPayment.method]}</Tag>
              </Column>
              <Column sm={4} md={4} lg={5}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Fee Amount</p>
                <p style={{ fontWeight: 600, fontSize: '1.125rem' }}>{formatCurrency(selectedPayment.amount)}</p>
              </Column>
              <Column sm={4} md={4} lg={6}>
                <p style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase' }}>Verification Status</p>
                <Tag type={statusTagType(selectedPayment.status)}>{selectedPayment.status}</Tag>
              </Column>
            </Grid>

            {/* Payment Proof / Slip Details */}
            <div style={{ border: '1px solid #e0e0e0', borderRadius: '4px', padding: '1rem', marginBottom: '1.5rem', backgroundColor: '#fff' }}>
              <p style={{ fontWeight: 600, marginBottom: '0.75rem', fontSize: '0.875rem' }}>
                Payment Evidence &amp; Bank Reference
              </p>
              <Grid style={{ paddingLeft: 0, paddingRight: 0, rowGap: '0.5rem' }}>
                {(selectedPayment.referenceNumber || selectedPayment.transactionId) && (
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.5rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Bank Reference / Transaction ID</p>
                    <p style={{ fontWeight: 600, color: '#161616', fontFamily: 'monospace' }}>
                      {selectedPayment.referenceNumber || selectedPayment.transactionId}
                    </p>
                  </Column>
                )}
                {selectedPayment.bankName && (
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.5rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Bank / Branch</p>
                    <p>{selectedPayment.bankName} {selectedPayment.branchName ? `· ${selectedPayment.branchName}` : ''}</p>
                  </Column>
                )}
                {selectedPayment.accountNumber && (
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.5rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Account Number</p>
                    <p>{selectedPayment.accountNumber}</p>
                  </Column>
                )}
                {selectedPayment.paymentDate && (
                  <Column sm={4} md={4} lg={8} style={{ marginBottom: '0.5rem' }}>
                    <p style={{ fontSize: '0.75rem', color: '#525252' }}>Payment Date</p>
                    <p>{formatDate(selectedPayment.paymentDate)}</p>
                  </Column>
                )}
              </Grid>

              {/* Deposit Slip File / Viewer */}
              {selectedPayment.manualSlipUrl ? (
                <div style={{ marginTop: '0.75rem', borderTop: '1px solid #f4f4f4', paddingTop: '0.75rem' }}>
                  <p style={{ fontSize: '0.75rem', color: '#525252', marginBottom: '0.5rem' }}>Attached Deposit Slip</p>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.75rem',
                        border: '1px dashed #8d8d8d',
                        borderRadius: '4px',
                        padding: '0.75rem',
                        backgroundColor: '#f4f4f4',
                        flex: 1,
                        minWidth: '220px',
                      }}
                    >
                      <Money size={24} />
                      <div style={{ overflow: 'hidden' }}>
                        <p style={{ fontWeight: 500, textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
                          {selectedPayment.slipFileName || "bank_deposit_slip.pdf"}
                        </p>
                        <p style={{ fontSize: '0.75rem', color: '#525252' }}>
                          Uploaded {formatDateTime(selectedPayment.slipUploadedAt)}
                        </p>
                      </div>
                    </div>
                    <Button
                      size="sm"
                      kind="tertiary"
                      renderIcon={Launch}
                      href={selectedPayment.manualSlipUrl}
                      target="_blank"
                    >
                      View Deposit Slip
                    </Button>
                  </div>
                </div>
              ) : (
                <div style={{ marginTop: '0.5rem', color: '#525252', fontSize: '0.8125rem' }}>
                  No physical deposit slip attached (Verified electronically via Gateway or Ref ID).
                </div>
              )}
            </div>

            {isEditingStatus ? (
              <div
                style={{
                  marginTop: '1.25rem',
                  padding: '1.25rem',
                  border: '1px solid #0f62fe',
                  borderRadius: '4px',
                  backgroundColor: '#f4f7fb',
                }}
              >
                <h4 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#0f62fe', marginBottom: '0.75rem' }}>
                  Edit Statutory Payment Status
                </h4>
                <Select
                  id="edit-status-select"
                  labelText="Select New Status"
                  value={editStatusValue}
                  onChange={(e) => setEditStatusValue(e.target.value as PaymentStatus)}
                  style={{ marginBottom: '1rem' }}
                >
                  <SelectItem value="Verified" text="Verified — Fee confirmed and posted to ledger" />
                  <SelectItem value="Pending" text="Pending — Awaiting audit / deposit slip review" />
                  <SelectItem value="Rejected" text="Rejected — Invalid deposit slip / payment declined" />
                </Select>
                <TextArea
                  id="edit-verification-notes"
                  labelText="Audit Reason / Verification Notes"
                  placeholder="Specify reason for changing status (e.g., slip verified with bank statement, mismatch, etc.)..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                  style={{ marginBottom: '1rem' }}
                />
                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <Button kind="primary" onClick={handleSaveEditedStatus}>
                    Save Status Changes
                  </Button>
                  <Button kind="ghost" onClick={() => setIsEditingStatus(false)}>
                    Cancel
                  </Button>
                </div>
              </div>
            ) : (
              <>
                <TextArea
                  id="verification-notes"
                  labelText="Verification Notes / Audit Reason"
                  placeholder="Add verification notes (e.g., matched with bank statement dated 2026-09-26)..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  disabled={selectedPayment.status !== "Pending"}
                  rows={3}
                />

                {selectedPayment.status === "Pending" ? (
                  <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1rem', flexWrap: 'wrap' }}>
                    <Button kind="primary" onClick={() => handleDecision("Verified")}>
                      Verify &amp; Post to Ledger
                    </Button>
                    <Button kind="danger--tertiary" onClick={() => handleDecision("Rejected")}>
                      Reject Payment
                    </Button>
                    <Button kind="secondary" renderIcon={Edit} onClick={() => setIsEditingStatus(true)}>
                      Edit Status
                    </Button>
                  </div>
                ) : (
                  <div
                    style={{
                      marginTop: '1rem',
                      fontSize: '0.875rem',
                      color: '#525252',
                      backgroundColor: '#f4f4f4',
                      padding: '0.75rem 1rem',
                      borderRadius: '4px',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.5rem',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
                      <div>
                        <strong>{selectedPayment.status}</strong> by {selectedPayment.verifiedByOfficerName || "Finance Officer"} on{" "}
                        {formatDateTime(selectedPayment.verifiedAt)}
                      </div>
                      <Button size="sm" kind="secondary" renderIcon={Edit} onClick={() => setIsEditingStatus(true)}>
                        Edit Status
                      </Button>
                    </div>
                    {selectedPayment.verificationNotes && (
                      <div style={{ fontStyle: 'italic', fontSize: '0.8125rem' }}>
                        Note: "{selectedPayment.verificationNotes}"
                      </div>
                    )}
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </Modal>
    </FinanceShell>
  );
}
