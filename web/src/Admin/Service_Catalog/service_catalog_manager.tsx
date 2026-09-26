import "@carbon/styles/css/styles.css";
import { useState, useEffect } from "react";
import CurrentUserBadge from "../../components/CurrentUserBadge";
import { getAdminOverviewHref } from "../../utils/currentUser";
import {
  Header,
  HeaderName,
  HeaderMenuButton,
  HeaderGlobalBar,
  HeaderGlobalAction,
  SideNav,
  SideNavItems,
  SideNavLink,
  Search,
  DataTable,
  TableContainer,
  Table,
  TableHead,
  TableRow,
  TableHeader,
  TableBody,
  TableCell,
  Tag,
  Button,
  Loading,
  Modal,
  TextInput,
  Select,
  SelectItem,
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
  Edit,
} from "@carbon/icons-react";
import { DEPARTMENTS, getCategoryForDepartment } from "../../constants/departments";

const headers = [
  { key: "serviceId", header: "Service ID" },
  { key: "name", header: "Procedure Name" },
  { key: "category", header: "Category" },
  { key: "workflow", header: "Workflow & Stages" },
  { key: "status", header: "Status" },
  { key: "actions", header: "Actions" },
];

interface ServiceRecord {
  id: string;
  serviceId: string;
  name: string;
  category: string;
  status: string;
  totalStages?: number;
  workflowDepartments?: string[] | string;
  workflow?: string;
}

