import '@carbon/styles/css/styles.css';
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  SideNav,
  SideNavItems,
  SideNavLink,
  Search
} from "@carbon/react";
import { Dashboard, Document, Time, User, Logout, Notification, Add, Catalog } from "@carbon/icons-react";

import TemplateBuilder from "./TemplateBuilder";

export default function ApplicationCreate() {
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
                 <Search size="sm" id="search-queue-create" labelText="Search" placeholder="Search..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/officer/dashboard">Application Queue</SideNavLink>
                <SideNavLink renderIcon={Catalog} href="/officer/applications">All Applications</SideNavLink>
                <SideNavLink renderIcon={Add} href="/officer/Application_create/application_create" isActive>Create Template</SideNavLink>
                <SideNavLink renderIcon={Document} href="/officer/verified-records">Verified Records</SideNavLink>
                <SideNavLink renderIcon={Time} href="/officer/pending-reviews">Pending Reviews</SideNavLink>
                <SideNavLink renderIcon={User} href="/officer/profile">My Profile</SideNavLink>
                <div style={{ marginTop: 'auto', borderTop: '1px solid #393939' }}>
                  <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>Sign Out</SideNavLink>
                </div>
              </SideNavItems>
            </SideNav>
          </Header>

          <TemplateBuilder />
        </>
      )}
    />
  );
}