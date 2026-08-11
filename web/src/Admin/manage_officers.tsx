import '@carbon/styles/css/styles.css'; // Maintains the Carbon styling[cite: 3]
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
  Button,
  Tag,
  Search,
  OverflowMenu,
  OverflowMenuItem
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings,
  Logout,
  Notification,
  Add
} from "@carbon/icons-react";

// Table Data for Officers
const headers = [
  { key: "name", header: "Officer Name" },
  { key: "email", header: "Official Email" },
  { key: "role", header: "Role / Designation" },
  { key: "department", header: "Department" },
  { key: "status", header: "Account Status" },
  { key: "actions", header: "" }, // Empty header for the overflow menu
];

const rows = [
  { id: "1", name: "Sarah Fernando", email: "sarah.f@gov.lk", role: "Verifying Officer", department: "Land Registry", status: "Active" },
  { id: "2", name: "Nuwan Perera", email: "nuwan.p@gov.lk", role: "Department Admin", department: "Motor Traffic", status: "Active" },
  { id: "3", name: "Priyanka Silva", email: "priyanka.s@gov.lk", role: "Verifying Officer", department: "Immigration", status: "Suspended" },
  { id: "4", name: "Kamal Dissanayake", email: "kamal.d@gov.lk", role: "Verifying Officer", department: "Pensions", status: "Active" },
];

export default function ManageOfficers() {
  const [, setAdminName] = useState("System Admin");

  useEffect(() => {
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.fullName) setAdminName(parsedUser.fullName);
      } catch {
        // ignore parse error
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
      render={({ isSideNavExpanded }) => (
        <>
          <Header aria-label="Registry Admin System">
            <HeaderName href="#" prefix="GSN">
              Registry Admin
            </HeaderName>
            
            <HeaderGlobalBar>
              <div style={{ width: '250px', marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-records-global" labelText="Search" placeholder="Search records..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/admin/dashboard">
                  Overview
                </SideNavLink>
                {/* Set Manage Officers as the active link */}
                <SideNavLink renderIcon={UserMultiple} href="/admin/manage-officers" isActive>
                  Manage Officers
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="#">
                  Audit Logs
                </SideNavLink>
                <SideNavLink renderIcon={Settings} href="#">
                  System Settings
                </SideNavLink>
                
                <div style={{ marginTop: 'auto', borderTop: '1px solid #393939' }}>
                  <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>
                    Sign Out
                  </SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          {/* Main Content[cite: 3] */}
          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            
            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Officer Directory
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Provision, modify, and manage access for all government verifying officers.
              </p>
            </div>

            {/* Interactive Data Table */}
            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
                <TableContainer>
                  {/* Toolbar for Search and Add Actions */}
                  <TableToolbar>
                    <TableToolbarContent>
                      <TableToolbarSearch onChange={onInputChange} persistent />
                      <Button renderIcon={Add} onClick={() => console.log('Open Add Officer Modal')}>
                        Add Officer
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
                            // Format the status with Tags
                            if (cell.info.header === 'status') {
                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={cell.value === 'Active' ? 'blue' : 'red'}>
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            
                            // Format the actions column with an Overflow Menu
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: 0, width: '48px' }}>
                                  <OverflowMenu flipped direction="bottom">
                                    <OverflowMenuItem itemText="Edit Profile" />
                                    <OverflowMenuItem itemText="Reset Password" />
                                    <OverflowMenuItem hasDivider isDelete itemText="Suspend Account" />
                                  </OverflowMenu>
                                </TableCell>
                              );
                            }

                            // Default cell rendering
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