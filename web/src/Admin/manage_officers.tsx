import '@carbon/styles/css/styles.css'; 
import React, { useState, useEffect, useCallback } from "react";
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
  OverflowMenuItem,
  Loading,
  Modal,
  TextInput,
  PasswordInput,
  Select,
  SelectItem,
  Stack,
  InlineNotification
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

const headers = [
  { key: "name", header: "Officer Name" },
  { key: "email", header: "Official Email" },
  { key: "role", header: "Role / Designation" },
  { key: "department", header: "Department" },
  { key: "status", header: "Account Status" },
  { key: "actions", header: "" }, 
];

export default function ManageOfficers() {
  const [adminName, setAdminName] = useState("System Admin");
  
  const [officerRows, setOfficerRows] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Modal & Form State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    department: "",
    role: "Verifying Officer"
  });

  const fetchOfficers = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch("http://localhost:5119/api/admin/officers");
      if (response.ok) {
        const data = await response.json();
        setOfficerRows(data);
      } else {
        console.error("Failed to fetch officers");
      }
    } catch (error) {
      console.error("Error connecting to backend:", error);
    } finally {
      setIsLoading(false);
    }
  }, []);

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

    fetchOfficers();
  }, [fetchOfficers]);

  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login";
  };

  const handleAddOfficer = async () => {
    setFormError(null);
    setIsSubmitting(true);
    
    try {
      const response = await fetch("http://localhost:5119/api/admin/officers", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        setIsModalOpen(false);
        setFormData({ fullName: "", email: "", password: "", department: "", role: "Verifying Officer" });
        fetchOfficers();
      } else {
        const errorData = await response.json();
        setFormError(errorData.message || "Failed to add officer. Please check the details.");
      }
    } catch (error) {
      setFormError("Network error. Could not connect to the server.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      {/* 1. HeaderContainer ONLY wraps the UI Shell components now */}
      <HeaderContainer
        render={({ isSideNavExpanded, onClickSideNavExpand }) => (
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
                <SideNavLink renderIcon={UserMultiple} href="/admin/manage-officers" isActive>
                  Manage Officers
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="/admin/audit-logs">
                  Audit Logs
                </SideNavLink>
                <SideNavLink renderIcon={Settings} href="/admin/system-settings">
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
        )}
      />

      {/* 2. Main content and Modal are safely outside, preventing focus-loss on re-renders */}
      <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
        
        <div style={{ marginBottom: '2rem' }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
            Officer Directory
          </h1>
          <p style={{ color: '#525252', marginTop: '0.5rem' }}>
            Provision, modify, and manage access for all government verifying officers.
          </p>
        </div>

        {isLoading ? (
          <Loading description="Loading data..." withOverlay={false} />
        ) : (
          <DataTable rows={officerRows} headers={headers}>
            {({ rows, headers, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
              <TableContainer>
                <TableToolbar>
                  <TableToolbarContent>
                    <TableToolbarSearch onChange={onInputChange} persistent />
                    <Button renderIcon={Add} onClick={() => setIsModalOpen(true)}>
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
                          if (cell.info.header === 'status') {
                            return (
                              <TableCell key={cell.id}>
                                <Tag type={cell.value === 'Active' ? 'blue' : 'red'}>
                                  {cell.value}
                                </Tag>
                              </TableCell>
                            );
                          }
                          
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

                          return <TableCell key={cell.id}>{cell.value}</TableCell>;
                        })}
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </DataTable>
        )}

        <Modal
          open={isModalOpen}
          onRequestClose={() => setIsModalOpen(false)}
          onRequestSubmit={handleAddOfficer}
          modalHeading="Add New Officer"
          primaryButtonText={isSubmitting ? "Saving..." : "Create Officer"}
          secondaryButtonText="Cancel"
          primaryButtonDisabled={isSubmitting || !formData.fullName || !formData.email || !formData.password || !formData.department}
        >
          <p style={{ marginBottom: '1.5rem', color: '#525252' }}>
            Fill in the details below to provision a new verifying officer account.
          </p>
          
          {formError && (
            <InlineNotification
              kind="error"
              title="Error"
              subtitle={formError}
              lowContrast
              style={{ marginBottom: '1rem' }}
            />
          )}

          <Stack gap={5}>
            <TextInput
              id="fullName"
              labelText="Full Name"
              placeholder="e.g. Kasun Bandara"
              value={formData.fullName}
              onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
              disabled={isSubmitting}
            />
            
            <TextInput
              id="email"
              type="email"
              labelText="Official Email"
              placeholder="officer@gov.lk"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              disabled={isSubmitting}
            />
            
            <PasswordInput
              id="password"
              labelText="Temporary Password"
              placeholder="Create a strong password"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              disabled={isSubmitting}
            />
            
            <TextInput
              id="department"
              labelText="Department"
              placeholder="e.g. Land Registry"
              value={formData.department}
              onChange={(e) => setFormData({ ...formData, department: e.target.value })}
              disabled={isSubmitting}
            />

            <Select
              id="role"
              labelText="Role Designation"
              value={formData.role}
              onChange={(e) => setFormData({ ...formData, role: e.target.value })}
              disabled={isSubmitting}
            >
              <SelectItem value="Verifying Officer" text="Verifying Officer" />
              <SelectItem value="Department Admin" text="Department Admin" />
              <SelectItem value="Auditor" text="Auditor" />
            </Select>
          </Stack>
        </Modal>

      </main>
    </>
  );
}