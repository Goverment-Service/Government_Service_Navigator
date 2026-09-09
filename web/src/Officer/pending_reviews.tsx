import '@carbon/styles/css/styles.css';
import { useState, useEffect } from "react";
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
  Button
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
  Catalog
} from "@carbon/icons-react";

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

const rows = [
  { id: "1", appId: "GSN-2026-9102", citizen: "Amila Kumara", service: "Business Registration", reason: "Missing NIC Upload", days: "3 Days", status: "Awaiting Citizen" },
  { id: "2", appId: "GSN-2026-9088", citizen: "Nethmi Silva", service: "Income Certificate", reason: "Requires Supervisor Approval", days: "1 Day", status: "In Progress" },
  { id: "3", appId: "GSN-2026-8799", citizen: "Dinesh Bandara", service: "Residence Certificate", reason: "Mismatched Address Details", days: "5 Days", status: "Action Required" },
  { id: "4", appId: "GSN-2026-8745", citizen: "Tharindu Perera", service: "Character Verification", reason: "Pending Police Clearance", days: "14 Days", status: "External Block" },
];

export default function PendingReviews() {
  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login";
  };

  return (
    <HeaderContainer
      render={({ isSideNavExpanded }) => (
        <>
          <Header aria-label="Registry Portal System">
            <HeaderName href="#" prefix="GSN">
              Registry Portal
            </HeaderName>
            
            <HeaderGlobalBar>
              <div style={{ width: '280px', marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-global" labelText="Search" placeholder="Search NIC or Application ID..." />
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
                <SideNavLink renderIcon={Catalog} href="/officer/applications">
                  All Applications
                </SideNavLink>
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create">
                  New Application
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">
                  Verified Records
                </SideNavLink>
                {/* Active state moved to Pending Reviews */}
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews" isActive>
                  Pending Reviews
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
          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            
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
                              let tagColor = 'blue';
                              if (cell.value === 'Awaiting Citizen') tagColor = 'purple';
                              if (cell.value === 'Action Required') tagColor = 'red';
                              if (cell.value === 'External Block') tagColor = 'gray';

                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={tagColor as any}>
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
                                    onClick={() => alert(`Taking action on ${row.cells.find(c => c.info.header === 'appId')?.value}`)}
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