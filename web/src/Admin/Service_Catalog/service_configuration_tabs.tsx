import "@carbon/styles/css/styles.css";
import { useState, useEffect } from "react";
import CurrentUserBadge from "../../components/CurrentUserBadge";
import { getStoredUser, getAdminOverviewHref } from "../../utils/currentUser";
import { getCategoryForDepartment } from "../../constants/departments";
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
  Tabs,
  TabList,
  Tab,
  TabPanels,
  TabPanel,
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
  Checkbox,
  InlineNotification,
  Tile,
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
  Add,
} from "@carbon/icons-react";

const docHeaders = [
  { key: "documentName", header: "Document Type" },
  { key: "description", header: "Description" },
  { key: "isMandatory", header: "Requirement" },
  { key: "actions", header: "Actions" },
];

const feeHeaders = [
  { key: "feeType", header: "Fee Type" },
  { key: "amount", header: "Amount (LKR)" },
  { key: "effectiveDate", header: "Effective Date" },
  { key: "actions", header: "Actions" },
];

interface ServiceOption {
  id: number;
  serviceId: string;
  name: string;
  category?: string;
  status?: string;
}

interface DocumentRequirement {
  id: string;
  documentName: string;
  description: string;
  isMandatory: boolean;
}

interface FeeSchedule {
  id: string;
  feeType: string;
  amount: number;
  effectiveDate: string;
}

