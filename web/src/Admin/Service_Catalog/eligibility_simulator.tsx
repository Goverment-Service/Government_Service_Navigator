import "@carbon/styles/css/styles.css";
import React, { useState, useEffect } from "react";
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
  Tag,
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
  CheckmarkFilled,
  WarningFilled,
} from "@carbon/icons-react";

interface Service {
  id: number;
  serviceId: string;
  name: string;
}

interface EvaluationResult {
  isEligible: boolean;
  matchPercentage: number;
  missingCriteria: string[];
}

export default function EligibilitySimulator() {
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(false);
  const [services, setServices] = useState<Service[]>([]);
  const [selectedServiceId, setSelectedServiceId] = useState<string>("");

  // Citizen profile test input state
  const [profile, setProfile] = useState({
    age: "20",
    citizenship: "Sri Lankan",
  });

  const [evaluationResult, setEvaluationResult] = useState<EvaluationResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isEvaluating, setIsEvaluating] = useState(false);
  const [notification, setNotification] = useState<{
    type: "success" | "error";
    title: string;
    subtitle: string;
  } | null>(null);

  // 1. Fetch services on mount to populate the procedure dropdown
   useEffect(() => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        const activeServices = data.filter((srv: any) => srv.status !== "Retired");
        setServices(activeServices);
        if (activeServices.length > 0) {
          setSelectedServiceId(activeServices[0].id.toString());
        }
        setIsLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
        setIsLoading(false);
      });
  }, []);


  // 2. Call POST /api/services/eligibility-score
  const handleEvaluate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedServiceId) return;

    setIsEvaluating(true);
    setEvaluationResult(null);

    const payload = {
      serviceId: parseInt(selectedServiceId),
      citizenProfile: {
        age: parseInt(profile.age) || 0,
        citizenship: profile.citizenship,
      },
    };

    try {
      const response = await fetch(
        "http://localhost:5119/api/services/eligibility-score",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );

      if (response.ok) {
        const result = await response.json();
        setEvaluationResult(result);
        setNotification({
          type: "success",
          title: "Evaluation Complete",
          subtitle: `Match calculated successfully at ${result.matchPercentage}%`,
        });
      } else {
        setNotification({
          type: "error",
          title: "Evaluation Failed",
          subtitle: "Could not evaluate citizen profile against service rules.",
        });
      }
    } catch (error) {
      console.error("Error evaluating eligibility score:", error);
      setNotification({
        type: "error",
        title: "Server Error",
        subtitle: "Could not connect to backend server.",
      });
    } finally {
      setIsEvaluating(false);
    }
  };

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
              id="search-simulator"
              labelText="Search"
              placeholder="Search records..."
            />
          </div>
          <HeaderGlobalAction aria-label="Notifications">
            <Notification size={20} />
          </HeaderGlobalAction>
        </HeaderGlobalBar>

        <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
          <SideNavItems>
            <SideNavLink renderIcon={Dashboard} href="/admin/dashboard">
              Overview
            </SideNavLink>
            <SideNavLink renderIcon={Catalog} href="/admin/services">
              Service Catalog
            </SideNavLink>
            <SideNavLink renderIcon={Rule} href="/admin/services/rules">
              Eligibility Rules
            </SideNavLink>
            <SideNavLink renderIcon={Categories} href="/admin/services/config">
              Service Configuration
            </SideNavLink>
            <SideNavLink
              renderIcon={Rule}
              href="/admin/services/simulator"
              isActive
            >
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
              <SideNavLink renderIcon={Logout} href="/officer/login">
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
            Eligibility Score Simulator
          </h1>
          <p style={{ color: "#525252", marginTop: "0.5rem" }}>
            Test citizen profiles against service prerequisites and business
            rules.
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

        <Grid style={{ width: "100%", paddingLeft: 0, paddingRight: 0 }}>
          {/* Form Column */}
          <Column sm={4} md={8} lg={8} style={{ paddingLeft: 0 }}>
            <Tile style={{ padding: "2rem", height: "100%", width: "100%" }}>
              <h3 style={{ marginBottom: "1.5rem", fontWeight: 500 }}>
                Test Profile Parameters
              </h3>

              {isLoading ? (
                <Loading
                  description="Loading services..."
                  withOverlay={false}
                />
              ) : (
                <form
                  onSubmit={handleEvaluate}
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    gap: "1.5rem",
                  }}
                >
                  <Select
                    id="simulator-service-select"
                    labelText="Target Service Procedure"
                    value={selectedServiceId}
                    onChange={(e) => setSelectedServiceId(e.target.value)}
                  >
                    {services.map((srv) => (
                      <SelectItem
                        key={srv.id}
                        value={srv.id.toString()}
                        text={`${srv.serviceId} - ${srv.name}`}
                      />
                    ))}
                  </Select>

                  <TextInput
                    id="citizen-age"
                    labelText="Citizen Age"
                    type="number"
                    value={profile.age}
                    onChange={(e) =>
                      setProfile({ ...profile, age: e.target.value })
                    }
                  />

                  <TextInput
                    id="citizen-citizenship"
                    labelText="Citizenship"
                    value={profile.citizenship}
                    onChange={(e) =>
                      setProfile({ ...profile, citizenship: e.target.value })
                    }
                  />

                  <Button
                    type="submit"
                    kind="primary"
                    style={{ marginTop: "1rem", width: "100%" }}
                  >
                    {isEvaluating
                      ? "Evaluating..."
                      : "Run Eligibility Simulation"}
                  </Button>
                </form>
              )}
            </Tile>
          </Column>

          {/* Results Column */}
          <Column sm={4} md={8} lg={8} style={{ paddingRight: 0 }}>
            <Tile
              style={{
                padding: "2rem",
                height: "100%",
                width: "100%",
                backgroundColor: "#ffffff",
              }}
            >
              <h3 style={{ marginBottom: "1.5rem", fontWeight: 500 }}>
                Evaluation Results
              </h3>

              {!evaluationResult ? (
                <div
                  style={{
                    color: "#6f6f6f",
                    padding: "3rem 0",
                    textAlign: "center",
                  }}
                >
                  <p>
                    Run a simulation to view match percentage and requirement
                    breakdown.
                  </p>
                </div>
              ) : (
                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    gap: "1.5rem",
                  }}
                >
                  <div
                    className="flex-wrap"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      gap: "0.75rem",
                      padding: "1rem",
                      backgroundColor: "#f4f4f4",
                      borderLeft: `4px solid ${evaluationResult.isEligible ? "#24a148" : "#da1e28"}`,
                    }}
                  >
                    <div>
                      <span
                        style={{
                          fontSize: "0.875rem",
                          color: "#525252",
                          display: "block",
                        }}
                      >
                        Overall Status
                      </span>
                      <span
                        style={{
                          fontSize: "1.25rem",
                          fontWeight: 600,
                          color: "#161616",
                        }}
                      >
                        {evaluationResult.isEligible
                          ? "Eligible for Service"
                          : "Not Eligible"}
                      </span>
                    </div>
                    <Tag type={evaluationResult.isEligible ? "green" : "red"}>
                      {evaluationResult.matchPercentage}% Match
                    </Tag>
                  </div>

                  <div>
                    <h4
                      style={{
                        fontSize: "1rem",
                        fontWeight: 500,
                        marginBottom: "0.75rem",
                      }}
                    >
                      Missing Criteria & Failed Rules:
                    </h4>
                    {evaluationResult.missingCriteria.length === 0 ? (
                      <p
                        style={{
                          color: "#24a148",
                          display: "flex",
                          alignItems: "center",
                          gap: "0.5rem",
                        }}
                      >
                        <CheckmarkFilled size={16} /> All prerequisites passed
                        successfully.
                      </p>
                    ) : (
                      <ul
                        style={{
                          listStyleType: "none",
                          padding: 0,
                          display: "flex",
                          flexDirection: "column",
                          gap: "0.5rem",
                        }}
                      >
                        {evaluationResult.missingCriteria.map(
                          (crit: string, idx: number) => (
                            <li
                              key={idx}
                              style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "0.5rem",
                                color: "#da1e28",
                                backgroundColor: "#fff1f1",
                                padding: "0.75rem",
                                fontSize: "0.875rem",
                              }}
                            >
                              <WarningFilled size={16} /> {crit}
                            </li>
                          ),
                        )}
                      </ul>
                    )}
                  </div>
                </div>
              )}
            </Tile>
          </Column>
        </Grid>
      </main>
    </>
  );
}
