import "@carbon/styles/css/styles.css";
import { useState, useEffect } from "react";
import {
  Header,
  HeaderName,
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
} from "@carbon/icons-react";

const headers = [
  { key: "serviceId", header: "Service ID" },
  { key: "name", header: "Procedure Name" },
  { key: "category", header: "Category" },
  { key: "status", header: "Status" },
  { key: "actions", header: "Actions" },
];

interface ServiceRecord {
  id: string;
  serviceId: string;
  name: string;
  category: string;
  status: string;
}

export default function ServiceCatalogManager() {
  const [isSideNavExpanded] = useState(true);
  const [services, setServices] = useState<ServiceRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentServiceId, setCurrentServiceId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    serviceId: "",
    name: "",
    category: "Commerce",
    status: "Draft",
  });

  const fetchServices = () => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        const formattedData = data.map((item: Omit<ServiceRecord, "id"> & { id: number }) => ({
          ...item,
          id: item.id.toString(),
        }));
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

  const openCreateModal = () => {
    setIsEditMode(false);
    setCurrentServiceId(null);
    setFormData({
      serviceId: "",
      name: "",
      category: "Commerce",
      status: "Draft",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (service: ServiceRecord) => {
    setIsEditMode(true);
    setCurrentServiceId(service.id);
    setFormData({
      serviceId: service.serviceId,
      name: service.name,
      category: service.category,
      status: service.status,
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

  const filteredServices = services.filter(
    (service) =>
      service.serviceId?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      service.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      service.category?.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  return (
    <>
      <Header aria-label="Registry Admin System">
        <HeaderName href="#" prefix="GSN">
          Registry Admin
        </HeaderName>
        <HeaderGlobalBar>
          <div
            style={{
              width: "250px",
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
          <HeaderGlobalAction aria-label="Notifications">
            <Notification size={20} />
          </HeaderGlobalAction>
        </HeaderGlobalBar>

        <SideNav aria-label="Side navigation" expanded={isSideNavExpanded}>
          <SideNavItems>
            <SideNavLink renderIcon={Dashboard} href="/admin/dashboard">
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
              <SideNavLink renderIcon={Logout} href="/officer/login">
                Sign Out
              </SideNavLink>
            </div>
          </SideNavItems>
        </SideNav>
      </Header>

      <main
        style={{
          marginTop: "3rem",
          padding: "2rem",
          marginLeft: "16rem",
          backgroundColor: "#f4f4f4",
          minHeight: "100vh",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "flex-start",
            marginBottom: "2rem",
          }}
        >
          <div>
            <h1 style={{ fontSize: "2rem", fontWeight: 400, color: "#161616" }}>
              Service Catalog
            </h1>
            <p style={{ color: "#525252", marginTop: "0.5rem" }}>
              Manage departmental procedures and maintain available registry
              services.
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
              placeholder="e.g., GSN-SRV-004"
              value={formData.serviceId}
              onChange={(e) =>
                setFormData({ ...formData, serviceId: e.target.value })
              }
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
              value={formData.category}
              onChange={(e) =>
                setFormData({ ...formData, category: e.target.value })
              }
            >
              <SelectItem value="Commerce" text="Commerce" />
              <SelectItem value="Civil" text="Civil" />
              <SelectItem value="Police" text="Police" />
              <SelectItem value="Transport" text="Transport" />
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
                                  <Button
                                    size="sm"
                                    kind="tertiary"
                                    onClick={() => {
                                      const serviceToEdit = services.find(
                                        (s) => s.id === row.id,
                                      );
                                      if (serviceToEdit)
                                        openEditModal(serviceToEdit);
                                    }}
                                  >
                                    Edit
                                  </Button>
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
