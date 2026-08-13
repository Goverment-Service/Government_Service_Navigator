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
  TextInput,
  Button,
  Toggle,
  Select,
  SelectItem,
  FormGroup,
  Search
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings as SettingsIcon,
  Logout,
  Notification,
  UserAvatar
} from "@carbon/icons-react";
import { useNavigate } from "react-router-dom";

export default function Settings() {
  const navigate = useNavigate();
  const [userName, setUserName] = useState("System User");
  const [userEmail, setUserEmail] = useState("user@gov.lk");
  const [userRole, setUserRole] = useState("User");

  useEffect(() => {
    const storedUser = localStorage.getItem("officerUser");
    if (storedUser) {
      try {
        const parsedUser = JSON.parse(storedUser);
        if (parsedUser.fullName) setUserName(parsedUser.fullName);
        if (parsedUser.email) setUserEmail(parsedUser.email);
        if (parsedUser.role) setUserRole(parsedUser.role);
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

  const isSystemAdmin = userRole === "SystemAdmin" || userName === "System Admin";

  return (
    <HeaderContainer
      render={({ isSideNavExpanded }) => (
        <>
          <Header aria-label="Registry System">
            <HeaderName href="#" prefix="GSN">
              {isSystemAdmin ? "Registry Admin" : "Officer Portal"}
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
                <SideNavLink 
                  renderIcon={Dashboard} 
                  href={isSystemAdmin ? "/admin/dashboard" : "/officer/dashboard"}
                >
                  Overview
                </SideNavLink>
                {isSystemAdmin && (
                  <SideNavLink renderIcon={UserMultiple} href="/admin/manage-officers">
                    Manage Officers
                  </SideNavLink>
                )}
                {isSystemAdmin && (
                  <SideNavLink renderIcon={Security} href="#">
                    Audit Logs
                  </SideNavLink>
                )}
                <SideNavLink renderIcon={SettingsIcon} href="/settings" isActive>
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
            
            <div style={{ marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Settings & Profile
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Manage your personal details, security credentials, and application preferences.
              </p>
            </div>

            <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
              {/* Left Column - Profile & Security */}
              <Column sm={4} md={4} lg={8}>
                <Tile style={{ marginBottom: '2rem', padding: '2rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', marginBottom: '2rem' }}>
                    <div style={{ width: '64px', height: '64px', borderRadius: '50%', backgroundColor: '#e0e0e0', display: 'flex', justifyContent: 'center', alignItems: 'center', marginRight: '1rem' }}>
                      <UserAvatar size={32} color="#525252" />
                    </div>
                    <div>
                      <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Profile Information</h2>
                      <p style={{ color: '#525252', fontSize: '0.875rem' }}>Update your personal details here.</p>
                    </div>
                  </div>

                  <FormGroup legendText="">
                    <Grid style={{ paddingLeft: 0, paddingRight: 0 }}>
                      <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                        <TextInput
                          id="fullName"
                          labelText="Full Name"
                          value={userName}
                          onChange={(e) => setUserName(e.target.value)}
                        />
                      </Column>
                      <Column sm={4} md={4} lg={8} style={{ marginBottom: '1rem' }}>
                        <TextInput
                          id="emailAddress"
                          labelText="Email Address"
                          value={userEmail}
                          onChange={(e) => setUserEmail(e.target.value)}
                          readOnly
                          helperText="Contact system admin to change your official email."
                        />
                      </Column>
                    </Grid>
                    <Button style={{ marginTop: '1rem' }}>Save Changes</Button>
                  </FormGroup>
                </Tile>

                <Tile style={{ padding: '2rem' }}>
                  <div style={{ marginBottom: '2rem' }}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Security</h2>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Update your password and secure your account.</p>
                  </div>
                  <FormGroup legendText="">
                    <div style={{ marginBottom: '1rem', maxWidth: '400px' }}>
                      <TextInput
                        type="password"
                        id="currentPassword"
                        labelText="Current Password"
                        placeholder="••••••••"
                      />
                    </div>
                    <div style={{ marginBottom: '1rem', maxWidth: '400px' }}>
                      <TextInput
                        type="password"
                        id="newPassword"
                        labelText="New Password"
                        placeholder="••••••••"
                      />
                    </div>
                    <div style={{ marginBottom: '1rem', maxWidth: '400px' }}>
                      <TextInput
                        type="password"
                        id="confirmPassword"
                        labelText="Confirm New Password"
                        placeholder="••••••••"
                      />
                    </div>
                    <Button kind="secondary" style={{ marginTop: '1rem' }}>Update Password</Button>
                  </FormGroup>
                </Tile>
              </Column>

              {/* Right Column - Preferences */}
              <Column sm={4} md={4} lg={8}>
                <Tile style={{ padding: '2rem', height: '100%' }}>
                  <div style={{ marginBottom: '2rem' }}>
                    <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>System Preferences</h2>
                    <p style={{ color: '#525252', fontSize: '0.875rem' }}>Customize your notification and display settings.</p>
                  </div>

                  <div style={{ marginBottom: '2rem' }}>
                    <h3 style={{ fontSize: '1rem', fontWeight: 500, marginBottom: '1rem' }}>Notifications</h3>
                    <div style={{ marginBottom: '1rem' }}>
                      <Toggle
                        id="email-notifications"
                        labelText="Email Notifications"
                        defaultToggled
                        labelA="Off"
                        labelB="On"
                      />
                      <p style={{ color: '#525252', fontSize: '0.75rem', marginTop: '0.25rem' }}>Receive daily summary reports.</p>
                    </div>
                    <div style={{ marginBottom: '1rem' }}>
                      <Toggle
                        id="sms-alerts"
                        labelText="Critical Alerts (SMS)"
                        defaultToggled
                        labelA="Off"
                        labelB="On"
                      />
                      <p style={{ color: '#525252', fontSize: '0.75rem', marginTop: '0.25rem' }}>Get notified immediately on security events.</p>
                    </div>
                  </div>

                  <div style={{ marginBottom: '2rem' }}>
                    <h3 style={{ fontSize: '1rem', fontWeight: 500, marginBottom: '1rem' }}>Appearance</h3>
                    <Select
                      id="theme-select"
                      defaultValue="light"
                      labelText="Theme"
                      helperText="Choose how the dashboard looks to you."
                    >
                      <SelectItem value="light" text="Light Mode" />
                      <SelectItem value="dark" text="Dark Mode" />
                      <SelectItem value="system" text="System Default" />
                    </Select>
                  </div>
                  
                  <div style={{ marginBottom: '2rem' }}>
                    <h3 style={{ fontSize: '1rem', fontWeight: 500, marginBottom: '1rem' }}>Language</h3>
                    <Select
                      id="language-select"
                      defaultValue="en"
                      labelText="Display Language"
                    >
                      <SelectItem value="en" text="English" />
                      <SelectItem value="si" text="Sinhala" />
                      <SelectItem value="ta" text="Tamil" />
                    </Select>
                  </div>
                  
                  <Button kind="tertiary">Save Preferences</Button>
                </Tile>
              </Column>
            </Grid>
          </main>
        </>
      )}
    />
  );
}
