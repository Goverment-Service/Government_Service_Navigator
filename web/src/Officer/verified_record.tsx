import '@carbon/styles/css/styles.css';
import { useState, useEffect } from 'react';
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderMenuButton,
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
  Modal,
  Select,
  SelectItem,
  TextInput
} from "@carbon/react";
import {
  CheckmarkOutline,
  CloseOutline,
  Dashboard,
  Catalog,
  DataStructured,
  Download,
  Document,
  Time,
  User,
  Logout,
  Add,
  Notification
} from '@carbon/icons-react';

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
  const [rows, setRows] = useState<any[]>([]);
  const [editingRecord, setEditingRecord] = useState<any>(null);
  const [viewingRecord, setViewingRecord] = useState<any>(null);
  const [editStatus, setEditStatus] = useState('Approved');
  const [editComments, setEditComments] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const fetchVerifiedTasks = async () => {
    const token = localStorage.getItem('officerToken');
    try {
      const response = await fetch(`http://localhost:5119/api/Verification/tasks/verified`, {
        headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}) }
      });
      if (response.ok) {
        const data = await response.json();
        const mappedRows = data.map((t: any) => {
          return {
            id: t.id.toString(),
            appId: `GSN-2026-${t.applicationId}`,
            citizen: `User ${t.applicationId}`,
            service: 'General Verification',
            dateVerified: new Date(t.createdDate).toISOString().split('T')[0],
            status: t.status,
            comments: t.comments || ''
          };
        });
        setRows(mappedRows);
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    fetchVerifiedTasks();
  }, []);

  const handleSaveEdit = async () => {
    if (!editingRecord) return;
    setIsSaving(true);
    const token = localStorage.getItem('officerToken');
    try {
      const response = await fetch(`http://localhost:5119/api/Verification/tasks/${editingRecord.id}/decision`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: JSON.stringify({
          Status: editStatus,
          Comments: editComments
        })
      });
      if (response.ok) {
        await fetchVerifiedTasks();
        setEditingRecord(null);
      } else {
        console.error('Failed to update');
      }
    } catch (e) {
      console.error(e);
    } finally {
      setIsSaving(false);
    }
  };

  const handleExport = () => {
    if (rows.length === 0) return;
    const csvRows = [];
    const csvHeaders = ['App ID', 'Citizen Name', 'Service Type', 'Date Verified', 'Status'];
    csvRows.push(csvHeaders.join(','));
    
    for (const row of rows) {
      csvRows.push([
        row.appId,
        row.citizen,
        row.service,
        row.dateVerified,
        row.status
      ].join(','));
    }
    
    const blob = new Blob([csvRows.join('\n')], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.setAttribute('href', url);
    a.setAttribute('download', 'verified_records.csv');
    a.click();
  };
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
      window.location.href = "/officer/login"; //[cite: 6]
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
              <div className="w-[120px] sm:w-[200px] md:w-[280px]" style={{ marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
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
                <SideNavLink renderIcon={CheckmarkOutline} href="/officer/bulk-verification">
                  Bulk Verification
                </SideNavLink>
                <SideNavLink renderIcon={DataStructured} href="/officer/rejection-codes">
                  Rejection Codes
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
          <main className="mt-12 min-h-screen p-4 sm:p-6 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64" style={{ backgroundColor: '#f4f4f4' }}>
            
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
                        onClick={handleExport}
                      >
                        Export
                      </Button>
                    </TableToolbarContent>
                  </TableToolbar>

                  <div className="overflow-x-auto">
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
                            
                            // Format the actions column with a View button and Edit button
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                  <Button 
                                    size="sm" 
                                    kind="primary"
                                    onClick={() => {
                                      setEditingRecord(row);
                                      setEditStatus(row.cells.find((c: any) => c.info.header === 'status')?.value || 'Approved');
                                      setEditComments(row.comments || '');
                                    }}
                                    style={{ marginRight: '0.5rem' }}
                                  >
                                    Edit
                                  </Button>
                                  <Button 
                                    size="sm" 
                                    kind="ghost"
                                    onClick={() => setViewingRecord(row)}
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
                  </div>
                </TableContainer>
              )}
            </DataTable>

          </main>

          {/* Edit Record Modal */}
          <Modal
            open={!!editingRecord}
            onRequestClose={() => setEditingRecord(null)}
            onRequestSubmit={handleSaveEdit}
            modalHeading={`Edit Decision: ${editingRecord?.cells.find((c: any) => c.info.header === 'appId')?.value}`}
            primaryButtonText={isSaving ? "Saving..." : "Save Changes"}
            secondaryButtonText="Cancel"
            primaryButtonDisabled={isSaving}
          >
            <div style={{ marginBottom: '1rem' }}>
              <Select
                id="edit-status"
                labelText="Decision Status"
                value={editStatus}
                onChange={(e) => setEditStatus(e.target.value)}
              >
                <SelectItem value="Approved" text="Approved" />
                <SelectItem value="Rejected" text="Rejected" />
              </Select>
            </div>
            <div style={{ marginBottom: '1rem' }}>
              <TextInput
                id="edit-comments"
                labelText="Comments/Reasons"
                value={editComments}
                onChange={(e) => setEditComments(e.target.value)}
              />
            </div>
          </Modal>

          {/* View Record Modal */}
          <Modal
            open={!!viewingRecord}
            onRequestClose={() => setViewingRecord(null)}
            passiveModal
            modalHeading={`Application Details: ${viewingRecord?.cells.find((c: any) => c.info.header === 'appId')?.value}`}
          >
            {viewingRecord && (
              <div style={{ padding: '1rem 0', fontSize: '1rem', color: '#161616' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', letterSpacing: '0.32px' }}>Citizen Name</span>
                    <p style={{ marginTop: '0.25rem', fontWeight: 600 }}>{viewingRecord.cells.find((c: any) => c.info.header === 'citizen')?.value}</p>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', letterSpacing: '0.32px' }}>Service Type</span>
                    <p style={{ marginTop: '0.25rem', fontWeight: 600 }}>{viewingRecord.cells.find((c: any) => c.info.header === 'service')?.value}</p>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', letterSpacing: '0.32px' }}>Date Verified</span>
                    <p style={{ marginTop: '0.25rem', fontWeight: 600 }}>{viewingRecord.cells.find((c: any) => c.info.header === 'dateVerified')?.value}</p>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', letterSpacing: '0.32px' }}>Decision Status</span>
                    <div style={{ marginTop: '0.25rem' }}>
                      <Tag type={viewingRecord.cells.find((c: any) => c.info.header === 'status')?.value === 'Approved' ? 'green' : 'red'}>
                        {viewingRecord.cells.find((c: any) => c.info.header === 'status')?.value}
                      </Tag>
                    </div>
                  </div>
                </div>
                <div style={{ borderTop: '1px solid #e0e0e0', paddingTop: '1rem' }}>
                  <span style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', letterSpacing: '0.32px' }}>Officer Comments</span>
                  <p style={{ marginTop: '0.5rem', fontStyle: viewingRecord.comments ? 'normal' : 'italic', color: viewingRecord.comments ? '#161616' : '#8d8d8d' }}>
                    {viewingRecord.comments || 'No additional comments provided during verification.'}
                  </p>
                </div>
              </div>
            )}
          </Modal>
        </>
      )}
    />
  );
}