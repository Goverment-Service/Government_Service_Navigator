import '@carbon/styles/css/styles.css'; // This fixes the unstyled layout![cite: 5]
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
  Search
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings,
  Logout,
  Notification,
  Download,
  Catalog,
  Rule,
  Categories
} from "@carbon/icons-react";

// Expanded Table Data for Audit Logs
const headers = [
  { key: "time", header: "Timestamp" },
  { key: "officer", header: "User / System" },
  { key: "action", header: "Event Action" },
  { key: "target", header: "Target ID" },
  { key: "ip", header: "IP Address" },
  { key: "status", header: "Status" },
];

const rows = [
  { id: "1", time: "2026-08-12 18:05:12", officer: "Sarah Fernando", action: "Approved Application", target: "APP-8992", ip: "192.168.1.45", status: "Success" },
  { id: "2", time: "2026-08-12 17:50:01", officer: "Nuwan Perera", action: "Rejected Document", target: "DOC-1029", ip: "192.168.1.102", status: "Flagged" },
  { id: "3", time: "2026-08-12 17:00:00", officer: "System Auto-Sync", action: "Database Backup", target: "SYS-DB-01", ip: "Internal System", status: "Success" },
  { id: "4", time: "2026-08-12 16:45:22", officer: "Unknown", action: "Failed Login Attempt", target: "admin@gov.lk", ip: "103.24.55.12", status: "Failed" },
  { id: "5", time: "2026-08-12 15:30:10", officer: "Priyanka Silva", action: "Modified Global Settings", target: "SET-GLOBAL", ip: "192.168.1.88", status: "Success" },
  { id: "6", time: "2026-08-12 14:12:05", officer: "Kamal Dissanayake", action: "Suspended User Account", target: "USR-4091", ip: "192.168.1.22", status: "Warning" },
];

export default function AuditLogs() {
  const [, setAdminName] = useState("System Admin");

  useEffect(() => {
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.fullName) setAdminName(parsedUser.fullName);
      } catch {
        // ignore parse error[cite: 5]
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
                 <Search size="sm" id="search-records" labelText="Search" placeholder="Search records..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="#">
                  Overview
                </SideNavLink>

                {/* --- SUPUN'S ASSIGNED COMPONENTS --- */}
                <SideNavLink renderIcon={Catalog} href="/admin/services">
                  Service Catalog
                </SideNavLink>
                <SideNavLink renderIcon={Rule} href="/admin/services/rules">
                  Eligibility Rules
                </SideNavLink>
                <SideNavLink
                  renderIcon={Categories}
                  href="/admin/services/config"
                >
                  Service Configuration
                </SideNavLink>
                <SideNavLink
                  renderIcon={Rule}
                  href="/admin/services/simulator"
                >
                  Eligibility Simulator
                </SideNavLink>
                {/* ---------------------------------- */}

                <SideNavLink
                  renderIcon={UserMultiple}
                  href="/admin/manage-officers"
                >
                  Manage Officers
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="/admin/audit-logs" isActive>
                  Audit Logs
                </SideNavLink>
                <SideNavLink
                  renderIcon={Settings}
                  href="/admin/system-settings"
                >
                  System Settings
                </SideNavLink>

                {/* Logout Button */}
                <div
                  style={{ marginTop: "auto", borderTop: "1px solid #393939" }}
                >
                  <SideNavLink
                    renderIcon={Logout}
                    onClick={handleLogout}
                    style={{ cursor: "pointer" }}
                  >
                    Sign Out
                  </SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          {/* Main Content[cite: 5] */}
          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            
            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                System Audit Logs
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Immutable, timestamped record of all registry modifications, access attempts, and administrative actions.
              </p>
            </div>

            {/* Data Table with Toolbar */}
            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
                <TableContainer>
                  <TableToolbar>
                    <TableToolbarContent>
                      <TableToolbarSearch 
                        onChange={onInputChange} 
                        persistent 
                        placeholder="Filter by officer, action, or IP..." 
                      />
                      <Button 
                        kind="ghost" 
                        renderIcon={Download} 
                        onClick={() => console.log('Exporting CSV...')}
                      >
                        Export CSV
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
                            if (cell.info.header === 'status') {
                              // Dynamic tag coloring based on the log status[cite: 5]
                              let tagType = "green";
                              if (cell.value === "Failed" || cell.value === "Flagged") tagType = "red";
                              if (cell.value === "Warning") tagType = "magenta";

                              return (
                                <TableCell key={cell.id}>
                                  <Tag type={tagType as any}>
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            
                            // Render monospace font for IPs and Target IDs for better readability
                            if (cell.info.header === 'target' || cell.info.header === 'ip') {
                              return (
                                <TableCell key={cell.id} style={{ fontFamily: 'monospace', fontSize: '13px' }}>
                                  {cell.value}
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