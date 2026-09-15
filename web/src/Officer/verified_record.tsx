import '@carbon/styles/css/styles.css';
import { useState, useEffect } from 'react';
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderMenuButton,
  HeaderGlobalBar,
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
  TextArea,
  FormGroup
} from '@carbon/react';
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
  Add
} from '@carbon/icons-react';

const headers = [
  { key: 'appId', header: 'App ID' },
  { key: 'citizen', header: 'Citizen Name' },
  { key: 'service', header: 'Service Type' },
  { key: 'dateVerified', header: 'Date Verified' },
  { key: 'status', header: 'Status' },
  { key: 'actions', header: '' },
];

export default function VerifiedRecords() {
  const [rows, setRows] = useState<any[]>([]);
  const [editingRecord, setEditingRecord] = useState<any>(null);
  const [editStatus, setEditStatus] = useState('Approved');
  const [editComments, setEditComments] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  const fetchVerifiedTasks = async () => {
    const token = localStorage.getItem('officerToken');
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/Verification/tasks/verified`, {
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
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/Verification/tasks/${editingRecord.id}/decision`, {
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
    const token = localStorage.getItem('officerToken');
    try {
      await fetch(`${import.meta.env.VITE_API_URL}/api/auth/logout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
      });
    } catch (error) {
      console.error('Logout failed:', error);
    } finally {
      localStorage.removeItem('officerToken');
      localStorage.removeItem('officerUser');
      window.location.href = '/officer/login';
    }
  };

  return (
    <HeaderContainer
      render={({ isSideNavExpanded, onClickSideNavExpand }) => (
        <>
          <Header aria-label="Registry Portal System">
            <HeaderMenuButton
              aria-label={isSideNavExpanded ? 'Close menu' : 'Open menu'}
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
          <main className="mt-12 min-h-screen p-4 sm:p-6 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64" style={{ backgroundColor: '#f4f4f4' }}>
            
            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Verified Records
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Search and review historically processed applications and official decisions.
              </p>
            </div>

            {/* Stat Cards for Historical Context */}
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

            {/* Data Table for Verified Records */}
            <DataTable rows={rows} headers={headers}>
              {({ rows: cRows, headers: cHeaders, getTableProps, getHeaderProps, getRowProps, onInputChange }) => (
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
                        {cHeaders.map((header) => (
                          <TableHeader {...getHeaderProps({ header })} key={header.key}>
                            {header.header}
                          </TableHeader>
                        ))}
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {cRows.map((row) => (
                        <TableRow {...getRowProps({ row })} key={row.id}>
                          {row.cells.map((cell) => {
                            if (cell.info.header === 'status') {
                              return (
                                <TableCell key={cell.id}>
                                  {cell.value === 'Approved' ? (
                                    <Tag type="green" title="Approved">Approved</Tag>
                                  ) : cell.value === 'Revised' ? (
                                    <Tag type="blue" title="Revised">Revised</Tag>
                                  ) : (
                                    <Tag type="red" title="Rejected">Rejected</Tag>
                                  )}
                                </TableCell>
                              );
                            }
                            if (cell.info.header === 'actions') {
                              return (
                                <TableCell key={cell.id} style={{ padding: '0.5rem', textAlign: 'right' }}>
                                  <Button 
                                    size="sm" 
                                    kind="ghost"
                                    onClick={() => {
                                      const fullRow = rows.find(r => r.id === row.id);
                                      if (fullRow) {
                                        setEditingRecord(fullRow);
                                        setEditStatus(fullRow.status);
                                        setEditComments(fullRow.comments || '');
                                      }
                                    }}
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

          {editingRecord && (
            <Modal
              open={!!editingRecord}
              modalHeading={`Edit Record: ${editingRecord.appId}`}
              primaryButtonText={isSaving ? 'Saving...' : 'Save Changes'}
              secondaryButtonText="Cancel"
              onRequestSubmit={handleSaveEdit}
              onRequestClose={() => setEditingRecord(null)}
              primaryButtonDisabled={isSaving}
            >
              <div style={{ marginBottom: '1rem' }}>
                <p><strong>Citizen Name:</strong> {editingRecord.citizen}</p>
                <p><strong>Service Type:</strong> {editingRecord.service}</p>
                <p><strong>Date Verified:</strong> {editingRecord.dateVerified}</p>
              </div>

              <FormGroup legendText="">
                <Select
                  id="status-select"
                  labelText="Status"
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value)}
                  style={{ marginBottom: '1rem' }}
                >
                  <SelectItem value="Approved" text="Approved" />
                  <SelectItem value="Rejected" text="Rejected" />
                  <SelectItem value="Revised" text="Revised" />
                </Select>

                <TextArea
                  labelText="Internal Comments (Optional)"
                  rows={4}
                  value={editComments}
                  onChange={(e) => setEditComments(e.target.value)}
                  placeholder="Add any internal notes..."
                />
              </FormGroup>
            </Modal>
          )}
        </>
      )}
    />
  );
}
