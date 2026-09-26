import '@carbon/styles/css/styles.css';
import { useState, useEffect, useMemo, useCallback } from "react";
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  HeaderMenuButton,
  SideNav,
  SideNavItems,
  SideNavLink,
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
  Tag,
  Search,
  Loading,
  Grid,
  Column,
  Tile,
  Select,
  SelectItem
} from "@carbon/react";
import {
  Dashboard,
  Document,
  Time,
  User,
  Logout,
  Notification,
  CheckmarkOutline,
  DataStructured,
  Security,
  TrashCan
} from "@carbon/icons-react";

const headers = [
  { key: "time", header: "Timestamp" },
  { key: "officer", header: "Performed By (Officer)" },
  { key: "action", header: "Event Action" },
  { key: "target", header: "Target ID" },
  { key: "details", header: "Reason & Remarks" },
  { key: "priorState", header: "Prior State" },
];

interface RawAuditLog {
  id: number;
  applicationId: number;
  action: string;
  performedBy: string;
  timestamp: string;
  oldValues?: string;
  newValues?: string;
}

interface DisplayAuditRow {
  id: string;
  time: string;
  officer: string;
  action: string;
  target: string;
  details: string;
  priorState: string;
  rawAction: string;
}

export default function OfficerAuditLogs() {
  const [logs, setLogs] = useState<RawAuditLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [actionFilter, setActionFilter] = useState("ALL");

  const fetchLogs = useCallback(async () => {
    setIsLoading(true);
    try {
      const token = localStorage.getItem("officerToken");
      const response = await fetch("http://localhost:5119/api/Verification/audit-logs/all", {
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        }
      });
      if (response.ok) {
        const data = await response.json();
        setLogs(data);
      }
    } catch (e) {
      console.error("Failed to load audit logs", e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const handleLogout = async () => {
    const token = localStorage.getItem("officerToken");
    try {
      await fetch("http://localhost:5119/api/auth/logout", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      });
    } catch (error) {
      console.error("Logout failed:", error);
    } finally {
      localStorage.removeItem("officerToken");
      localStorage.removeItem("officerUser");
      window.location.href = "/officer/login";
    }
  };

  const rows: DisplayAuditRow[] = useMemo(() => {
    return logs
      .filter((log) => {
        if (actionFilter === "DELETED" && !log.action.toLowerCase().includes("delete")) return false;
        if (actionFilter === "APPROVED" && !log.action.toLowerCase().includes("approv")) return false;
        if (actionFilter === "REJECTED" && !log.action.toLowerCase().includes("reject")) return false;

        if (!searchQuery.trim()) return true;
        const q = searchQuery.toLowerCase();
        return (
          `APP-${log.applicationId}`.toLowerCase().includes(q) ||
          log.action.toLowerCase().includes(q) ||
          (log.performedBy || "").toLowerCase().includes(q) ||
          (log.newValues || "").toLowerCase().includes(q)
        );
      })
      .map((log) => ({
        id: log.id.toString(),
        time: new Date(log.timestamp).toLocaleString(),
        officer: log.performedBy || "System Officer",
        action: log.action,
        target: `APP-${log.applicationId}`,
        details: log.newValues || "—",
        priorState: log.oldValues || "—",
        rawAction: log.action
      }));
  }, [logs, searchQuery, actionFilter]);

  const totalDeletedCount = useMemo(() => {
    return logs.filter(l => l.action.toLowerCase().includes("delete")).length;
  }, [logs]);

  return (
    <HeaderContainer
      render={({ isSideNavExpanded, onClickSideNavExpand }) => (
        <>
          <Header aria-label="Registry Portal System">
            <HeaderMenuButton
              aria-label={isSideNavExpanded ? "Close menu" : "Open menu"}
              onClick={onClickSideNavExpand}
              isActive={isSideNavExpanded}
              isCollapsible
            />
            <HeaderName href="#" prefix="GSN">
              Registry Portal
            </HeaderName>

            <HeaderGlobalBar>
              <div className="w-[140px] sm:w-[280px]" style={{ marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                <Search size="sm" id="search-global" labelText="Search" placeholder="Search..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/officer/dashboard">
                  Application Queue
                </SideNavLink>
                <SideNavLink renderIcon={CheckmarkOutline} href="/officer/bulk-verification">
                  Bulk Verification
                </SideNavLink>
                <SideNavLink renderIcon={DataStructured} href="/officer/rejection-codes">
                  Rejection Codes
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">
                  Pending Reviews
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="/officer/audit-logs" isActive>
                  Audit Logs
                </SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile">
                  My Profile
                </SideNavLink>

                {/* Logout Button */}
                <div style={{ marginTop: 'auto', borderTop: '1px solid #393939' }}>
                  <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>
                    Sign Out
                  </SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          {/* Main Content */}
          <main className="mt-12 min-h-screen p-4 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64" style={{ backgroundColor: '#f4f4f4' }}>
            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Officer Audit Section
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Comprehensive, tamper-evident audit logs documenting all application reviews, stage approvals, and deletions performed by verifying officers.
              </p>
            </div>

            {/* Stat Cards */}
            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Total Audit Events</p>
                    <Security size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{logs.length}</h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Recorded in ledger</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #da1e28' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Applications Deleted</p>
                    <TrashCan size={20} color="#da1e28" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{totalDeletedCount}</h3>
                  <p style={{ color: '#da1e28', fontSize: '0.875rem', marginTop: '1rem' }}>Dismissed / No review needed</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #24a148' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Decisions & Approvals</p>
                    <CheckmarkOutline size={20} color="#24a148" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>
                    {logs.filter(l => l.action.toLowerCase().includes("approv")).length}
                  </h3>
                  <p style={{ color: '#24a148', fontSize: '0.875rem', marginTop: '1rem' }}>Verified milestone actions</p>
                </Tile>
              </Column>
            </Grid>

            {isLoading ? (
              <Loading description="Loading audit logs..." withOverlay={false} />
            ) : (
              <DataTable rows={rows} headers={headers}>
                {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
                  <TableContainer
                    title="Audit Section Records"
                    description="Official log entries recording actions, officer credentials, and justifications."
                  >
                    <TableToolbar>
                      <TableToolbarContent>
                        <TableToolbarSearch
                          onChange={(e) => setSearchQuery(typeof e === "string" ? e : e?.target?.value ?? "")}
                          persistent
                          placeholder="Search App ID, Officer Email, or Reason..."
                        />
                        <div style={{ width: '220px', marginLeft: '0.5rem' }}>
                          <Select
                            id="audit-filter-select"
                            labelText=""
                            hideLabel
                            value={actionFilter}
                            onChange={(e) => setActionFilter(e.target.value)}
                            size="md"
                          >
                            <SelectItem value="ALL" text="All Event Types" />
                            <SelectItem value="DELETED" text="Applications Deleted" />
                            <SelectItem value="APPROVED" text="Approvals & Milestones" />
                            <SelectItem value="REJECTED" text="Rejections" />
                          </Select>
                        </div>
                      </TableToolbarContent>
                    </TableToolbar>

                    <div style={{ overflowX: 'auto', width: '100%' }}>
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
                              No audit log records found.
                            </TableCell>
                          </TableRow>
                        ) : (
                          rows.map((row) => (
                            <TableRow {...getRowProps({ row })} key={row.id}>
                              {row.cells.map((cell) => {
                                if (cell.info.header === 'action') {
                                  const isDeleted = cell.value.toLowerCase().includes("delete");
                                  const isApproved = cell.value.toLowerCase().includes("approv");
                                  const isRejected = cell.value.toLowerCase().includes("reject");
                                  let tagType: "red" | "green" | "purple" | "blue" | "gray" = "blue";
                                  if (isDeleted) tagType = "red";
                                  else if (isApproved) tagType = "green";
                                  else if (isRejected) tagType = "purple";

                                  return (
                                    <TableCell key={cell.id}>
                                      <Tag type={tagType}>
                                        {cell.value}
                                      </Tag>
                                    </TableCell>
                                  );
                                }

                                if (cell.info.header === 'target') {
                                  return (
                                    <TableCell key={cell.id}>
                                      <span style={{ fontFamily: 'monospace', fontWeight: 600 }}>{cell.value}</span>
                                    </TableCell>
                                  );
                                }

                                if (cell.info.header === 'details') {
                                  return (
                                    <TableCell key={cell.id} style={{ maxWidth: '300px' }}>
                                      <span style={{ fontSize: '0.875rem', color: '#161616' }}>{cell.value}</span>
                                    </TableCell>
                                  );
                                }

                                if (cell.info.header === 'priorState') {
                                  return (
                                    <TableCell key={cell.id} style={{ maxWidth: '240px' }}>
                                      <span style={{ fontSize: '0.8rem', color: '#525252' }}>{cell.value}</span>
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
                    </div>
                  </TableContainer>
                )}
              </DataTable>
            )}
          </main>
        </>
      )}
    />
  );
}
