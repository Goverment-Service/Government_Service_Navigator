import '@carbon/styles/css/styles.css';
import React, { useState } from "react";
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  SideNav,
  SideNavItems,
  SideNavLink,
  TextInput,
  Select,
  SelectItem,
  Button,
  Stack,
  FormGroup,
  InlineNotification,
  Search
} from "@carbon/react";
import {
  Dashboard,
  Document,
  Time,
  User,
  Logout,
  Notification,
  Add
} from "@carbon/icons-react";

export default function ApplicationCreate() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    citizenName: "",
    nicNumber: "",
    serviceType: "Business Registration",
    priority: "Normal"
  });

  const handleLogout = () => {
    localStorage.removeItem("officerToken");
    localStorage.removeItem("officerUser");
    window.location.href = "/officer/login";
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setIsSubmitting(true);

    try {
      // TODO: Connect to your backend API here
      // Example: await fetch("http://localhost:5119/api/applications", { method: "POST", body: JSON.stringify(formData) })
      
      console.log("Submitting:", formData);
      
      // Simulating a network request delay
      setTimeout(() => {
        setIsSubmitting(false);
        // Redirect back to dashboard on success
        window.location.href = "/officer/dashboard";
      }, 1000);

    } catch (error) {
      setFormError("Failed to submit application. Please check your connection.");
      setIsSubmitting(false);
    }
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
                 <Search size="sm" id="search-queue-create" labelText="Search" placeholder="Search NIC or Application ID..." />
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
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create" isActive>
                  New Application
                </SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">
                  Verified Records
                </SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">
                  Pending Reviews
                </SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile">
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

          {/* Main Content Area */}
          <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
            
            <div style={{ marginBottom: '2.5rem', maxWidth: '800px' }}>
              <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>
                Submit New Citizen Application
              </h1>
              <p style={{ color: '#525252', marginTop: '0.5rem' }}>
                Provision a new service request directly into the registry queue. Ensure all citizen identification details match verified documents.
              </p>
            </div>

            {formError && (
              <InlineNotification
                kind="error"
                title="Submission Error"
                subtitle={formError}
                lowContrast
                style={{ marginBottom: '2rem', maxWidth: '800px' }}
              />
            )}

            <form onSubmit={handleSubmit} style={{ maxWidth: '600px', backgroundColor: '#fff', padding: '2rem', border: '1px solid #e0e0e0' }}>
              <Stack gap={7}>
                <FormGroup legendText="">
                  <TextInput
                    id="citizenName"
                    labelText="Citizen Full Name"
                    placeholder="e.g. Nimal Jayasinghe"
                    value={formData.citizenName}
                    onChange={(e) => setFormData({ ...formData, citizenName: e.target.value })}
                    disabled={isSubmitting}
                    required
                  />
                </FormGroup>

                <FormGroup legendText="">
                  <TextInput
                    id="nicNumber"
                    labelText="National Identity Card (NIC) Number"
                    placeholder="e.g. 199512345678"
                    value={formData.nicNumber}
                    onChange={(e) => setFormData({ ...formData, nicNumber: e.target.value })}
                    disabled={isSubmitting}
                    required
                  />
                </FormGroup>

                <FormGroup legendText="">
                  <Select
                    id="serviceType"
                    labelText="Requested Service Type"
                    value={formData.serviceType}
                    onChange={(e) => setFormData({ ...formData, serviceType: e.target.value })}
                    disabled={isSubmitting}
                  >
                    <SelectItem value="Business Registration" text="Business Registration" />
                    <SelectItem value="Residence Certificate" text="Residence Certificate" />
                    <SelectItem value="Character Verification" text="Character Verification" />
                    <SelectItem value="Land Deed Verification" text="Land Deed Verification" />
                  </Select>
                </FormGroup>

                <FormGroup legendText="">
                  <Select
                    id="priority"
                    labelText="Queue Priority Level"
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
                    disabled={isSubmitting}
                  >
                    <SelectItem value="Normal" text="Normal Priority" />
                    <SelectItem value="High" text="High Priority (Requires Justification)" />
                  </Select>
                </FormGroup>

                <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                  <Button 
                    type="submit" 
                    disabled={isSubmitting || !formData.citizenName || !formData.nicNumber}
                  >
                    {isSubmitting ? "Submitting..." : "Submit Application"}
                  </Button>
                  <Button 
                    kind="secondary" 
                    onClick={() => window.location.href = "/officer/dashboard"}
                    disabled={isSubmitting}
                  >
                    Cancel
                  </Button>
                </div>
              </Stack>
            </form>

          </main>
        </>
      )}
    />
  );
}