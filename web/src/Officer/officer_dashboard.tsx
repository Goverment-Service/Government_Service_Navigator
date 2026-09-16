import '@carbon/styles/css/styles.css';
import { useState, useEffect } from "react";
import { useParams, Navigate } from "react-router-dom";
import { getCategoryForDepartment, getDepartmentLabel } from "../constants/departments";
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  SideNav,
  SideNavItems,
  SideNavLink,
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
  Tag,
  Search,
  Button,
  Loading,
  HeaderMenuButton
} from "@carbon/react";
import {
  Dashboard,
  Document,
  Time,
  User,
  Logout,
  Notification,
  Warning,
  CheckmarkOutline,
  Add,
  Catalog,
  DataStructured
} from "@carbon/icons-react";

const headers = [
  { key: "appId", header: "Application ID" },
  { key: "serviceName", header: "Service" },
  { key: "department", header: "Department" },
  { key: "status", header: "Status" },
  { key: "time", header: "Submitted" },
  { key: "priority", header: "Priority" },
  { key: "actions", header: "" },
];

interface QueueRow {
  id: string;
  appId: string;
  serviceName: string;
  department: string;
  status: string;
  time: string;
  priority: string;
}

interface OfficerStats {
  reviewedToday: number;
  reviewedYesterday: number;
  approvedThisMonth: number;
  approvalRate: number | null;
}

