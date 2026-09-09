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
  Download,
  CheckmarkOutline,
  CloseOutline,
  Add,
  Catalog
} from "@carbon/icons-react";

// Table Data for Verified Records
const headers = [
  { key: "appId", header: "App ID" },
  { key: "citizen", header: "Citizen Name" },
  { key: "service", header: "Service Type" },
  { key: "dateVerified", header: "Date Verified" },
  { key: "status", header: "Status" },
  { key: "actions", header: "" },
];

const rows = [
  { id: "1", appId: "GSN-2026-8901", citizen: "Sunil Perera", service: "Business Registration", dateVerified: "2026-08-12", status: "Approved" },
  { id: "2", appId: "GSN-2026-8895", citizen: "Nimali Fernando", service: "Residence Certificate", dateVerified: "2026-08-11", status: "Approved" },
  { id: "3", appId: "GSN-2026-8850", citizen: "Ruwan Kumara", service: "Character Verification", dateVerified: "2026-08-10", status: "Rejected" },
  { id: "4", appId: "GSN-2026-8842", citizen: "Deva Silva", service: "Income Certificate", dateVerified: "2026-08-10", status: "Approved" },
];

export default function VerifiedRecords() {
  const [officerName, setOfficerName] = useState("Verifying Officer");

  useEffect(() => {
    // Retrieve the officer details stored during login[cite: 6]
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.fullName) setOfficerName(parsedUser.fullName);
        else if (parsedUser.email) setOfficerName(parsedUser.email.split("@")[0]);
      } catch (e) {
        // Handle parse error silently[cite: 6]
      }
    }
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login"; //[cite: 6]
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
                {/* Active state moved to Verified Records[cite: 6] */}
                <SideNavLink renderIcon={Document} href="/officer/verified-records" isActive>
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">
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
                Verified Records
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Search and review historically processed applications and official decisions.
              </p>
            </div>

            {/* Stat Cards for Historical Context[cite: 6] */}
            <Grid style={{ paddingLeft: 0, paddingRight: 0, marginBottom: '2rem' }}>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Total Processed</p>
                    <Document size={20} />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>1,284</h3>
                  <p style={{ color: '#525252', fontSize: '0.875rem', marginTop: '1rem' }}>Lifetime records</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #24a148' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Total Approved</p>
                    <CheckmarkOutline size={20} color="#24a148" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>1,150</h3>
                  <p style={{ color: '#24a148', fontSize: '0.875rem', marginTop: '1rem' }}>90% approval rate</p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: '4px solid #da1e28' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Total Rejected</p>
                    <CloseOutline size={20} color="#da1e28" />
                  </div>
                  <h3 style={{ fontSize: '2.5rem', fontWeight: 300, margin: '0.5rem 0' }}>134</h3>
                  <p style={{ color: '#da1e28', fontSize: '0.875rem', marginTop: '1rem' }}>10% rejection rate</p>
                </Tile>
              </Column>
            </Grid>

            {/* Data Table for Verified Records[cite: 6] */}
            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
                <TableContainer 
                  title="Record Archive" 
                  description="Complete history of all decisions made by you."
                >
                  <TableToolbar>
                    <TableToolbarContent>
                      <TableToolbarSearch 
                        onChange={onInputChange} 
                        persistent 
                        placeholder="Filter by App ID, Citizen, or Date..." 
                      />
                      <Button 
                        kind="ghost" 
                        renderIcon={Download} 
                        onClick={() => console.log('Exporting Data...')}
                      >
                        Export
                      </Button>
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
                            
                            // Format Status with Carbon Tags[cite: 6]
                            if (cell.info.header === 'status') {
                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={cell.value === 'Approved' ? 'green' : 'red'}>
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            
                            // Format the actions column with a View button[cite: 6]
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                  <Button 
                                    size="sm" 
                                    kind="ghost"
                                    onClick={() => alert(`Viewing details for ${row.cells.find(c => c.info.header === 'appId')?.value}`)}
                                  >
                                    View Record
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