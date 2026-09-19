import '@carbon/styles/css/styles.css';
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Button,
  Column,
  ContentSwitcher,
  DataTable,
  Grid,
  InlineLoading,
  InlineNotification,
  Modal,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableHeader,
  TableRow,
  TableToolbar,
  TableToolbarContent,
  TableToolbarSearch,
  Tag,
  TextArea,
  TextInput,
  Tile,
} from "@carbon/react";
import {
  Checkmark,
  Misuse,
  ArrowRight,
  Renew,
  CheckmarkFilled,
} from "@carbon/icons-react";
import FinanceShell from "./finance_shell";
import {
  getAllRefunds,
  approveRefund,
  rejectRefund,
  processRefund,
  completeRefund,
  type RefundResponse,
  type RefundStatus,
} from "./refundsApi";

// ── Helpers ───────────────────────────────────────────────────────────────────

const STATUS_FILTERS: { key: "All" | RefundStatus; label: string }[] = [
  { key: "All", label: "All" },
  { key: "Pending", label: "Pending" },
  { key: "Approved", label: "Approved" },
  { key: "Rejected", label: "Rejected" },
  { key: "Processing", label: "Processing" },
  { key: "Completed", label: "Completed" },
  { key: "Failed", label: "Failed" },
];

type TagType = "blue" | "green" | "red" | "teal" | "purple" | "cool-gray";

function statusTag(status: RefundStatus): TagType {
  const map: Record<RefundStatus, TagType> = {
    Pending: "blue",
    Approved: "teal",
    Rejected: "red",
    Processing: "purple",
    Completed: "green",
    Failed: "cool-gray",
  };
  return map[status] ?? "blue";
}

function fmt(iso: string | null | undefined): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function fmtAmount(n: number): string {
  return new Intl.NumberFormat("en-LK", {
    style: "currency",
    currency: "LKR",
    maximumFractionDigits: 2,
  }).format(n);
}

const TABLE_HEADERS = [
  { key: "id", header: "Refund ID" },
  { key: "paymentId", header: "Payment ID" },
  { key: "requestedByEmail", header: "Requested By" },
  { key: "refundAmount", header: "Amount" },
  { key: "status", header: "Status" },
  { key: "requestedDate", header: "Requested" },
];

// ── Component ─────────────────────────────────────────────────────────────────