function formatRelativeTime(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins} min${diffMins === 1 ? "" : "s"} ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours} hour${diffHours === 1 ? "" : "s"} ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays} day${diffDays === 1 ? "" : "s"} ago`;
}

function getStoredOfficerName(): string {
  const storedUser = localStorage.getItem("officerUser");
  if (storedUser) {
    try {
      const parsedUser = JSON.parse(storedUser);
      if (parsedUser.fullName) return parsedUser.fullName;
      if (parsedUser.email) return parsedUser.email.split("@")[0];
    } catch {
      // Handle parse error silently
    }
  }
  return "Verifying Officer";
}

function getStoredOfficerDepartment(): string | null {
  const storedUser = localStorage.getItem("officerUser");
  if (storedUser) {
    try {
      const parsedUser = JSON.parse(storedUser);
      return parsedUser.department || null;
    } catch {
      // Handle parse error silently
    }
  }
  return null;
}

export default function OfficerDashboard() {
  const { deptSlug } = useParams<{ deptSlug?: string }>();
  const [officerName] = useState(getStoredOfficerName);
  const [officerDepartment] = useState(getStoredOfficerDepartment);
  const [rows, setRows] = useState<QueueRow[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState<OfficerStats | null>(null);

  // /officer/:deptSlug/dashboard scopes the queue to that department; the
  // plain /officer/dashboard falls back to the officer's own stored
  // department (or shows everything if they have none).
  const routeDepartmentLabel = deptSlug ? getDepartmentLabel(deptSlug) : null;
  const departmentLabel = routeDepartmentLabel || officerDepartment;
  const category = departmentLabel ? getCategoryForDepartment(departmentLabel) : null;

  useEffect(() => {
    const token = localStorage.getItem("officerToken");
    const authHeaders = { Authorization: `Bearer ${token}` };
    const categoryParam = category ? `?category=${encodeURIComponent(category)}` : "";

    const fetchQueue = async () => {
      try {
        const response = await fetch(`http://localhost:5119/api/verification/tasks/pending${categoryParam}`, {
          headers: authHeaders,
        });
        if (response.ok) {
          const data: {
            id: number;
            applicationId: number;
            applicationReference?: string | null;
            serviceName?: string | null;
            department?: string | null;
            status: string;
            createdDate: string;
          }[] = await response.json();
          setRows(
            data.map((task) => {
              const ageHours = (Date.now() - new Date(task.createdDate).getTime()) / 3_600_000;
              return {
                id: task.id.toString(),
                appId: task.applicationReference || `APP-${task.applicationId}`,
                serviceName: task.serviceName || "-",
                department: task.department || "-",
                status: task.status,
                time: formatRelativeTime(task.createdDate),
                priority: ageHours > 24 ? "High" : "Normal",
              };
            })
          );
        } else {
          console.error("Failed to fetch verification queue");
        }
      } catch (error) {
        console.error("Error fetching verification queue:", error);
      } finally {
        setIsLoading(false);
      }
    };

    const fetchStats = async () => {
      try {
        const response = await fetch("http://localhost:5119/api/verification/stats", {
          headers: authHeaders,
        });
        if (response.ok) {
          const data = await response.json();
          setStats({
            reviewedToday: data.reviewedToday,
            reviewedYesterday: data.reviewedYesterday,
            approvedThisMonth: data.approvedThisMonth,
            approvalRate: data.approvalRate,
          });
        } else {
          console.error("Failed to fetch officer stats");
        }
      } catch (error) {
        console.error("Error fetching officer stats:", error);
      }
    };

    fetchQueue();
    fetchStats();
  }, [category]);

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

  // Unknown department slug - send back to the generic dashboard instead of a broken page.
  if (deptSlug && !routeDepartmentLabel) {
    return <Navigate to="/officer/dashboard" replace />;
  }

  return (
    <HeaderContainer
      render={({ isSideNavExpanded, onClickSideNavExpand }) => (
        <>
          <Header aria-label={departmentLabel ? `${departmentLabel} Registry Portal` : "Registry Portal System"}>
            <HeaderMenuButton
              aria-label={isSideNavExpanded ? "Close menu" : "Open menu"}
              onClick={onClickSideNavExpand}
              isActive={isSideNavExpanded}
              isCollapsible
            />
            <HeaderName href="#" prefix="GSN">
              {departmentLabel ? `${departmentLabel} Registry` : "Registry Portal"}
            </HeaderName>

            <HeaderGlobalBar>
              <div className="w-[140px] sm:w-[280px]" style={{ marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-queue" labelText="Search" placeholder="Search NIC or Application ID..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href={deptSlug ? `/officer/${deptSlug}/dashboard` : "/officer/dashboard"} isActive>
                  Application Queue
                </SideNavLink>
                                <SideNavLink renderIcon={CheckmarkOutline} href="/officer/bulk-verification">
                  Bulk Verification
                </SideNavLink>
                <SideNavLink renderIcon={DataStructured} href="/officer/rejection-codes">
                  Rejection Codes
                </SideNavLink>
<SideNavLink renderIcon={Catalog} href="/officer/applications">
                  All Applications
                </SideNavLink>
                {/* Updated: Navigates to the new page instead of opening a modal */}
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create">
                  New Application
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">
                  Pending Reviews
                </SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile">
                  My Profile
                </SideNavLink>
                
                <div style={{ marginTop: 'auto', borderTop: '1px solid #393939' }}>
                  <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>
                    Sign Out
                  </SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          <main className="mt-12 min-h-screen p-4 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64" style={{ backgroundColor: '#f4f4f4' }}>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <div>
                {departmentLabel && (
                  <Tag type="blue" style={{ marginBottom: '0.5rem' }}>
                    {departmentLabel}
                  </Tag>
                )}
                <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                  Welcome back, {officerName}
                </h1>
                <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                  {departmentLabel
                    ? `Review citizen submissions routed to the ${departmentLabel}.`
                    : "Review assigned citizen submissions and maintain accountable registry records."}
                </p>
              </div>
            </div>

            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #da1e28' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Queue Pending</p>
                    <Warning size={20} color="#da1e28" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>{rows.length}</h3>
                  <p style={{ color: '#da1e28', fontSize: '0.875rem', marginTop: '1rem' }}>Requires your review</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Reviewed Today</p>
                    <CheckmarkOutline size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>
                    {stats ? stats.reviewedToday : '—'}
                  </h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>
                    {stats
                      ? `${stats.reviewedToday - stats.reviewedYesterday >= 0 ? '+' : ''}${stats.reviewedToday - stats.reviewedYesterday} from yesterday`
                      : 'Loading…'}
                  </p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Approved Total</p>
                    <Document size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>
                    {stats ? stats.approvedThisMonth : '—'}
                  </h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>This month</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Approval Rate</p>
                    <User size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>
                    {stats && stats.approvalRate !== null ? `${stats.approvalRate}%` : '—'}
                  </h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>
                    {stats && stats.approvalRate !== null ? 'Share of your decisions approved' : 'No decisions recorded yet'}
                  </p>
                </Tile>
              </Column>
            </Grid>

            {isLoading ? (
              <Loading description="Loading verification queue" withOverlay={false} />
            ) : (
              <DataTable rows={rows} headers={headers}>
                {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
                  <TableContainer
                    title="Active Verification Queue"
                    description="Pending verification tasks waiting for departmental review and timestamping."
                  >
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
                              No pending applications in the queue.
                            </TableCell>
                          </TableRow>
                        ) : (
                          rows.map((row) => (
                            <TableRow {...getRowProps({ row })} key={row.id}>
                              {row.cells.map((cell) => {
                                if (cell.info.header === 'status') {
                                  return (
                                    <TableCell key={cell.id}>
                                      <Tag type="blue">{cell.value}</Tag>
                                    </TableCell>
                                  );
                                }
                                if (cell.info.header === 'priority') {
                                  return (
                                    <TableCell key={cell.id}>
                                      <Tag type={cell.value === 'High' ? 'red' : 'blue'}>
                                        {cell.value}
                                      </Tag>
                                    </TableCell>
                                  );
                                }
                                if (cell.info.header === 'actions') {
                                  return (
                                    <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                      <Button
                                        size="sm"
                                        onClick={() => window.location.href = `/officer/verification-workspace/${row.id}`}
                                      >
                                        Review
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

          </main>
        </>
      )}
    />
  );
}

