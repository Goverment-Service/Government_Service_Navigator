import "@carbon/styles/css/styles.css";
import { useState } from "react";
import { useParams, Navigate } from "react-router-dom";
import CurrentUserBadge from "../components/CurrentUserBadge";
import {
  Header,
  HeaderContainer,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  HeaderMenuButton,
  SideNav,
  SideNavItems,
  SideNavLink,
  Grid,
  Column,
  Tile,
  Tag,
  Search,
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings,
  Logout,
  Notification,
  Document,
  Activity,
  Catalog,
  Rule,
  Categories,
} from "@carbon/icons-react";
import { getDepartmentLabel } from "../constants/departments";
import { API_BASE } from "../lib/apiBase";

function getStoredOfficer(): { fullName?: string; department?: string } {
  const storedUser = localStorage.getItem("officerUser");
  if (storedUser) {
    try {
      return JSON.parse(storedUser);
    } catch {
      // ignore parse error
    }
  }
  return {};
}

export default function DepartmentAdminDashboard() {
  const { deptSlug } = useParams<{ deptSlug: string }>();
  const [officer] = useState(getStoredOfficer);

  const departmentName = (deptSlug && getDepartmentLabel(deptSlug)) || null;

  // Unknown department slug - send back to the generic dashboard instead of a broken page.
  if (!departmentName) {
    return <Navigate to="/admin/dashboard" replace />;
  }

  const officerName = officer.fullName || "Department Admin";

  const handleLogout = async () => {
    const token = localStorage.getItem("officerToken");
    try {
      await fetch(`${API_BASE}/auth/logout`, {
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
          <Header aria-label={`${departmentName} Admin System`}>
            <HeaderMenuButton
              aria-label={isSideNavExpanded ? "Close menu" : "Open menu"}
              onClick={onClickSideNavExpand}
              isActive={isSideNavExpanded}
              isCollapsible
            />
            <HeaderName href="#" prefix="GSN">
              {departmentName} Admin
            </HeaderName>

            <HeaderGlobalBar>
              <div className="flex items-center w-[120px] sm:w-[250px] mr-2 sm:mr-4">
                <Search
                  size="sm"
                  id="search-records"
                  labelText="Search"
                  placeholder="Search records..."
                />
              </div>
              <CurrentUserBadge />
              <HeaderGlobalAction aria-label="Notifications" onClick={() => {}}>
                <Notification size={20} />
              </HeaderGlobalAction>
            </HeaderGlobalBar>

            <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
              <SideNavItems>
                <SideNavLink renderIcon={Dashboard} href="#" isActive>
                  Overview
                </SideNavLink>

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
                  renderIcon={UserMultiple}
                  href="/admin/manage-officers"
                >
                  Manage Officers
                </SideNavLink>
                <SideNavLink renderIcon={Security} href="/admin/audit-logs">
                  Audit Logs
                </SideNavLink>
                <SideNavLink
                  renderIcon={Settings}
                  href="/admin/system-settings"
                >
                  System Settings
                </SideNavLink>

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

          <main
            className="mt-12 min-h-screen p-4 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64"
            style={{ backgroundColor: "#f4f4f4" }}
          >
            <div style={{ marginBottom: "2rem" }}>
              <Tag type="blue" style={{ marginBottom: "0.5rem" }}>
                {departmentName}
              </Tag>
              <h1
                style={{ fontSize: "2rem", fontWeight: 400, color: "#161616" }}
              >
                Welcome back, {officerName}
              </h1>
              <p style={{ color: "#525252", marginTop: "0.5rem" }}>
                Monitor activity and manage officers within the {departmentName}.
              </p>
            </div>

            <Grid
              style={{ paddingLeft: 0, paddingRight: 0, marginBottom: "2rem" }}
            >
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      marginBottom: "1rem",
                    }}
                  >
                    <p style={{ color: "#525252", fontSize: "0.875rem" }}>
                      Department Applications
                    </p>
                    <Document size={20} />
                  </div>
                  <h3
                    style={{
                      fontSize: "2.5rem",
                      fontWeight: 300,
                      margin: "0.5rem 0",
                    }}
                  >
                    —
                  </h3>
                  <p
                    style={{
                      color: "#525252",
                      fontSize: "0.875rem",
                      marginTop: "1rem",
                    }}
                  >
                    Total applications routed here
                  </p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile>
                  <div
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      marginBottom: "1rem",
                    }}
                  >
                    <p style={{ color: "#525252", fontSize: "0.875rem" }}>
                      Department Officers
                    </p>
                    <UserMultiple size={20} />
                  </div>
                  <h3
                    style={{
                      fontSize: "2.5rem",
                      fontWeight: 300,
                      margin: "0.5rem 0",
                    }}
                  >
                    —
                  </h3>
                  <p
                    style={{
                      color: "#525252",
                      fontSize: "0.875rem",
                      marginTop: "1rem",
                    }}
                  >
                    Verifying officers in this department
                  </p>
                </Tile>
              </Column>
              <Column sm={4} md={4} lg={4}>
                <Tile style={{ borderTop: "4px solid #da1e28" }}>
                  <div
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      marginBottom: "1rem",
                    }}
                  >
                    <p style={{ color: "#525252", fontSize: "0.875rem" }}>
                      Pending Reviews
                    </p>
                    <Activity size={20} color="#da1e28" />
                  </div>
                  <h3
                    style={{
                      fontSize: "2.5rem",
                      fontWeight: 300,
                      margin: "0.5rem 0",
                    }}
                  >
                    —
                  </h3>
                  <p
                    style={{
                      color: "#da1e28",
                      fontSize: "0.875rem",
                      marginTop: "1rem",
                    }}
                  >
                    Awaiting department review
                  </p>
                </Tile>
              </Column>
            </Grid>
          </main>
        </>
      )}
    />
  );
}