export default function FinanceRefunds() {
  const [refunds, setRefunds] = useState<RefundResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);

  const [statusFilter, setStatusFilter] = useState<"All" | RefundStatus>("All");
  const [search, setSearch] = useState("");

  const [selected, setSelected] = useState<RefundResponse | null>(null);
  const [note, setNote] = useState("");
  const [txRef, setTxRef] = useState("");

  const [actionLoading, setActionLoading] = useState(false);
  const [banner, setBanner] = useState<{ kind: "success" | "error"; msg: string } | null>(null);

  // ── Fetch ──────────────────────────────────────────────────────────────────

  const load = useCallback(async () => {
    setLoading(true);
    setFetchError(null);
    try {
      const data = await getAllRefunds();
      setRefunds(data);
    } catch (e: unknown) {
      setFetchError(e instanceof Error ? e.message : "Failed to load refund requests.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      load();
    }, 0);
    return () => clearTimeout(timer);
  }, [load]);

  // ── Derived list ───────────────────────────────────────────────────────────

  const filtered = useMemo(() => {
    return refunds
      .filter((r) => statusFilter === "All" || r.status === statusFilter)
      .filter((r) => {
        if (!search.trim()) return true;
        const t = search.trim().toLowerCase();
        return (
          String(r.id).includes(t) ||
          String(r.paymentId).includes(t) ||
          r.requestedByEmail.toLowerCase().includes(t)
        );
      });
  }, [refunds, statusFilter, search]);

  const rows = filtered.map((r) => ({
    id: String(r.id),
    paymentId: String(r.paymentId),
    requestedByEmail: r.requestedByEmail,
    refundAmount: fmtAmount(r.refundAmount),
    status: r.status,
    requestedDate: fmt(r.requestedDate),
  }));

  // ── Summary counts ─────────────────────────────────────────────────────────

  const counts = useMemo(() => ({
    pending: refunds.filter((r) => r.status === "Pending").length,
    approved: refunds.filter((r) => r.status === "Approved").length,
    processing: refunds.filter((r) => r.status === "Processing").length,
    completed: refunds.filter((r) => r.status === "Completed").length,
  }), [refunds]);

  // ── Actions ────────────────────────────────────────────────────────────────

  function openDetail(rowId: string) {
    const found = refunds.find((r) => String(r.id) === rowId) ?? null;
    setSelected(found);
    setNote("");
    setTxRef("");
    setBanner(null);
  }

  function closeDetail() {
    setSelected(null);
    setBanner(null);
  }

  async function mutate(fn: () => Promise<RefundResponse>, successMsg: string) {
    setActionLoading(true);
    setBanner(null);
    try {
      const updated = await fn();
      setRefunds((prev) => prev.map((r) => (r.id === updated.id ? updated : r)));
      setSelected(updated);
      setBanner({ kind: "success", msg: successMsg });
    } catch (e: unknown) {
      setBanner({ kind: "error", msg: e instanceof Error ? e.message : "Action failed." });
    } finally {
      setActionLoading(false);
    }
  }

  function handleApprove() {
    if (!selected) return;
    mutate(() => approveRefund(selected.id, note || undefined), "Refund approved successfully.");
  }

  function handleReject() {
    if (!selected) return;
    mutate(() => rejectRefund(selected.id, note || undefined), "Refund rejected.");
  }

  function handleProcess() {
    if (!selected || !txRef.trim()) return;
    mutate(() => processRefund(selected.id, txRef.trim()), "Refund marked as Processing.");
  }

  function handleComplete() {
    if (!selected) return;
    mutate(() => completeRefund(selected.id), "Refund completed and funds returned to citizen.");
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <FinanceShell active="refunds">
      {/* Page header */}
      <div style={{ marginBottom: "1.5rem" }}>
        <h1 style={{ fontSize: "2rem", fontWeight: 400, color: "#161616" }}>
          Refund Request Manager
        </h1>
        <p style={{ color: "#525252", marginTop: "0.5rem" }}>
          Review, approve, reject, and process citizen refund requests. Manual bank
          transfer is used for all disbursements per departmental policy.
        </p>
      </div>

      {/* Summary tiles */}
      <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: "2rem" }}>
        {[
          { label: "Pending Review", value: counts.pending, color: "#0f62fe" },
          { label: "Approved", value: counts.approved, color: "#0e6027" },
          { label: "Processing", value: counts.processing, color: "#6929c4" },
          { label: "Completed", value: counts.completed, color: "#007d79" },
        ].map(({ label, value, color }) => (
          <Column sm={2} md={2} lg={4} key={label}>
            <Tile style={{ borderTop: `4px solid ${color}`, marginBottom: "1rem" }}>
              <p style={{ fontSize: "0.75rem", color: "#525252", textTransform: "uppercase", letterSpacing: "0.05em" }}>
                {label}
              </p>
              <p style={{ fontSize: "2rem", fontWeight: 600, color: "#161616", marginTop: "0.5rem" }}>
                {loading ? "—" : value}
              </p>
            </Tile>
          </Column>
        ))}
      </Grid>

      {/* Fetch error */}
      {fetchError && (
        <InlineNotification
          kind="error"
          title="Failed to load refunds:"
          subtitle={fetchError}
          style={{ marginBottom: "1rem" }}
          lowContrast
        />
      )}

      {/* Status filter switcher */}
      <div style={{ marginBottom: "1rem", overflowX: "auto" }}>
        <ContentSwitcher
          onChange={(e) => setStatusFilter((e as { name: "All" | RefundStatus }).name)}
          size="sm"
        >
          {STATUS_FILTERS.map(({ key, label }) => (
            <Switch key={key} name={key} text={label} />
          ))}
        </ContentSwitcher>
      </div>

      {/* Table */}
      {loading ? (
        <InlineLoading description="Loading refund requests…" />
      ) : (
        <DataTable rows={rows} headers={TABLE_HEADERS}>
          {({ rows: tableRows, headers, getHeaderProps, getRowProps, getTableProps }) => (
            <TableContainer title="">
              <TableToolbar>
                <TableToolbarContent>
                  <TableToolbarSearch
                    id="refund-search"
                    placeholder="Search by ID, Payment ID, or email…"
                    onChange={(_e, value?: string) => setSearch(value ?? "")}
                  />
                  <Button size="sm" kind="ghost" renderIcon={Renew} onClick={load} hasIconOnly iconDescription="Refresh" />
                </TableToolbarContent>
              </TableToolbar>
              <Table {...getTableProps()} useZebraStyles>
                <TableHead>
                  <TableRow>
                    {headers.map((h) => (
                      <TableHeader {...getHeaderProps({ header: h })}>
                        {h.header}
                      </TableHeader>
                    ))}
                    <TableHeader>Actions</TableHeader>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {tableRows.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={TABLE_HEADERS.length + 1} style={{ textAlign: "center", color: "#525252" }}>
                        No refund requests match the current filter.
                      </TableCell>
                    </TableRow>
                  ) : (
                    tableRows.map((row) => (
                      <TableRow {...getRowProps({ row })}>
                        {row.cells.map((cell) => (
                          <TableCell key={cell.id}>
                            {cell.info.header === "status" ? (
                              <Tag type={statusTag(cell.value as RefundStatus)}>
                                {cell.value}
                              </Tag>
                            ) : (
                              cell.value
                            )}
                          </TableCell>
                        ))}
                        <TableCell>
                          <Button
                            size="sm"
                            kind="ghost"
                            renderIcon={ArrowRight}
                            onClick={() => openDetail(row.id)}
                          >
                            Review
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </DataTable>
      )}

      {/* ── Detail modal ─────────────────────────────────────────────────── */}
      <Modal
        open={selected !== null}
        modalHeading={`Refund #${selected?.id ?? ""}`}
        passiveModal
        onRequestClose={closeDetail}
        size="md"
      >
        {selected && (
          <div style={{ paddingBottom: "1rem" }}>
            {/* Banner */}
            {banner && (
              <InlineNotification
                kind={banner.kind}
                title={banner.kind === "success" ? "Success" : "Error"}
                subtitle={banner.msg}
                style={{ marginBottom: "1rem" }}
                lowContrast
              />
            )}

            {/* Meta grid */}
            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: "1.5rem" }}>
              {[
                { label: "Status", value: <Tag type={statusTag(selected.status)}>{selected.status}</Tag> },
                { label: "Payment ID", value: `#${selected.paymentId}` },
                { label: "Refund Amount", value: fmtAmount(selected.refundAmount) },
                { label: "Requested By", value: selected.requestedByEmail },
                { label: "Requested", value: fmt(selected.requestedDate) },
                { label: "Decided", value: fmt(selected.decidedDate) },
                { label: "Decided By", value: selected.decidedByEmail ?? "—" },
                { label: "Completed", value: fmt(selected.completedDate) },
                { label: "Transaction Ref", value: selected.refundTransactionRef ?? "—" },
              ].map(({ label, value }) => (
                <Column sm={4} md={4} lg={8} key={label} style={{ marginBottom: "1rem" }}>
                  <p style={{ fontSize: "0.75rem", color: "#525252", textTransform: "uppercase", letterSpacing: "0.05em" }}>
                    {label}
                  </p>
                  <p style={{ fontSize: "0.875rem", color: "#161616", marginTop: "0.25rem" }}>
                    {value}
                  </p>
                </Column>
              ))}
            </Grid>

            {/* Reason */}
            <Tile style={{ marginBottom: "1.5rem", background: "#f4f4f4" }}>
              <p style={{ fontSize: "0.75rem", color: "#525252", textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "0.5rem" }}>
                Reason for Refund
              </p>
              <p style={{ fontSize: "0.875rem", color: "#161616" }}>{selected.reason}</p>
            </Tile>

            {/* Decision note (if already decided) */}
            {selected.decisionNote && (
              <Tile style={{ marginBottom: "1.5rem", background: "#f4f4f4" }}>
                <p style={{ fontSize: "0.75rem", color: "#525252", textTransform: "uppercase", letterSpacing: "0.05em", marginBottom: "0.5rem" }}>
                  Officer Note
                </p>
                <p style={{ fontSize: "0.875rem", color: "#161616" }}>{selected.decisionNote}</p>
              </Tile>
            )}

            {/* ── PENDING: Approve / Reject ──────────────────────────────── */}
            {selected.status === "Pending" && (
              <div style={{ borderTop: "1px solid #e0e0e0", paddingTop: "1.5rem" }}>
                <p style={{ fontWeight: 600, marginBottom: "1rem" }}>Decision</p>
                <TextArea
                  id="refund-decision-note"
                  labelText="Note (optional)"
                  placeholder="Add a note visible to the citizen…"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  rows={3}
                  style={{ marginBottom: "1rem" }}
                />
                <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
                  <Button
                    renderIcon={Checkmark}
                    onClick={handleApprove}
                    disabled={actionLoading}
                  >
                    {actionLoading ? "Saving…" : "Approve"}
                  </Button>
                  <Button
                    kind="danger"
                    renderIcon={Misuse}
                    onClick={handleReject}
                    disabled={actionLoading}
                  >
                    {actionLoading ? "Saving…" : "Reject"}
                  </Button>
                </div>
              </div>
            )}

            {/* ── APPROVED: Process (requires bank transfer ref) ─────────── */}
            {selected.status === "Approved" && (
              <div style={{ borderTop: "1px solid #e0e0e0", paddingTop: "1.5rem" }}>
                <p style={{ fontWeight: 600, marginBottom: "0.5rem" }}>Process Refund</p>
                <p style={{ fontSize: "0.875rem", color: "#525252", marginBottom: "1rem" }}>
                  Confirm the manual bank transfer has been initiated and enter the
                  bank confirmation / transaction reference number below.
                </p>
                <TextInput
                  id="refund-tx-ref"
                  labelText="Bank Transfer Reference *"
                  placeholder="e.g. TRF-2026-00142"
                  value={txRef}
                  onChange={(e) => setTxRef(e.target.value)}
                  style={{ marginBottom: "1rem" }}
                />
                <Button
                  renderIcon={ArrowRight}
                  onClick={handleProcess}
                  disabled={actionLoading || !txRef.trim()}
                >
                  {actionLoading ? "Saving…" : "Mark as Processing"}
                </Button>
              </div>
            )}

            {/* ── PROCESSING: Complete ───────────────────────────────────── */}
            {selected.status === "Processing" && (
              <div style={{ borderTop: "1px solid #e0e0e0", paddingTop: "1.5rem" }}>
                <p style={{ fontWeight: 600, marginBottom: "0.5rem" }}>Complete Refund</p>
                <p style={{ fontSize: "0.875rem", color: "#525252", marginBottom: "1rem" }}>
                  Confirm that the bank transfer has been received by the citizen and
                  mark this refund as completed. This will also update the original
                  payment status to "Refunded".
                </p>
                <Button
                  renderIcon={CheckmarkFilled}
                  onClick={handleComplete}
                  disabled={actionLoading}
                >
                  {actionLoading ? "Saving…" : "Mark as Completed"}
                </Button>
              </div>
            )}
          </div>
        )}
      </Modal>
    </FinanceShell>
  );
}