export default function ServiceConfigurationTabs() {
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(false);
  const [currentUser] = useState(getStoredUser);
  const [overviewHref] = useState(() => getAdminOverviewHref(currentUser));
  const isDepartmentAdmin = (currentUser?.role || "").toLowerCase().includes("admin") && !!currentUser?.department;
  const scopedCategory = currentUser?.department ? getCategoryForDepartment(currentUser.department) : null;
  const [services, setServices] = useState<ServiceOption[]>([]);
  const [selectedServiceId, setSelectedServiceId] = useState<string>("");
  const [selectedServiceName, setSelectedServiceName] = useState<string>("");

  const [documents, setDocuments] = useState<DocumentRequirement[]>([]);
  const [fees, setFees] = useState<FeeSchedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [notification, setNotification] = useState<{
    type: "success" | "error";
    title: string;
    subtitle: string;
  } | null>(null);

  // Modal State for Adding/Editing Documents
  const [isDocModalOpen, setIsDocModalOpen] = useState(false);
  const [isDocEditMode, setIsDocEditMode] = useState(false);
  const [currentDocId, setCurrentDocId] = useState<string | null>(null);
  const [docForm, setDocForm] = useState({
    documentName: "",
    description: "",
    isMandatory: true,
  });

  // Modal State for Adding/Editing Fees
  const [isFeeModalOpen, setIsFeeModalOpen] = useState(false);
  const [isFeeEditMode, setIsFeeEditMode] = useState(false);
  const [currentFeeId, setCurrentFeeId] = useState<string | null>(null);
  const [feeForm, setFeeForm] = useState({
    feeType: "",
    amount: "",
    effectiveDate: new Date().toISOString().split("T")[0],
  });

  // 1. Fetch all services on mount
    useEffect(() => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        const activeServices = data.filter((srv: ServiceOption) => srv.status === "Active");
        setServices(activeServices);
        const scopedServices = activeServices.filter(
          (srv: ServiceOption) => !isDepartmentAdmin || !scopedCategory || srv.category === scopedCategory
        );
        if (scopedServices.length > 0) {
          setSelectedServiceId(scopedServices[0].id.toString());
          setSelectedServiceName(scopedServices[0].name);
        }
        setIsLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
        setIsLoading(false);
      });
  }, [isDepartmentAdmin, scopedCategory]);


  // 2. Fetch procedure details (documents and fees) when selected procedure changes
  useEffect(() => {
    if (!selectedServiceId) return;

    const loadConfig = async () => {
      const currentSrv = services.find(
        (s) => s.id.toString() === selectedServiceId,
      );
      if (currentSrv) {
        setSelectedServiceName(currentSrv.name);
      }

      setIsLoading(true);
      try {
        const res = await fetch(`http://localhost:5119/api/services/${selectedServiceId}`);
        const data = await res.json();
        const formattedDocs = (data.documentRequirements || []).map(
          (d: Omit<DocumentRequirement, "id"> & { id: number }) => ({
            ...d,
            id: d.id.toString(),
          }),
        );
        const formattedFees = (data.feeSchedules || []).map(
          (f: Omit<FeeSchedule, "id"> & { id: number }) => ({
            ...f,
            id: f.id.toString(),
          }),
        );
        setDocuments(formattedDocs);
        setFees(formattedFees);
      } catch (error) {
        console.error("Error fetching service config:", error);
      } finally {
        setIsLoading(false);
      }
    };

    loadConfig();
  }, [selectedServiceId, services]);

  // Document Handlers
  const openAddDocModal = () => {
    setIsDocEditMode(false);
    setCurrentDocId(null);
    setDocForm({ documentName: "", description: "", isMandatory: true });
    setIsDocModalOpen(true);
  };

  const openEditDocModal = (doc: DocumentRequirement) => {
    setIsDocEditMode(true);
    setCurrentDocId(doc.id);
    setDocForm({
      documentName: doc.documentName,
      description: doc.description === "—" ? "" : doc.description,
      isMandatory: doc.isMandatory,
    });
    setIsDocModalOpen(true);
  };

  const handleSaveDocument = async () => {
    if (!docForm.documentName) return;

    let updatedDocs = [...documents];
    if (isDocEditMode) {
      updatedDocs = updatedDocs.map((d) =>
        d.id === currentDocId ? { ...d, ...docForm } : d,
      );
    } else {
      const newDoc = {
        id: "0",
        serviceProcedureId: parseInt(selectedServiceId),
        ...docForm,
      };
      updatedDocs.push(newDoc);
    }

    try {
      const payload = updatedDocs.map((d) => ({
        id:
          !isNaN(Number(d.id)) && String(d.id).length < 15 ? parseInt(d.id) : 0,
        serviceProcedureId: parseInt(selectedServiceId),
        documentName: d.documentName,
        description: d.description,
        isMandatory: d.isMandatory,
      }));

      const response = await fetch(
        `http://localhost:5119/api/services/${selectedServiceId}/documents`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );

      if (response.ok) {
        const result = await response.json();
        setDocuments(
          (result.documentRequirements || []).map(
            (d: Omit<DocumentRequirement, "id"> & { id: number }) => ({
              ...d,
              id: d.id.toString(),
            }),
          ),
        );
        setIsDocModalOpen(false);
        setDocForm({ documentName: "", description: "", isMandatory: true });
        setNotification({
          type: "success",
          title: "Success",
          subtitle: "Document requirements updated successfully!",
        });
      } else {
        const errData = await response.json();
        setNotification({
          type: "error",
          title: "Database Error",
          subtitle: errData.message || "Failed to save documents.",
        });
      }
    } catch (error) {
      console.error("Error saving documents:", error);
    }
  };

  const handleDeleteDocument = async (docId: string) => {
    if (!docId.startsWith("temp_") && !isNaN(Number(docId))) {
      try {
        await fetch(`http://localhost:5119/api/services/documents/${docId}`, {
          method: "DELETE",
        });
      } catch (error) {
        console.error("Error deleting document from DB:", error);
      }
    }

    const updatedDocs = documents.filter((d) => d.id !== docId);
    setDocuments(updatedDocs);
    setNotification({
      type: "success",
      title: "Deleted",
      subtitle: "Document requirement removed successfully.",
    });
  };

  // Fee Handlers
  const openAddFeeModal = () => {
    setIsFeeEditMode(false);
    setCurrentFeeId(null);
    setFeeForm({
      feeType: "",
      amount: "",
      effectiveDate: new Date().toISOString().split("T")[0],
    });
    setIsFeeModalOpen(true);
  };

  const openEditFeeModal = (fee: FeeSchedule) => {
    setIsFeeEditMode(true);
    setCurrentFeeId(fee.id);
    setFeeForm({
      feeType: fee.feeType,
      amount: fee.amount.toString(),
      effectiveDate: fee.effectiveDate
        ? fee.effectiveDate.split("T")[0]
        : new Date().toISOString().split("T")[0],
    });
    setIsFeeModalOpen(true);
  };

  const handleSaveFee = async () => {
    let updatedFees = [...fees];
    if (isFeeEditMode) {
      updatedFees = updatedFees.map((f) =>
        f.id === currentFeeId
          ? { ...f, ...feeForm, amount: parseFloat(feeForm.amount) }
          : f,
      );
    } else {
      const newFee = {
        id: "0",
        serviceProcedureId: parseInt(selectedServiceId),
        feeType: feeForm.feeType,
        amount: parseFloat(feeForm.amount),
        effectiveDate: new Date(feeForm.effectiveDate).toISOString(),
      };
      updatedFees.push(newFee);
    }

    try {
      const payload = updatedFees.map((f) => ({
        id:
          !isNaN(Number(f.id)) && String(f.id).length < 15 ? parseInt(f.id) : 0,
        serviceProcedureId: parseInt(selectedServiceId),
        feeType: f.feeType,
        amount: f.amount,
        effectiveDate: new Date(f.effectiveDate).toISOString(),
      }));

      const response = await fetch(
        `http://localhost:5119/api/services/${selectedServiceId}/fees`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        },
      );

      if (response.ok) {
        const result = await response.json();
        setFees(
          (result.feeSchedules || []).map(
            (f: Omit<FeeSchedule, "id"> & { id: number }) => ({
              ...f,
              id: f.id.toString(),
            }),
          ),
        );
        setIsFeeModalOpen(false);
        setNotification({
          type: "success",
          title: "Success",
          subtitle: "Fee schedules updated successfully!",
        });
      }
    } catch (error) {
      console.error("Error saving fees:", error);
    }
  };

  const handleDeleteFee = async (feeId: string) => {
    if (!feeId.startsWith("temp_") && !isNaN(Number(feeId))) {
      try {
        await fetch(`http://localhost:5119/api/services/fees/${feeId}`, {
          method: "DELETE",
        });
      } catch (error) {
        console.error("Error deleting fee from DB:", error);
      }
    }

    setFees(fees.filter((f) => f.id !== feeId));
    setNotification({
      type: "success",
      title: "Deleted",
      subtitle: "Fee schedule removed successfully.",
    });
  };

  const visibleServices = services.filter(
    (srv) => !isDepartmentAdmin || !scopedCategory || srv.category === scopedCategory
  );

  const filteredDocs = documents.filter(
    (d) =>
      d.documentName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      d.description?.toLowerCase().includes(searchQuery.toLowerCase()),
  );

  const filteredFees = fees.filter(
    (f) =>
      f.feeType?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.amount?.toString().includes(searchQuery),
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
              id="search-config"
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
            <SideNavLink renderIcon={Catalog} href="/admin/services">
              Service Catalog
            </SideNavLink>
            <SideNavLink renderIcon={Rule} href="/admin/services/rules">
              Eligibility Rules
            </SideNavLink>

            <SideNavLink
              renderIcon={Categories}
              href="/admin/services/config"
              isActive
            >
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
            {selectedServiceName
              ? `Configure: ${selectedServiceName}`
              : "Service Configuration"}
          </h1>
          <p style={{ color: "#525252", marginTop: "0.5rem" }}>
            Manage document requirements and fee schedules for departmental
            services.
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
            id="target-service-config-select"
            labelText="Select Target Service Procedure"
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

        <div style={{ width: "100%" }}>
          <Tabs>
            <TabList aria-label="Configuration Tabs">
              <Tab>Required Documents</Tab>
              <Tab>Fee Schedule</Tab>
            </TabList>
            <TabPanels>
              {/* Documents Tab */}
              <TabPanel
                style={{ padding: "2rem 0", backgroundColor: "transparent" }}
              >
                {isLoading ? (
                  <Loading
                    description="Loading documents..."
                    withOverlay={false}
                  />
                ) : (
                  <>
                    <DataTable rows={filteredDocs} headers={docHeaders}>
                      {({
                        rows,
                        headers,
                        getTableProps,
                        getHeaderProps,
                        getRowProps,
                      }) => (
                        <TableContainer
                          title="Document Checklist"
                          description="Files required from citizens for this specific procedure."
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
                                    style={{
                                      textAlign: "center",
                                      padding: "2rem",
                                    }}
                                  >
                                    No document requirements configured for this
                                    procedure yet.
                                  </TableCell>
                                </TableRow>
                              ) : (
                                rows.map((row) => (
                                  <TableRow
                                    {...getRowProps({ row })}
                                    key={row.id}
                                  >
                                    {row.cells.map((cell) => {
                                      if (cell.info.header === "isMandatory") {
                                        return (
                                          <TableCell key={cell.id}>
                                            <Tag
                                              type={cell.value ? "red" : "gray"}
                                            >
                                              {cell.value
                                                ? "Mandatory"
                                                : "Optional"}
                                            </Tag>
                                          </TableCell>
                                        );
                                      }
                                      if (cell.info.header === "actions") {
                                        const docItem = documents.find(
                                          (d) => d.id === row.id,
                                        );
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
                                                onClick={() =>
                                                  docItem &&
                                                  openEditDocModal(docItem)
                                                }
                                              />
                                              <Button
                                                size="sm"
                                                kind="danger--ghost"
                                                renderIcon={TrashCan}
                                                iconDescription="Delete"
                                                hasIconOnly
                                                onClick={() =>
                                                  handleDeleteDocument(row.id)
                                                }
                                              />
                                            </div>
                                          </TableCell>
                                        );
                                      }
                                      return (
                                        <TableCell key={cell.id}>
                                          {cell.value || "—"}
                                        </TableCell>
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
                    <Button
                      kind="secondary"
                      renderIcon={Add}
                      style={{ marginTop: "1.5rem" }}
                      onClick={openAddDocModal}
                    >
                      Add Document Requirement
                    </Button>
                  </>
                )}
              </TabPanel>

              {/* Fee Schedule Tab */}
              <TabPanel
                style={{ padding: "2rem 0", backgroundColor: "transparent" }}
              >
                {isLoading ? (
                  <Loading description="Loading fees..." withOverlay={false} />
                ) : (
                  <>
                    <DataTable
                      rows={filteredFees.map((f) => ({
                        ...f,
                        id: f.id.toString(),
                        effectiveDate: f.effectiveDate
                          ? new Date(f.effectiveDate).toLocaleDateString()
                          : "—",
                      }))}
                      headers={feeHeaders}
                    >
                      {({
                        rows,
                        headers,
                        getTableProps,
                        getHeaderProps,
                        getRowProps,
                      }) => (
                        <TableContainer
                          title="Tiered Fee Structure"
                          description="Pricing tiers configured for this service."
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
                                    style={{
                                      textAlign: "center",
                                      padding: "2rem",
                                    }}
                                  >
                                    No fee schedules configured for this
                                    service.
                                  </TableCell>
                                </TableRow>
                              ) : (
                                rows.map((row) => (
                                  <TableRow
                                    {...getRowProps({ row })}
                                    key={row.id}
                                  >
                                    {row.cells.map((cell) => {
                                      if (cell.info.header === "actions") {
                                        const feeItem = fees.find(
                                          (f) => f.id === row.id,
                                        );
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
                                                onClick={() =>
                                                  feeItem &&
                                                  openEditFeeModal(feeItem)
                                                }
                                              />
                                              <Button
                                                size="sm"
                                                kind="danger--ghost"
                                                renderIcon={TrashCan}
                                                iconDescription="Delete"
                                                hasIconOnly
                                                onClick={() =>
                                                  handleDeleteFee(row.id)
                                                }
                                              />
                                            </div>
                                          </TableCell>
                                        );
                                      }
                                      return (
                                        <TableCell key={cell.id}>
                                          {cell.value}
                                        </TableCell>
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
                    <Button
                      kind="secondary"
                      renderIcon={Add}
                      style={{ marginTop: "1.5rem" }}
                      onClick={openAddFeeModal}
                    >
                      Add Fee
                    </Button>
                  </>
                )}
              </TabPanel>
            </TabPanels>
          </Tabs>
        </div>

        {/* Add/Edit Document Modal */}
        <Modal
          open={isDocModalOpen}
          modalHeading={
            isDocEditMode
              ? "Edit Document Requirement"
              : "Add Required Document"
          }
          primaryButtonText={isDocEditMode ? "Save Changes" : "Add Document"}
          secondaryButtonText="Cancel"
          onRequestClose={() => setIsDocModalOpen(false)}
          onRequestSubmit={handleSaveDocument}
        >
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "1.2rem",
              paddingTop: "1rem",
            }}
          >
            <TextInput
              id="docName"
              labelText="Document Type Name"
              placeholder="e.g., National Identity Card (NIC)"
              value={docForm.documentName}
              onChange={(e) =>
                setDocForm({ ...docForm, documentName: e.target.value })
              }
            />
            <TextInput
              id="docDesc"
              labelText="Description / Instructions"
              placeholder="e.g., Front and back copy required"
              value={docForm.description}
              onChange={(e) =>
                setDocForm({ ...docForm, description: e.target.value })
              }
            />
            <Checkbox
              id="isMandatory"
              labelText="Mandatory Requirement"
              checked={docForm.isMandatory}
              onChange={(_, { checked }) =>
                setDocForm({ ...docForm, isMandatory: checked })
              }
            />
          </div>
        </Modal>

        {/* Add/Edit Fee Modal */}
        <Modal
          open={isFeeModalOpen}
          modalHeading={
            isFeeEditMode ? "Edit Fee Schedule" : "Add Fee Schedule"
          }
          primaryButtonText={isFeeEditMode ? "Save Changes" : "Add Fee"}
          secondaryButtonText="Cancel"
          onRequestClose={() => setIsFeeModalOpen(false)}
          onRequestSubmit={handleSaveFee}
        >
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              gap: "1.2rem",
              paddingTop: "1rem",
            }}
          >
            <TextInput
              id="feeType"
              labelText="Fee Type"
              placeholder="e.g., Standard Processing Fee"
              value={feeForm.feeType}
              onChange={(e) =>
                setFeeForm({ ...feeForm, feeType: e.target.value })
              }
            />
            <TextInput
              id="feeAmount"
              labelText="Amount (LKR)"
              type="number"
              placeholder="e.g., 1500"
              value={feeForm.amount}
              onChange={(e) =>
                setFeeForm({ ...feeForm, amount: e.target.value })
              }
            />
            <TextInput
              id="feeEffectiveDate"
              labelText="Effective Date"
              type="date"
              value={feeForm.effectiveDate}
              onChange={(e) =>
                setFeeForm({ ...feeForm, effectiveDate: e.target.value })
              }
            />
          </div>
        </Modal>
      </main>
    </>
  );
}
