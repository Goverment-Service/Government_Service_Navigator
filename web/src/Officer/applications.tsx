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
  DataTable,
  TableContainer,
  Table,
  TableHead,
  TableRow,
  TableHeader,
  TableBody,
  TableCell,
  Button,
  Search,
  Tag
} from "@carbon/react";
import {
  Dashboard,
  Document,
  Time,
  User,
  Logout,
  Notification,
  Add,
  Catalog,
  Edit,
  View
} from "@carbon/icons-react";

const headers = [
  { key: "templateId", header: "Template ID" },
  { key: "formName", header: "Form Name / Title" },
  { key: "createdDate", header: "Created Date" },
  { key: "fieldsCount", header: "Fields" },
  { key: "status", header: "Status" },
  { key: "actions", header: "Actions" },
];

const initialRows = [
  { id: "1", templateId: "TPL-001", formName: "FORM 1 - Company Registration", createdDate: "2026-09-01", fieldsCount: 10, status: "Active" },
  { id: "2", templateId: "TPL-002", formName: "Business Name Registration (Sinhala)", createdDate: "2026-09-03", fieldsCount: 8, status: "Active" },
  { id: "3", templateId: "TPL-003", formName: "Birth Certificate Copy Request", createdDate: "2026-09-05", fieldsCount: 5, status: "Draft" },
  { id: "4", templateId: "TPL-004", formName: "Residence Certificate Application", createdDate: "2026-09-06", fieldsCount: 6, status: "Active" },
];

export default function ApplicationsList() {
  const [rows, setRows] = useState(initialRows);

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
            <HeaderName href="#" prefix="GSN">Registry Portal</HeaderName>
            
            <HeaderGlobalBar>
              <div style={{ width: '280px', marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-templates" labelText="Search" placeholder="Search Templates..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/officer/dashboard">Application Queue</SideNavLink>
                <SideNavLink renderIcon={Catalog} href="/officer/applications" isActive>All Applications</SideNavLink>
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create">New Application</SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">Verified Records</SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">Pending Reviews</SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile">My Profile</SideNavLink>
                <div style={{ marginTop: 'auto', borderTop: '1px solid #393939' }}>
                  <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>Sign Out</SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <div>
                <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Created Applications & Templates</h1>
                <p style={{ color: '#525252', marginTop: '0.5rem' }}>Manage and review all customizable application forms created by officers.</p>
              </div>
              <Button renderIcon={Add} onClick={() => window.location.href = "/officer/Application_create/application_create"} style={{ backgroundColor: '#0f62fe' }}>
                Create New Template
              </Button>
            </div>

            <DataTable rows={rows} headers={headers}>
              {({ rows, headers, getTableProps, getHeaderProps, getRowProps }) => (
                <TableContainer title="Template Directory" description="List of all application templates available in the system.">
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
                               return (
                                 <TableCell key={cell.id}>
                                   <Tag type={cell.value === 'Active' ? 'green' : 'gray'}>
                                     {cell.value}
                                   </Tag>
                                 </TableCell>
                               );
                            }
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem' }}>
                                  <Button kind="ghost" size="sm" renderIcon={Edit} iconDescription="Edit" hasIconOnly onClick={() => window.location.href = "/officer/Application_create/application_create"} />
                                  <Button kind="ghost" size="sm" renderIcon={View} iconDescription="View" hasIconOnly onClick={() => alert("Preview feature coming soon")} />
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
