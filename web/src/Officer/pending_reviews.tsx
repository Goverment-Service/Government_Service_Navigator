import '@carbon/styles/css/styles.css';
import { useState, useEffect } from 'react';
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
  TableToolbar,
  TableToolbarContent,
  TableToolbarSearch,
  Tag,
  Search,
  Button,
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
  Hourglass,
  Email,
  Flag,
  Add,
  Catalog,
  CheckmarkOutline,
  DataStructured 
} from "@carbon/icons-react";
import { useNavigate } from 'react-router-dom';

// Table Data for Pending Reviews
const headers = [
  { key: "appId", header: "App ID" },
  { key: "citizen", header: "Citizen Name" },
  { key: "service", header: "Service Type" },
  { key: "reason", header: "Pending Reason" },
  { key: "days", header: "Time Pending" },
  { key: "status", header: "Status" },
  { key: "actions", header: "" },
];

export default function PendingReviews() {
  const navigate = useNavigate();
  const [rows, setRows] = useState<any[]>([]);

  useEffect(() => {
    const fetchPendingTasks = async () => {
      const token = localStorage.getItem("officerToken");
      try {
        const response = await fetch(`${import.meta.env.VITE_API_URL}/api/Verification/tasks/pending`, {
          headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}) }
        });
        if (response.ok) {
          const data = await response.json();
          const mappedRows = data.map((t: any) => {
            const daysPending = Math.floor((new Date().getTime() - new Date(t.createdDate).getTime()) / (1000 * 3600 * 24));
            return {
              id: t.id.toString(),
              appId: `GSN-2026-${t.applicationId}`,
              citizen: `User ${t.applicationId}`,
              service: "General Verification",
              reason: "Requires Officer Review",
              days: daysPending === 0 ? "Today" : `${daysPending} Days`,
              status: t.status === "Pending" ? "Action Required" : t.status
            };
          });
          setRows(mappedRows);
        }
      } catch (e) {
        console.error(e);
      }
    };
    fetchPendingTasks();
  }, []);

    const handleLogout = async () => {
    const token = localStorage.getItem("officerToken");
    try {
      await fetch(`${import.meta.env.VITE_API_URL}/api/auth/logout`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: "Bearer " } : {}),
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
                 <Search size="sm" id="search-global" labelText="Search" placeholder="Search NIC or Application ID..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

                        <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/officer/dashboard" isActive={window.location.pathname.includes('dashboard')}>
                  Application Queue
                </SideNavLink>
                <SideNavLink renderIcon={CheckmarkOutline} href="/officer/bulk-verification" isActive={window.location.pathname.includes('bulk-verification')}>
                  Bulk Verification
                </SideNavLink>
                <SideNavLink renderIcon={DataStructured} href="/officer/rejection-codes" isActive={window.location.pathname.includes('rejection-codes')}>
                  Rejection Codes
                </SideNavLink>
                <SideNavLink renderIcon={Catalog} href="/officer/applications" isActive={window.location.pathname.includes('applications')}>
                  All Applications
                </SideNavLink>
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create" isActive={window.location.pathname.includes('application_create')}>
                  New Application
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records" isActive={window.location.pathname.includes('verified-records')}>
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews" isActive={window.location.pathname.includes('pending-reviews')}>
                  Pending Reviews
                </SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile" isActive={window.location.pathname.includes('profile')}>
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

          {/* Main Content */}
          <main className="mt-12 min-h-screen p-4 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64" style={{ backgroundColor: '#f4f4f4' }}>

            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Pending Reviews
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Manage stalled applications, follow up on missing documents, and clear blocked queues.
              </p>
            </div>

            {/* Stat Cards for Pending Context */}
            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Total Pending</p>
                    <Hourglass size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>45</h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Active on hold</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #8a3ffc' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Awaiting Citizen</p>
                    <Email size={20} color="#8a3ffc" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>12</h3>
                  <p style={{ color: '#8a3ffc', fontSize: '0.875rem', marginTop: '1rem' }}>Missing documents</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #da1e28' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Action Required</p>
                    <Flag size={20} color="#da1e28" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>5</h3>
                  <p style={{ color: '#da1e28', fontSize: '0.875rem', marginTop: '1rem' }}>Flagged issues</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #f1c21b' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>SLA Overdue</p>
                    <Warning size={20} color="#f1c21b" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>2</h3>
                  <p style={{ color: '#f1c21b', fontSize: '0.875rem', marginTop: '1rem' }}>Exceeded target time</p>
                </Tile>
              </Column>
            </Grid>

            {/* Data Table for Pending Reviews */}
            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
                <TableContainer 
                  title="Stalled Applications" 
                  description="Items that require manual intervention before they can be verified."
                >
                  <TableToolbar>
                    <TableToolbarContent>
                      <TableToolbarSearch 
                        onChange={onInputChange} 
                        persistent 
                        placeholder="Filter by App ID, Citizen, or Status..." 
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
                      {rows.map((row) => (
                        <TableRow {...getRowProps({ row })} key={row.id}>
                          {row.cells.map((cell) => {
                            
                            // Format Status with Carbon Tags based on state severity
                            if (cell.info.header === 'status') {
                              let tagColor: 'blue' | 'purple' | 'red' | 'gray' = 'blue';
                              if (cell.value === 'Awaiting Citizen') tagColor = 'purple';
                              if (cell.value === 'Action Required') tagColor = 'red';
                              if (cell.value === 'External Block') tagColor = 'gray';

                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={tagColor}>
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            
                            // Dynamic Action Buttons
                            if (cell.info.header === 'actions') {
                              const status = row.cells.find(c => c.info.header === 'status')?.value;
                              
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                  <Button 
                                    size="sm" 
                                    kind={status === 'Awaiting Citizen' ? "secondary" : "primary"}
                                    onClick={() => {
                                      if (status === 'Awaiting Citizen') {
                                        alert(`Sending reminder to citizen for ${row.cells.find(c => c.info.header === 'appId')?.value}`);
                                      } else {
                                        navigate(`/officer/workspace/${row.id}`);
                                      }
                                    }}
                                  >
                                    {status === 'Awaiting Citizen' ? "Send Reminder" : "Resume Review"}
                                  </Button>
                                </TableCell>
                              );
                            }

                            return <TableCell key={cell.id}>{cell.value}</TableCell>;
                          })}
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </DataTable>

          </main>
        </>
      )}
    />
  );
}




