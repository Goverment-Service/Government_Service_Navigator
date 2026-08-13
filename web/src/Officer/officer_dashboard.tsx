import '@carbon/styles/css/styles.css';
import React, { useState, useEffect } from "react";
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
  CheckmarkOutline,
  Settings
} from "@carbon/icons-react";

// Table Data for Verification Queue
const headers = [
  { key: "appId", header: "App ID" },
  { key: "citizen", header: "Citizen Name" },
  { key: "service", header: "Service Type" },
  { key: "time", header: "Submitted" },
  { key: "priority", header: "Priority" },
  { key: "actions", header: "" },
];

const rows = [
  { id: "1", appId: "GSN-2026-9012", citizen: "Kasun Bandara", service: "Business Registration", time: "15 mins ago", priority: "High" },
  { id: "2", appId: "GSN-2026-9015", citizen: "Chamari Silva", service: "Residence Certificate", time: "42 mins ago", priority: "Normal" },
  { id: "3", appId: "GSN-2026-9021", citizen: "Amesh Perera", service: "Character Verification", time: "1 hour ago", priority: "Normal" },
];

export default function OfficerDashboard() {
  const [officerName, setOfficerName] = useState("Verifying Officer");

  useEffect(() => {
    // Retrieve the officer details stored during login[cite: 4]
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.fullName) setOfficerName(parsedUser.fullName);
        else if (parsedUser.email) setOfficerName(parsedUser.email.split("@")[0]);
      } catch (e) {
        // Handle parse error silently[cite: 4]
      }
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login";
  };

  return (
    <HeaderContainer
      render={({ isSideNavExpanded, onClickSideNavExpand }) => (
        <>
          <Header aria-label="Registry Portal System">
            <HeaderName href="#" prefix="GSN">
              Registry Portal
            </HeaderName>
            
            <HeaderGlobalBar>
              <div style={{ width: '280px', marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-queue" labelText="Search" placeholder="Search NIC or Application ID..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="#" isActive>
                  Application Queue
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="#">
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="#">
                  Pending Reviews
                </SideNavLink>
                <SideNavLink renderIcon={Settings} href="/settings">
                  System Settings
                </SideNavLink>
                <SideNavLink renderIcon={User} href="#">
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
                Welcome back, {officerName}
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Review assigned citizen submissions and maintain accountable registry records.
              </p>
            </div>

            {/* Stat Cards mapped to Carbon Grid/Tiles */}
            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #da1e28' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Queue Pending</p>
                    <Warning size={20} color="#da1e28" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>24</h3>
                  <p style={{ color: '#da1e28', fontSize: '0.875rem', marginTop: '1rem' }}>Requires your review</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Reviewed Today</p>
                    <CheckmarkOutline size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>18</h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>+4 from yesterday</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Approved Total</p>
                    <Document size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>482</h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>This month</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Accuracy Rating</p>
                    <User size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>99.4%</h3>
                  <p style={{ color: '#24a148', fontSize: '0.875rem', marginTop: '1rem' }}>Audit compliant</p>
                </Tile>
              </Column>
            </Grid>

            {/* Data Table for Active Verification Queue */}
            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
                <TableContainer 
                  title="Active Verification Queue" 
                  description="Citizen submissions waiting for departmental review and timestamping."
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
                      {rows.map((row) => (
                        <TableRow {...getRowProps({ row })} key={row.id}>
                          {row.cells.map((cell) => {
                            
                            // Format Priority with Carbon Tags[cite: 4]
                            if (cell.info.header === 'priority') {
                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={cell.value === 'High' ? 'red' : 'blue'}>
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            
                            // Format the actions column with a Review button[cite: 4]
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                  <Button 
                                    size="sm" 
                                    onClick={() => alert(`Reviewing application ${row.cells.find(c => c.info.header === 'appId')?.value}`)}
                                  >
                                    Review
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