import "@carbon/styles/css/styles.css";
import { useState, useEffect } from "react";
import CurrentUserBadge from "../../components/CurrentUserBadge";
import { getStoredUser, getAdminOverviewHref } from "../../utils/currentUser";
import { getCategoryForDepartment } from "../../constants/departments";
import {
  Header,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  HeaderMenuButton,
  SideNav,
  SideNavItems,
  SideNavLink,
  Search,
  Select,
  SelectItem,
  TextInput,
  Button,
  Tile,
  Grid,
  Column,
  Loading,
  InlineNotification,
} from "@carbon/react";
import {
  Dashboard,
  UserMultiple,
  Security,
  Settings,
  Logout,
  Notification,
  Catalog,
  Rule,
  Categories,
  TrashCan,
} from "@carbon/icons-react";

interface Service {
  id: number;
  serviceId: string;
  name: string;
  category?: string;
}

interface EligibilityRule {
  id: number;
  serviceProcedureId?: number;
  field: string;
  operator: string;
  value: string;
  isStrict?: boolean;
}

export default function EligibilityRuleBuilder() {
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(false);
  const [currentUser] = useState(getStoredUser);
  const [overviewHref] = useState(() => getAdminOverviewHref(currentUser));
  const isDepartmentAdmin = (currentUser?.role || "").toLowerCase().includes("admin") && !!currentUser?.department;
  const scopedCategory = currentUser?.department ? getCategoryForDepartment(currentUser.department) : null;
  const [services, setServices] = useState<Service[]>([]);
  const [selectedServiceId, setSelectedServiceId] = useState<string>("");
  const [rules, setRules] = useState<EligibilityRule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [notification, setNotification] = useState<{
    type: "success" | "error";
    title: string;
    subtitle: string;
  } | null>(null);

    useEffect(() => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        const activeServices = data.filter((srv: any) => srv.status === "Active");
        setServices(activeServices);
        const scopedServices = activeServices.filter(
          (srv: Service) => !isDepartmentAdmin || !scopedCategory || srv.category === scopedCategory
        );
        if (scopedServices.length > 0) {
          setSelectedServiceId(scopedServices[0].id.toString());
        }
        setIsLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
        setIsLoading(false);
      });
  }, []);


  useEffect(() => {
    if (!selectedServiceId) return;

    const loadRules = async () => {
      setIsLoading(true);
      try {
        const res = await fetch(`http://localhost:5119/api/services/${selectedServiceId}`);
        const data = await res.json();
        setRules(data.eligibilityRules || []);
      } catch (error) {
        console.error("Error fetching rules for service:", error);
      } finally {
        setIsLoading(false);
      }
    };

    loadRules();
  }, [selectedServiceId]);

  const handleRuleChange = (id: number, key: string, val: string) => {
    setRules(rules.map((r) => (r.id === id ? { ...r, [key]: val } : r)));
  };

  const handleAddRule = () => {
    const tempId = Date.now();
    setRules([
      ...rules,
      {
        id: tempId,
        serviceProcedureId: parseInt(selectedServiceId),
        field: "Age",
        operator: ">=",
        value: "",
        isStrict: true,
      },
    ]);
  };

  const handleDeleteRule = (id: number) => {
    setRules(rules.filter((r) => r.id !== id));
  };

  const handleSave = async () => {
    try {
      const payload = rules.map((r) => ({
        serviceProcedureId: r.serviceProcedureId,
        field: r.field,
        operator: r.operator,
        value: r.value,
        isStrict: r.isStrict,
      }));

      const response = await fetch(
        `http://localhost:5119/api/services/${selectedServiceId}/eligibility-rules`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );

      if (response.ok) {
        const updatedService = await response.json();
        setRules(updatedService.eligibilityRules || []);
        setNotification({
          type: "success",
          title: "Success",
          subtitle: "Ruleset saved and persisted successfully!",
        });
      } else {
        setNotification({
          type: "error",
          title: "Error",
          subtitle: "Failed to save ruleset to database.",
        });
      }
    } catch (error) {
      console.error("Error saving ruleset:", error);
      setNotification({
        type: "error",
        title: "Server Error",
        subtitle: "Could not connect to backend server.",
      });
    }
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
      window.location.href = "/officer/login";
    }
  };

  const visibleServices = services.filter(
    (srv) => !isDepartmentAdmin || !scopedCategory || srv.category === scopedCategory
  );

  const filteredRules = rules.filter(
    (r) =>
      r.field?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.operator?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.value?.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  return (
    <>
      <Header aria-label="Registry Admin System">
        <HeaderMenuButton
          aria-label={isSideNavExpanded ? "Close menu" : "Open menu"}
          onClick={() => setIsSideNavExpanded((prev) => !prev)}
          isActive={isSideNavExpanded}
          isCollapsible
        />
        <HeaderName href="#" prefix="GSN">
          Registry Admin
        </HeaderName>
        <HeaderGlobalBar>
          <div
            className="w-[120px] sm:w-[250px]"
            style={{
              marginRight: "1rem",
              display: "flex",
              alignItems: "center",
            }}
          >
            <Search
              size="sm"
              id="search-rules"
              labelText="Search"
              placeholder="Search rules..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onClear={() => setSearchQuery("")}
            />
          </div>
          <CurrentUserBadge />
          <HeaderGlobalAction aria-label="Notifications">
            <Notification size={20} />
          </HeaderGlobalAction>
        </HeaderGlobalBar>

        <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
          <SideNavItems>
            <SideNavLink renderIcon={Dashboard} href={overviewHref}>
              Overview
            </SideNavLink>
            <SideNavLink renderIcon={Catalog} href="/admin/services">
              Service Catalog
            </SideNavLink>
            <SideNavLink
              renderIcon={Rule}
              href="/admin/services/rules"
              isActive
            >
              Eligibility Rules
            </SideNavLink>
            <SideNavLink renderIcon={Categories} href="/admin/services/config">
              Service Configuration
            </SideNavLink>
            <SideNavLink renderIcon={Rule} href="/admin/services/simulator">
              Eligibility Simulator
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
            <SideNavLink renderIcon={Settings} href="/admin/system-settings">
              System Settings
            </SideNavLink>
            <div style={{ marginTop: "auto", borderTop: "1px solid #393939" }}>
              <SideNavLink renderIcon={Logout} onClick={handleLogout} style={{ cursor: 'pointer' }}>
                Sign Out
              </SideNavLink>
            </div>
          </SideNavItems>
        </SideNav>
      </Header>

      <main
        className="mt-12 min-h-screen p-4 min-[66rem]:p-8 ml-0 min-[66rem]:ml-64"
        style={{
          backgroundColor: "#f4f4f4",
        }}
      >
        <div style={{ marginBottom: "2rem" }}>
          <h1 style={{ fontSize: "2rem", fontWeight: 400, color: "#161616" }}>
            Eligibility Rule Builder
          </h1>
          <p style={{ color: "#525252", marginTop: "0.5rem" }}>
            Configure business logic and prerequisites for citizen eligibility.
          </p>
        </div>

        {notification && (
          <div style={{ marginBottom: "1.5rem", width: "100%" }}>
            <InlineNotification
              kind={notification.type}
              title={notification.title}
              subtitle={notification.subtitle}
              onClose={() => setNotification(null)}
            />
          </div>
        )}

        <Tile style={{ width: "100%", marginBottom: "1.5rem" }}>
          <Select
            id="target-service-select"
            labelText="Target Service Procedure"
            value={selectedServiceId}
            onChange={(e) => setSelectedServiceId(e.target.value)}
          >
            {visibleServices.map((srv) => (
              <SelectItem
                key={srv.id}
                value={srv.id.toString()}
                text={`${srv.serviceId} - ${srv.name}`}
              />
            ))}
          </Select>
        </Tile>

        <Tile style={{ width: "100%" }}>
          <h3 style={{ marginBottom: "1.5rem", fontWeight: 500 }}>
            Active Ruleset
          </h3>

          {isLoading ? (
            <Loading description="Loading rules..." withOverlay={false} />
          ) : filteredRules.length === 0 ? (
            <p style={{ color: "#6f6f6f", padding: "1rem 0" }}>
              No eligibility rules configured for this service yet.
            </p>
          ) : (
            filteredRules.map((rule) => (
              <Grid
                key={rule.id}
                style={{
                  marginBottom: "1rem",
                  alignItems: "flex-end",
                  paddingLeft: 0,
                  paddingRight: 0,
                }}
              >
                <Column sm={4} md={3} lg={4}>
                  <Select
                    id={`field-${rule.id}`}
                    labelText="Field"
                    value={rule.field}
                    onChange={(e) =>
                      handleRuleChange(rule.id, "field", e.target.value)
                    }
                  >
                    <SelectItem value="Age" text="Age" />
                    <SelectItem value="Citizenship" text="Citizenship" />
                    <SelectItem value="Income" text="Income" />
                  </Select>
                </Column>
                <Column sm={4} md={2} lg={3}>
                  <Select
                    id={`operator-${rule.id}`}
                    labelText="Operator"
                    value={rule.operator}
                    onChange={(e) =>
                      handleRuleChange(rule.id, "operator", e.target.value)
                    }
                  >
                    <SelectItem value=">=" text=">=" />
                    <SelectItem value="<=" text="<=" />
                    <SelectItem value="==" text="==" />
                    <SelectItem value="!=" text="!=" />
                  </Select>
                </Column>
                <Column sm={4} md={2} lg={4}>
                  <TextInput
                    id={`value-${rule.id}`}
                    labelText="Value"
                    value={rule.value}
                    onChange={(e) =>
                      handleRuleChange(rule.id, "value", e.target.value)
                    }
                  />
                </Column>
                <Column sm={4} md={1} lg={1} className="flex justify-end min-[66rem]:justify-start">
                  <Button
                    kind="danger--ghost"
                    renderIcon={TrashCan}
                    iconDescription="Remove"
                    hasIconOnly
                    onClick={() => handleDeleteRule(rule.id)}
                  />
                </Column>
              </Grid>
            ))
          )}

          <div
            className="flex flex-wrap"
            style={{
              gap: "1rem",
              marginTop: "2rem",
              borderTop: "1px solid #e0e0e0",
              paddingTop: "1.5rem",
            }}
          >
            <Button kind="secondary" onClick={handleAddRule}>
              + Add New Condition
            </Button>
            <Button kind="primary" onClick={handleSave}>
              Save Ruleset
            </Button>
          </div>
        </Tile>
      </main>
    </>
  );
}
