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
  FormGroup,
  Toggle,
  NumberInput,
  Select,
  SelectItem,
  Button,
  Stack,
  Search
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings,
  Logout,
  Notification,
  Save
} from "@carbon/icons-react";

export default function SystemSettings() {
  const [adminName, setAdminName] = useState("System Admin");
  const [isSaving, setIsSaving] = useState(false);

  // Example Setting States
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [enforce2FA, setEnforce2FA] = useState(true);

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

  const handleSaveSettings = () => {
    setIsSaving(true);
    // Simulate API save delay
    setTimeout(() => {
      setIsSaving(false);
      alert("System settings successfully updated.");
    }, 1000);
  };

  return (
    <HeaderContainer
      render={({ isSideNavExpanded, onClickSideNavExpand }) => (
        <>
          <Header aria-label="Registry Admin System">
            <HeaderName href="#" prefix="GSN">
              Registry Admin
            </HeaderName>
            
            <HeaderGlobalBar>
              <div style={{ width: '250px', marginRight: '1rem', display: 'flex', alignItems: 'center' }}>
                 <Search size="sm" id="search-settings" labelText="Search" placeholder="Search settings..." />
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
                <SideNavLink renderIcon={UserMultiple} href="/admin/manage-officers">
                  Manage Officers
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="/admin/audit-logs">
                  Audit Logs
                </SideNavLink>
                {/* Active state moved to System Settings */}
                <SideNavLink renderIcon={Settings} href="/admin/settings" isActive>
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

          {/* Main Content */}
          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            
            <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
              <div>
                <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                  System Settings
                </h1>
                <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                  Configure global registry parameters, security policies, and maintenance windows.
                </p>
              </div>
              <Button 
                renderIcon={Save} 
                onClick={handleSaveSettings}
                disabled={isSaving}
              >
                {isSaving ? "Saving..." : "Save Changes"}
              </Button>
            </div>

            <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
              {/* Security Policies */}
              <Column sm={4} md={8} lg={8} style={{ marginBottom: '1.5rem' }}>
                <Tile>
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem', fontWeight: 400 }}>Security & Access</h3>
                  <Stack gap={6}>
                    <Toggle 
                      id="enforce-2fa" 
                      labelText="Two-Factor Authentication (2FA)"
                      labelA="Optional"
                      labelB="Enforced"
                      toggled={enforce2FA}
                      onToggle={(checked) => setEnforce2FA(checked)}
                    />
                    
                    <FormGroup legendText="">
                      <NumberInput
                        id="session-timeout"
                        label="Idle Session Timeout (Minutes)"
                        min={5}
                        max={120}
                        value={30}
                        helperText="Officers will be automatically logged out after this period of inactivity."
                        invalidText="Must be between 5 and 120 minutes."
                      />
                    </FormGroup>

                    <FormGroup legendText="">
                      <NumberInput
                        id="max-login-attempts"
                        label="Maximum Failed Login Attempts"
                        min={3}
                        max={10}
                        value={5}
                        helperText="Account locks automatically after reaching this threshold."
                      />
                    </FormGroup>
                  </Stack>
                </Tile>
              </Column>

              {/* Maintenance & Core Systems */}
              <Column sm={4} md={8} lg={8} style={{ marginBottom: '1.5rem' }}>
                <Tile>
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem', fontWeight: 400 }}>Core Infrastructure</h3>
                  <Stack gap={6}>
                    <Toggle 
                      id="maintenance-mode" 
                      labelText="System Maintenance Mode"
                      labelA="Off"
                      labelB="On"
                      toggled={maintenanceMode}
                      onToggle={(checked) => setMaintenanceMode(checked)}
                    />
                    <p style={{ fontSize: '12px', color: '#da1e28', marginTop: '-1rem', marginBottom: '1rem' }}>
                      Warning: Turning this on will lock out all Verifying Officers and Citizens. Only System Admins will have access.
                    </p>

                    <FormGroup legendText="">
                      <Select
                        id="backup-frequency"
                        defaultValue="daily"
                        labelText="Database Backup Frequency"
                        helperText="Determines how often the automated system state is snapshotted."
                      >
                        <SelectItem value="hourly" text="Hourly" />
                        <SelectItem value="daily" text="Daily (Midnight)" />
                        <SelectItem value="weekly" text="Weekly (Sunday)" />
                      </Select>
                    </FormGroup>
                    
                    <FormGroup legendText="">
                      <Select
                        id="log-retention"
                        defaultValue="90"
                        labelText="Audit Log Retention Period"
                      >
                        <SelectItem value="30" text="30 Days" />
                        <SelectItem value="90" text="90 Days" />
                        <SelectItem value="365" text="1 Year" />
                        <SelectItem value="indefinite" text="Indefinite" />
                      </Select>
                    </FormGroup>
                  </Stack>
                </Tile>
              </Column>
            </Grid>

          </main>
        </>
      )}
    />
  );
}