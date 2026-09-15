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
  Search,
  HeaderMenuButton
} from "@carbon/react";
import { Dashboard, Document, Time, User, Logout, Notification, Add, Catalog ,
  CheckmarkOutline,
  DataStructured
} from '@carbon/icons-react';

import TemplateBuilder from "./TemplateBuilder";

export default function ApplicationCreate() {
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
      window.location.href = "/officer/login";
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
            <HeaderName href="#" prefix="GSN">Registry Portal</HeaderName>
            <HeaderGlobalBar>
              <div className="gsn-header-search">
                 <Search size="sm" id="search-queue-create" labelText="Search" placeholder="Search..." />
              </div>
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="/officer/dashboard">Application Queue</SideNavLink>
                                <SideNavLink renderIcon={CheckmarkOutline} href="/officer/bulk-verification">
                  Bulk Verification
                </SideNavLink>
                <SideNavLink renderIcon={DataStructured} href="/officer/rejection-codes">
                  Rejection Codes
                </SideNavLink>
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