function getStoredOfficerUser(): { department?: string; role?: string } {
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

export default function ServiceCatalogManager() {
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(false);
  const [services, setServices] = useState<ServiceRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  // Department Admins only manage the service category that belongs to their own department.
  const [currentUser] = useState(getStoredOfficerUser);
  const isDepartmentAdmin = (currentUser.role || "").toLowerCase().includes("admin") && !!currentUser.department;
  const scopedCategory = currentUser.department ? getCategoryForDepartment(currentUser.department) : null;
  const overviewHref = getAdminOverviewHref(currentUser);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentServiceId, setCurrentServiceId] = useState<string | null>(null);
  const [formData, setFormData] = useState<{
    serviceId: string;
    name: string;
    category: string;
    status: string;
    totalStages: number;
    workflowDepartments: string[];
  }>({
    serviceId: "",
    name: "",
    category: isDepartmentAdmin && scopedCategory ? scopedCategory : "Commerce",
    status: "Draft",
    totalStages: 1,
    workflowDepartments: [currentUser.department || "Civil Department"],
  });

  const fetchServices = () => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        const formattedData = data.map(
          (item: Omit<ServiceRecord, "id"> & { id: number; totalStages?: number; workflowDepartments?: string[] | string }) => {
            let depts: string[] = [];
            if (Array.isArray(item.workflowDepartments)) {
              depts = item.workflowDepartments;
            } else if (typeof item.workflowDepartments === "string") {
              try {
                depts = JSON.parse(item.workflowDepartments);
              } catch (_) {}
            }
            const stages = item.totalStages && item.totalStages > 0 ? item.totalStages : 1;
            return {
              ...item,
              id: item.id.toString(),
              totalStages: stages,
              workflowDepartments: depts,
              workflow: `${stages} Stage${stages > 1 ? "s" : ""}`,
            };
          },
        );
        setServices(formattedData);
        setIsLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
        setIsLoading(false);
      });
  };

  useEffect(() => {
    fetchServices();
  }, []);

  const generateNextServiceId = () => {
    const maxNumber = services.reduce((max, service) => {
      const match = service.serviceId?.match(/GSN-SRV-(\d+)$/i);
      const num = match ? parseInt(match[1], 10) : 0;
      return num > max ? num : max;
    }, 0);
    const nextNumber = maxNumber + 1;
    return `GSN-SRV-${String(nextNumber).padStart(3, "0")}`;
  };

  const openCreateModal = () => {
    setIsEditMode(false);
    setCurrentServiceId(null);
    const defaultDept = currentUser.department || "Civil Department";
    setFormData({
      serviceId: generateNextServiceId(),
      name: "",
      category: isDepartmentAdmin && scopedCategory ? scopedCategory : "Commerce",
      status: "Draft",
      totalStages: 1,
      workflowDepartments: [defaultDept],
    });
    setIsModalOpen(true);
  };

  const openEditModal = (service: ServiceRecord) => {
    setIsEditMode(true);
    setCurrentServiceId(service.id);
    let parsedDepts: string[] = [];
    if (Array.isArray(service.workflowDepartments)) {
      parsedDepts = service.workflowDepartments;
    } else if (typeof service.workflowDepartments === "string") {
      try {
        parsedDepts = JSON.parse(service.workflowDepartments);
      } catch (_) {}
    }
    const stages = service.totalStages && service.totalStages > 0 ? service.totalStages : 1;
    if (parsedDepts.length === 0) {
      parsedDepts = [currentUser.department || "Civil Department"];
    }
    while (parsedDepts.length < stages) {
      parsedDepts.push("Civil Department");
    }

    setFormData({
      serviceId: service.serviceId,
      name: service.name,
      category: service.category,
      status: service.status,
      totalStages: stages,
      workflowDepartments: parsedDepts.slice(0, stages),
    });
    setIsModalOpen(true);
  };

  const handleSaveService = async () => {
    try {
      const method = isEditMode ? "PUT" : "POST";
      const endpoint = isEditMode
        ? `http://localhost:5119/api/services/${currentServiceId}`
        : "http://localhost:5119/api/services";

      const response = await fetch(endpoint, {
        method: method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...(isEditMode ? { id: parseInt(currentServiceId!) } : {}),
          ...formData,
          eligibilityRules: [],
          documentRequirements: [],
          feeSchedules: [],
        }),
      });

      if (response.ok) {
        fetchServices();
        setIsModalOpen(false);
      } else {
        console.error("Failed to save service");
      }
    } catch (error) {
      console.error("Error saving service:", error);
    }
  };

  const handleDeleteService = async (id: string) => {
    if (
      !window.confirm("Are you sure you want to delete this service procedure?")
    ) {
      return;
    }

    try {
      const response = await fetch(`http://localhost:5119/api/services/${id}`, {
        method: "DELETE",
      });

      if (response.ok) {
        // Immediately update local state to filter out the retired/deleted service
        setServices((prev) => prev.filter((s) => s.id !== id));
      } else {
        console.error("Failed to delete service");
      }
    } catch (error) {
      console.error("Error deleting service:", error);
    }
  };

  // Filter out retired services so they don't clutter the active catalog view, plus apply search query
  const filteredServices = services
    .filter((service) => service.status !== "Retired")
    .filter((service) => !isDepartmentAdmin || !scopedCategory || service.category === scopedCategory)
    .filter(
      (service) =>
        service.serviceId?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        service.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        service.category?.toLowerCase().includes(searchQuery.toLowerCase()),
    );

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
            className="w-[120px] sm:w-[200px] lg:w-[250px]"
            style={{
              marginRight: "1rem",
              display: "flex",
              alignItems: "center",
            }}
          >
            <Search
              size="sm"
              id="search-services"
              labelText="Search"
              placeholder="Search records..."
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

        <SideNav
          aria-label="Side navigation"
          expanded={isSideNavExpanded}
          onOverlayClick={() => setIsSideNavExpanded(false)}
        >
          <SideNavItems>
            <SideNavLink renderIcon={Dashboard} href={overviewHref}>
              Overview
            </SideNavLink>
            <SideNavLink renderIcon={Catalog} href="/admin/services" isActive>
              Service Catalog
            </SideNavLink>
            <SideNavLink renderIcon={Rule} href="/admin/services/rules">
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
        <div
          className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
          style={{
            marginBottom: "2rem",
          }}
        >
          <div>
            {isDepartmentAdmin && (
              <Tag type="blue" style={{ marginBottom: "0.5rem" }}>
                {currentUser.department}
              </Tag>
            )}
            <h1 style={{ fontSize: "2rem", fontWeight: 400, color: "#161616" }}>
              Service Catalog
            </h1>
            <p style={{ color: "#525252", marginTop: "0.5rem" }}>
              {isDepartmentAdmin
                ? `Manage procedures and services for the ${currentUser.department}.`
                : "Manage departmental procedures and maintain available registry services."}
            </p>
          </div>
          <Button size="md" onClick={openCreateModal}>
            + New Service
          </Button>
        </div>

        <Modal
          open={isModalOpen}
          modalHeading={isEditMode ? "Edit Service" : "Create New Service"}
          primaryButtonText={isEditMode ? "Save Changes" : "Create"}
          secondaryButtonText="Cancel"
          onRequestClose={() => setIsModalOpen(false)}
          onRequestSubmit={handleSaveService}
        >
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "1rem",
              paddingTop: "1rem",
            }}
          >
            <TextInput
              id="serviceId"
              labelText="Service ID"
              helperText="Auto-generated based on existing services."
              value={formData.serviceId}
              readOnly
            />
            <TextInput
              id="name"
              labelText="Procedure Name"
              placeholder="e.g., Vehicle Registration"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
            <Select
              id="category"
              labelText="Category"
              helperText={isDepartmentAdmin ? "Locked to your department's category." : undefined}
              value={formData.category}
              onChange={(e) =>
                setFormData({ ...formData, category: e.target.value })
              }
              disabled={isDepartmentAdmin}
            >
              {DEPARTMENTS.map((dept) => (
                <SelectItem key={dept.category} value={dept.category} text={dept.category} />
              ))}
            </Select>
            <Select
              id="status"
              labelText="Status"
              value={formData.status}
              onChange={(e) =>
                setFormData({ ...formData, status: e.target.value })
              }
            >
              <SelectItem value="Draft" text="Draft" />
              <SelectItem value="Active" text="Active" />
              <SelectItem value="Retired" text="Retired" />
            </Select>
          </div>
        </Modal>

        {isLoading ? (
          <Loading description="Loading services" withOverlay={false} />
        ) : (
          <DataTable rows={filteredServices} headers={headers}>
            {({
              rows,
              headers,
              getTableProps,
              getHeaderProps,
              getRowProps,
            }) => (
              <TableContainer
                title="Active Services"
                description="Procedures available for citizen submissions."
              >
                <Table {...getTableProps()}>
                  <TableHead>
                    <TableRow>
                      {headers.map((header) => (
                        <TableHeader
                          {...getHeaderProps({ header })}
                          key={header.key}
                        >
                          {header.header}
                        </TableHeader>
                      ))}
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {rows.length === 0 ? (
                      <TableRow>
                        <TableCell
                          colSpan={headers.length}
                          style={{ textAlign: "center", padding: "2rem" }}
                        >
                          No matching services found.
                        </TableCell>
                      </TableRow>
                    ) : (
                      rows.map((row) => (
                        <TableRow {...getRowProps({ row })} key={row.id}>
                          {row.cells.map((cell) => {
                            if (cell.info.header === "status") {
                              return (
                                <TableCell key={cell.id}>
                                  <Tag
                                    type={
                                      cell.value === "Active"
                                        ? "green"
                                        : cell.value === "Draft"
                                          ? "blue"
                                          : "gray"
                                    }
                                  >
                                    {cell.value}
                                  </Tag>
                                </TableCell>
                              );
                            }
                            if (cell.info.header === "actions") {
                              return (
                                <TableCell key={cell.id}>
                                  <div
                                    style={{
                                      display: "flex",
                                      gap: "0.5rem",
                                      alignItems: "center",
                                    }}
                                  >
                                    <Button
                                      size="sm"
                                      kind="tertiary"
                                      renderIcon={Edit}
                                      iconDescription="Edit"
                                      hasIconOnly
                                      onClick={() => {
                                        const serviceToEdit = services.find(
                                          (s) => s.id === row.id,
                                        );
                                        if (serviceToEdit)
                                          openEditModal(serviceToEdit);
                                      }}
                                    />
                                    <Button
                                      size="sm"
                                      kind="danger--ghost"
                                      renderIcon={TrashCan}
                                      iconDescription="Delete"
                                      hasIconOnly
                                      onClick={() =>
                                        handleDeleteService(row.id)
                                      }
                                    />
                                  </div>
                                </TableCell>
                              );
                            }
                            return (
                              <TableCell key={cell.id}>{cell.value}</TableCell>
                            );
                          })}
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </DataTable>
        )}
      </main>
    </>
  );
}
