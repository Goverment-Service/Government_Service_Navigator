import { useState, useEffect } from "react";
import {
  TextInput,
  Select,
  SelectItem,
  Button,
  Stack,
  Checkbox,
  TextArea,
  Tag,
  InlineNotification,
} from "@carbon/react";
import { TrashCan, UpToTop, DownToBottom, ArrowLeft } from "@carbon/icons-react";
import { getStoredUser } from "../../utils/currentUser";
import { getCategoryForDepartment } from "../../constants/departments";

export type FieldType = 
  | 'text' | 'textarea' | 'number' | 'select' | 'multiselect' 
  | 'date' | 'file' | 'heading' | 'paragraph' | 'table' | 'payment';

export interface FormField {
  id: string;
  label: string;
  type: FieldType;
  options?: string; // Comma separated for select/table
  required?: boolean;
}

interface ServiceOption {
  id: number;
  serviceId: string;
  name: string;
  category: string;
  status: string;
}

interface EligibilityRuleInfo {
  id: number;
  field: string;
  operator: string;
  value: string;
}

interface DocumentRequirementInfo {
  id: number;
  documentName: string;
  description?: string;
  isMandatory: boolean;
}

interface FeeScheduleInfo {
  id: number;
  feeType: string;
  amount: number;
  effectiveDate: string;
}

interface ServiceDetail {
  id: number;
  serviceId: string;
  name: string;
  category: string;
  eligibilityRules: EligibilityRuleInfo[];
  documentRequirements: DocumentRequirementInfo[];
  feeSchedules: FeeScheduleInfo[];
}

export default function TemplateBuilder() {
  const [templateId, setTemplateId] = useState<string | null>(null);
  const [formName, setFormName] = useState("");
  const [subTitle, setSubTitle] = useState("");
  const [lawText, setLawText] = useState("");
  
  // Multi-department sequential stage configuration
  const [department, setDepartment] = useState<string>("Civil Department");
  const [stageOrder, setStageOrder] = useState<number>(1);
  const [stageDescription, setStageDescription] = useState<string>("");
  
  const [customFields, setCustomFields] = useState<FormField[]>([]);
  
  const [newFieldLabel, setNewFieldLabel] = useState("");
  const [newFieldType, setNewFieldType] = useState<FieldType>("text");
  const [newFieldOptions, setNewFieldOptions] = useState("");
  const [newFieldRequired, setNewFieldRequired] = useState(false);
  const [paymentFeeAmount, setPaymentFeeAmount] = useState<number>(5000);
  const [paymentMethods, setPaymentMethods] = useState<string>("Online Card, Manual Bank Deposit Slip");
  const [selectedFeeScheduleId, setSelectedFeeScheduleId] = useState<string>("");
  const [isSaving, setIsSaving] = useState(false);

  // Linking this template to a Service Catalog entry so its Eligibility
  // Rules and Document/Fee configuration can be shown as reference while
  // the officer builds the form. Every officer belongs to one department, so
  // (unlike the Admin-side pages, which also allow a departmentless System
  // Admin through) any signed-in officer with a department only sees that
  // department's services here.
  const [currentUser] = useState(getStoredUser);
  const scopedCategory = currentUser?.department ? getCategoryForDepartment(currentUser.department) : null;
  const [services, setServices] = useState<ServiceOption[]>([]);
  const [linkedServiceId, setLinkedServiceId] = useState<string>("");
  const [linkedServiceDetail, setLinkedServiceDetail] = useState<ServiceDetail | null>(null);
  const [isLoadingServiceDetail, setIsLoadingServiceDetail] = useState(false);

  useEffect(() => {
    const urlDept = new URLSearchParams(window.location.search).get("department");
    if (!urlDept && currentUser?.department) {
      setDepartment(currentUser.department);
    }
  }, [currentUser]);

  useEffect(() => {
    fetch("http://localhost:5119/api/services")
      .then((res) => res.json())
      .then((data) => {
        setServices(data.filter((srv: ServiceOption) => srv.status === "Active"));
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
      });
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (!linkedServiceId) {
        setLinkedServiceDetail(null);
        return;
      }
      setIsLoadingServiceDetail(true);
      fetch(`http://localhost:5119/api/services/${linkedServiceId}`)
        .then((res) => res.json())
        .then((data) => setLinkedServiceDetail(data))
        .catch((error) => {
          console.error("Error fetching linked service details:", error);
          setLinkedServiceDetail(null);
        })
        .finally(() => setIsLoadingServiceDetail(false));
    }, 0);
    return () => clearTimeout(timer);
  }, [linkedServiceId]);

  const fetchTemplateData = async (id: string) => {
    try {
      const response = await fetch(`http://localhost:5119/api/templates/${id}`);
      if (response.ok) {
        const data = await response.json();
        setFormName(data.formName || "");
        setSubTitle(data.subTitle || "");
        setLawText(data.lawText || "");
        if (data.serviceProcedureId) {
          setLinkedServiceId(data.serviceProcedureId.toString());
        }
        if (data.department) setDepartment(data.department);
        if (data.stageOrder) setStageOrder(data.stageOrder);
        if (data.stageDescription) setStageDescription(data.stageDescription);
        if (data.fields) {
          setCustomFields(data.fields.map((f: { id?: string; label: string; type: FieldType; options?: string; isRequired?: boolean }) => ({
            id: f.id || Date.now().toString() + Math.random(),
            label: f.label,
            type: f.type,
            options: f.options,
            required: f.isRequired
          })));
        }
      }
    } catch (error) {
      console.error("Error fetching template", error);
    }
  };

  useEffect(() => {
    const queryParams = new URLSearchParams(window.location.search);
    const id = queryParams.get("id");
    const serviceId = queryParams.get("serviceId");
    const stage = queryParams.get("stage");
    const dept = queryParams.get("department");

    if (serviceId) setLinkedServiceId(serviceId);
    if (stage) setStageOrder(parseInt(stage, 10) || 1);
    if (dept) setDepartment(dept);

    if (id) {
      const load = async () => {
        setTemplateId(id);
        await fetchTemplateData(id);
      };
      load();
    }
  }, []);

  const handleSaveTemplate = async () => {
    try {
      setIsSaving(true);
      const token = localStorage.getItem("officerToken");
      
      const payload = {
        formName: formName,
        subTitle: subTitle,
        lawText: lawText,
        serviceProcedureId: linkedServiceId ? Number(linkedServiceId) : null,
        department: department || currentUser?.department || null,
        stageOrder: Number(stageOrder) || 1,
        stageDescription: stageDescription || null,
        fields: customFields.map(f => ({
          label: f.label,
          type: f.type,
          options: f.options,
          required: f.required || false
        }))
      };

      const url = templateId 
        ? `http://localhost:5119/api/templates/update/${templateId}` 
        : "http://localhost:5119/api/templates/create";
      const method = templateId ? "PUT" : "POST";

      const response = await fetch(url, {
        method: method,
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error("Failed to save template");
      }

      alert(`Stage ${stageOrder} Form Template Saved Successfully!`);
      const searchServiceId = new URLSearchParams(window.location.search).get("serviceId");
      const returnSvcId = linkedServiceId || searchServiceId || "";
      const isAdminContext = window.location.pathname.startsWith("/admin") || Boolean(searchServiceId);
      if (isAdminContext) {
        window.location.href = `/admin/services/config?serviceId=${encodeURIComponent(returnSvcId)}&tab=3`;
      } else {
        window.location.href = "/officer/dashboard";
      }
    } catch (error) {
      console.error(error);
      alert("Error saving template. Please check console.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleAddField = () => {
    if (!newFieldLabel) return;

    let optionsVal: string | undefined = undefined;
    if (['select', 'multiselect', 'table'].includes(newFieldType)) {
      optionsVal = newFieldOptions;
    } else if (newFieldType === 'payment') {
      optionsVal = JSON.stringify({
        feeType: newFieldLabel,
        amount: paymentFeeAmount,
        methods: paymentMethods,
      });
    }

    const newField: FormField = {
      id: Date.now().toString(),
      label: newFieldLabel,
      type: newFieldType,
      required: newFieldType === 'payment' ? true : newFieldRequired,
      options: optionsVal
    };
    setCustomFields([...customFields, newField]);
    setNewFieldLabel("");
    setNewFieldOptions("");
    setNewFieldType("text");
    setNewFieldRequired(false);
  };

  const handleRemoveField = (id: string) => {
    setCustomFields(customFields.filter(f => f.id !== id));
  };

  const moveField = (index: number, direction: 'up' | 'down') => {
    if (direction === 'up' && index === 0) return;
    if (direction === 'down' && index === customFields.length - 1) return;
    
    const newFields = [...customFields];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;
    [newFields[index], newFields[swapIndex]] = [newFields[swapIndex], newFields[index]];
    setCustomFields(newFields);
  };

  const renderFieldPreview = (field: FormField) => {
    switch (field.type) {
      case 'heading':
        return <h4 style={{ marginTop: '1.5rem', marginBottom: '0.5rem', fontWeight: 'bold', textTransform: 'uppercase', borderBottom: '2px solid #000', paddingBottom: '4px' }}>{field.label}</h4>;
      
      case 'paragraph':
        return <p style={{ marginBottom: '1rem', fontStyle: 'italic', fontSize: '0.9rem' }}>{field.label}</p>;
      
      case 'table': {
        const columns = field.options ? field.options.split(',').map(s => s.trim()) : ['Col 1', 'Col 2'];
        return (
          <div style={{ marginBottom: '1.5rem', width: '100%', overflowX: 'auto' }}>
            {field.label && field.label !== 'Table' && <div style={{ fontWeight: 'bold', marginBottom: '0.5rem' }}>{field.label}</div>}
            <table style={{ width: '100%', borderCollapse: 'collapse', border: '1px solid #000', fontSize: '0.85rem' }}>
              <thead>
                <tr>
                  {columns.map((col, i) => (
                    <th key={i} style={{ border: '1px solid #000', padding: '8px', backgroundColor: '#e0e0e0', textAlign: 'left' }}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                <tr>
                  {columns.map((_, i) => (
                    <td key={i} style={{ border: '1px solid #000', padding: '16px' }}></td>
                  ))}
                </tr>
                <tr>
                  {columns.map((_, i) => (
                    <td key={i} style={{ border: '1px solid #000', padding: '16px' }}></td>
                  ))}
                </tr>
              </tbody>
            </table>
          </div>
        );
      }

      case 'file':
        return (
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
            <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
            <div style={{ flex: 1, border: '1px dashed #666', padding: '1rem', textAlign: 'center', backgroundColor: '#fafafa', color: '#666' }}>
              [ Required Document Upload ]
            </div>
          </div>
        );

      case 'payment': {
        let paymentConfig = { feeType: "Statutory Processing Fee", amount: 5000, methods: "Online Card, Manual Bank Deposit Slip" };
        if (field.options) {
          try {
            paymentConfig = { ...paymentConfig, ...JSON.parse(field.options) };
          } catch {
            paymentConfig.feeType = field.options;
          }
        }
        return (
          <div style={{ margin: '1.25rem 0', border: '2px solid #0043ce', borderRadius: '4px', backgroundColor: '#f0f5ff', padding: '1.25rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #d0e2ff', paddingBottom: '0.75rem', marginBottom: '1rem' }}>
              <div>
                <span style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.5px', color: '#0043ce', fontWeight: 'bold' }}>
                  Statutory Government Fee
                </span>
                <h4 style={{ margin: '0.25rem 0 0 0', fontWeight: 'bold', fontSize: '1.1rem', color: '#161616' }}>
                  {field.label || paymentConfig.feeType}
                </h4>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontSize: '0.75rem', color: '#525252' }}>Payable Amount</span>
                <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#0043ce' }}>
                  Rs. {Number(paymentConfig.amount).toLocaleString()}
                </div>
              </div>
            </div>

            <div style={{ fontSize: '0.85rem', color: '#393939', marginBottom: '0.75rem' }}>
              <strong>Payment Options Accepted:</strong> {paymentConfig.methods}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', backgroundColor: '#fff', padding: '0.75rem', border: '1px solid #d0e2ff', borderRadius: '4px' }}>
              <div>
                <span style={{ fontSize: '0.75rem', color: '#666', display: 'block' }}>Option 1: Online Payment</span>
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>{"Credit / Debit Card (Instant Clearance)"}</span>
              </div>
              <div>
                <span style={{ fontSize: '0.75rem', color: '#666', display: 'block' }}>Option 2: Bank Deposit Slip</span>
                <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>{"Upload stamped deposit slip and reference number"}</span>
              </div>
            </div>

            <div style={{ marginTop: '0.75rem', fontSize: '0.75rem', color: '#525252', fontStyle: 'italic' }}>
              {"Payments are automatically routed to the Department Finance Officer for statutory ledger auditing."}
            </div>
          </div>
        );
      }

      case 'textarea':
        return (
          <div style={{ display: 'flex', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <div style={{ fontWeight: 'bold', width: '30%', marginTop: '0.5rem' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
            <div style={{ flex: 1, minHeight: '4rem', border: '1px solid #000', backgroundColor: '#fff' }} />
          </div>
        );

      case 'date':
        return (
           <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
            <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
            <div style={{ flex: 1, borderBottom: '1px solid #000', paddingBottom: '4px', color: '#666' }}>DD / MM / YYYY</div>
          </div>
        );

      case 'select':
      case 'multiselect':
         return (
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
            <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
            <div style={{ flex: 1, border: '1px solid #000', padding: '8px', color: '#666', backgroundColor: '#fff' }}>
              [ Select from: {field.options || 'None'} ]
            </div>
          </div>
        );

      default: // text, number
        return (
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
             <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
             <div style={{ flex: 1, border: '1px solid #000', padding: '12px', backgroundColor: '#fff' }} />
          </div>
        );
    }
  };

  // Keep the currently linked service visible even if it falls outside the
  // officer's department (e.g. editing a template someone else created),
  // so the dropdown doesn't silently blank out an existing selection.
  const visibleServices = services.filter(
    (srv) => !scopedCategory || srv.category === scopedCategory || srv.id.toString() === linkedServiceId
  );

  const queryParams = new URLSearchParams(window.location.search);
  const isWorkflowLocked = Boolean(
    queryParams.get("serviceId") || 
    queryParams.get("stage") ||
    window.location.pathname.startsWith("/admin")
  );

  return (
    <main className="gsn-shell-main">
      {isWorkflowLocked && (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
          <Button
            kind="ghost"
            size="sm"
            renderIcon={ArrowLeft}
            onClick={() => {
              const searchServiceId = new URLSearchParams(window.location.search).get("serviceId");
              const returnSvcId = linkedServiceId || searchServiceId || "";
              window.location.href = `/admin/services/config?serviceId=${encodeURIComponent(returnSvcId)}&tab=3`;
            }}
            style={{ color: '#0f62fe' }}
          >
            Back to Service Workflow Configuration
          </Button>
          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
            <Tag type="blue" size="md">ADMIN SERVICE DESIGNER</Tag>
            <Tag type="teal" size="md">STAGE {stageOrder}</Tag>
          </div>
        </div>
      )}

      <div style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Advanced Template Builder</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>Design highly customizable application forms matching official government layouts.</p>
      </div>

      <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
        
        {/* Builder Controls (Left Side) */}
        <div className="w-full lg:flex-1 lg:min-w-[350px] lg:max-w-[450px] lg:sticky lg:top-20" style={{ backgroundColor: '#fff', padding: '1.5rem', border: '1px solid #e0e0e0' }}>
          <h3 style={{ fontSize: '1.2rem', marginBottom: '1.5rem', borderBottom: '1px solid #e0e0e0', paddingBottom: '0.5rem' }}>Document Headers</h3>
          <Stack gap={5}>
            <TextInput
              id="formName"
              labelText="Form Number/Identifier"
              value={formName}
              onChange={(e) => setFormName(e.target.value)}
            />
            <TextInput
              id="subTitle"
              labelText="Main Title"
              value={subTitle}
              onChange={(e) => setSubTitle(e.target.value)}
            />
            <TextInput
              id="lawText"
              labelText="Legal Reference (Optional)"
              value={lawText}
              onChange={(e) => setLawText(e.target.value)}
            />

            {isWorkflowLocked ? (
              <div style={{
                padding: '1.25rem',
                backgroundColor: '#edf5ff',
                border: '1px solid #a6c8ff',
                borderLeft: '5px solid #0f62fe',
                borderRadius: '4px',
                marginTop: '0.5rem',
                marginBottom: '0.5rem'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                  <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: '#0f62fe', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    Workflow Stage Assignment (Locked)
                  </span>
                  <Tag type="blue" size="sm">Stage {stageOrder}</Tag>
                </div>

                <div style={{ marginBottom: '0.75rem' }}>
                  <div style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', fontWeight: 600 }}>Assigned Department</div>
                  <div style={{ fontSize: '1rem', fontWeight: 600, color: '#161616', marginTop: '2px' }}>{department}</div>
                </div>

                <div>
                  <div style={{ fontSize: '0.75rem', color: '#525252', textTransform: 'uppercase', fontWeight: 600 }}>Linked Service Procedure</div>
                  <div style={{ fontSize: '0.95rem', fontWeight: 600, color: '#161616', marginTop: '2px' }}>
                    {linkedServiceDetail ? `${linkedServiceDetail.serviceId} - ${linkedServiceDetail.name}` : (services.find(s => s.id.toString() === linkedServiceId)?.name || (linkedServiceId ? `Service #${linkedServiceId}` : 'None'))}
                  </div>
                </div>

                <p style={{ margin: '0.75rem 0 0 0', fontSize: '0.75rem', color: '#525252', fontStyle: 'italic', borderTop: '1px dashed #c6c6c6', paddingTop: '0.5rem' }}>
                  Assigned and locked by Service Workflow Configuration. Applications at this stage route directly to {department} verification officers.
                </p>
              </div>
            ) : (
              <>
                <Select
                  id="department"
                  labelText="Assigned Department"
                  helperText="The government department whose officers will verify this form stage."
                  value={department}
                  onChange={(e) => setDepartment(e.target.value)}
                >
                  <SelectItem value="Civil Department" text="Civil Department" />
                  <SelectItem value="Police Department" text="Police Department" />
                  <SelectItem value="Transport Department" text="Transport Department" />
                  <SelectItem value="Department of Registration of Persons" text="Department of Registration of Persons" />
                  <SelectItem value="Department of Immigration & Emigration" text="Department of Immigration & Emigration" />
                  <SelectItem value="Department of Motor Traffic" text="Department of Motor Traffic" />
                  <SelectItem value="Divisional Secretariat" text="Divisional Secretariat" />
                </Select>

                <TextInput
                  id="stageOrder"
                  type="number"
                  min={1}
                  labelText="Sequential Workflow Stage Number"
                  helperText="Enter the sequential stage number this form belongs to (e.g. 1, 2, 3, 4, 5...)."
                  value={stageOrder.toString()}
                  onChange={(e) => setStageOrder(Math.max(1, parseInt(e.target.value, 10) || 1))}
                />

                <Select
                  id="linkedService"
                  labelText="Linked Service Catalog Entry (Optional)"
                  helperText="Ties this template to a service so its eligibility rules and required documents/fees show below."
                  value={linkedServiceId}
                  onChange={(e) => setLinkedServiceId(e.target.value)}
                >
                  <SelectItem value="" text="None" />
                  {visibleServices.map((srv) => (
                    <SelectItem key={srv.id} value={srv.id.toString()} text={`${srv.serviceId} - ${srv.name}`} />
                  ))}
                </Select>
              </>
            )}

            <TextInput
              id="stageDescription"
              labelText="Stage Instructions for Citizens"
              placeholder="e.g. Identity and address verification by Civil Department"
              value={stageDescription}
              onChange={(e) => setStageDescription(e.target.value)}
            />

            {linkedServiceId && (
              <div style={{ padding: '1rem', backgroundColor: '#f4f4f4', borderLeft: '4px solid #24a148' }}>
                <h4 style={{ marginBottom: '1rem', fontWeight: 'bold' }}>Service Requirements</h4>
                {isLoadingServiceDetail ? (
                  <p style={{ color: '#525252', fontSize: '0.875rem' }}>Loading...</p>
                ) : !linkedServiceDetail ? (
                  <InlineNotification
                    kind="error"
                    lowContrast
                    hideCloseButton
                    title="Could not load service details"
                    subtitle="The service may have been removed from the catalog."
                  />
                ) : (
                  <Stack gap={5}>
                    <div>
                      <p style={{ fontSize: '0.75rem', fontWeight: 'bold', textTransform: 'uppercase', color: '#525252', marginBottom: '0.5rem' }}>
                        Eligibility Rules
                      </p>
                      {linkedServiceDetail.eligibilityRules.length === 0 ? (
                        <p style={{ fontSize: '0.875rem', color: '#8d8d8d', fontStyle: 'italic' }}>None defined.</p>
                      ) : (
                        <ul style={{ margin: 0, paddingLeft: '1.1rem', fontSize: '0.875rem' }}>
                          {linkedServiceDetail.eligibilityRules.map((rule) => (
                            <li key={rule.id}>{rule.field} {rule.operator} {rule.value}</li>
                          ))}
                        </ul>
                      )}
                    </div>

                    <div>
                      <p style={{ fontSize: '0.75rem', fontWeight: 'bold', textTransform: 'uppercase', color: '#525252', marginBottom: '0.5rem' }}>
                        Required Documents
                      </p>
                      {linkedServiceDetail.documentRequirements.length === 0 ? (
                        <p style={{ fontSize: '0.875rem', color: '#8d8d8d', fontStyle: 'italic' }}>None defined.</p>
                      ) : (
                        <Stack gap={2}>
                          {linkedServiceDetail.documentRequirements.map((doc) => (
                            <div key={doc.id} className="flex items-center flex-wrap" style={{ display: 'flex', gap: '0.5rem', fontSize: '0.875rem' }}>
                              <span>{doc.documentName}</span>
                              <Tag type={doc.isMandatory ? 'red' : 'gray'} size="sm">
                                {doc.isMandatory ? 'Mandatory' : 'Optional'}
                              </Tag>
                            </div>
                          ))}
                        </Stack>
                      )}
                    </div>

                    <div>
                      <p style={{ fontSize: '0.75rem', fontWeight: 'bold', textTransform: 'uppercase', color: '#525252', marginBottom: '0.5rem' }}>
                        Fees
                      </p>
                      {linkedServiceDetail.feeSchedules.length === 0 ? (
                        <p style={{ fontSize: '0.875rem', color: '#8d8d8d', fontStyle: 'italic' }}>None defined.</p>
                      ) : (
                        <ul style={{ margin: 0, paddingLeft: '1.1rem', fontSize: '0.875rem' }}>
                          {linkedServiceDetail.feeSchedules.map((fee) => (
                            <li key={fee.id}>{fee.feeType} - LKR {fee.amount.toLocaleString()}</li>
                          ))}
                        </ul>
                      )}
                    </div>
                  </Stack>
                )}
              </div>
            )}

            <div style={{ marginTop: '1rem', padding: '1rem', backgroundColor: '#f4f4f4', borderLeft: '4px solid #0f62fe' }}>
              <h4 style={{ marginBottom: '1rem', fontWeight: 'bold' }}>Add New Element</h4>
              <Stack gap={5}>
                <Select
                  id="fieldType"
                  labelText="Element Type"
                  value={newFieldType}
                  onChange={(e) => {
                    const val = e.target.value as FieldType;
                    setNewFieldType(val);
                    if (val === 'payment') {
                      if (!newFieldLabel) setNewFieldLabel("Statutory Processing Fee");
                      setNewFieldRequired(true);
                    }
                  }}
                >
                  <optgroup label="Layout & Text">
                    <SelectItem value="heading" text="Section Heading" />
                    <SelectItem value="paragraph" text="Paragraph / Instructions" />
                  </optgroup>
                  <optgroup label="Inputs">
                    <SelectItem value="text" text="Short Text Input" />
                    <SelectItem value="textarea" text="Long Text Area" />
                    <SelectItem value="number" text="Number Input" />
                    <SelectItem value="date" text="Date Picker" />
                  </optgroup>
                  <optgroup label="Selections">
                    <SelectItem value="select" text="Dropdown (Single Select)" />
                    <SelectItem value="multiselect" text="Dropdown (Multi-Select)" />
                  </optgroup>
                  <optgroup label="Complex & Official">
                    <SelectItem value="table" text="Data Table Grid" />
                    <SelectItem value="file" text="Required Document Upload" />
                    <SelectItem value="payment" text="💳 Statutory Payment Section" />
                  </optgroup>
                </Select>

                <TextArea
                  id="fieldLabel"
                  labelText={['heading', 'paragraph'].includes(newFieldType) ? "Text Content" : newFieldType === 'payment' ? "Payment Section Title" : "Field Label"}
                  rows={2}
                  value={newFieldLabel}
                  onChange={(e) => setNewFieldLabel(e.target.value)}
                />
                
                {newFieldType === 'payment' && (
                  <div style={{ backgroundColor: '#edf5ff', border: '1px solid #a6c8ff', padding: '0.75rem', borderRadius: '4px' }}>
                    <div style={{ fontSize: '0.8125rem', fontWeight: 600, color: '#0043ce', marginBottom: '0.5rem' }}>
                      Statutory Payment Settings
                    </div>

                    {linkedServiceDetail?.feeSchedules && linkedServiceDetail.feeSchedules.length > 0 && (
                      <div style={{ marginBottom: '0.5rem' }}>
                        <Select
                          id="select-fee-schedule"
                          labelText="Link to Service Fee Schedule"
                          size="sm"
                          value={selectedFeeScheduleId}
                          onChange={(e) => {
                            const val = e.target.value;
                            setSelectedFeeScheduleId(val);
                            const found = linkedServiceDetail.feeSchedules.find((f) => f.id.toString() === val);
                            if (found) {
                              setNewFieldLabel(found.feeType);
                              setPaymentFeeAmount(found.amount);
                            }
                          }}
                        >
                          <SelectItem value="" text="-- Select predefined fee --" />
                          {linkedServiceDetail.feeSchedules.map((fee) => (
                            <SelectItem
                              key={fee.id}
                              value={fee.id.toString()}
                              text={`${fee.feeType} — Rs. ${fee.amount.toLocaleString()}`}
                            />
                          ))}
                        </Select>
                      </div>
                    )}

                    <div style={{ marginBottom: '0.5rem' }}>
                      <TextInput
                        id="payment-fee-amount"
                        labelText="Statutory Payable Amount (LKR)"
                        type="number"
                        size="sm"
                        value={paymentFeeAmount}
                        onChange={(e) => setPaymentFeeAmount(Number(e.target.value))}
                      />
                    </div>

                    <div>
                      <TextInput
                        id="payment-methods"
                        labelText="Accepted Payment Methods"
                        size="sm"
                        value={paymentMethods}
                        onChange={(e) => setPaymentMethods(e.target.value)}
                        placeholder="e.g. Online Card, Manual Bank Deposit Slip"
                      />
                    </div>
                  </div>
                )}

                {(['select', 'multiselect', 'table'].includes(newFieldType)) && (
                  <TextArea
                    id="fieldOptions"
                    labelText={newFieldType === 'table' ? "Table Columns (Comma separated)" : "Dropdown Options (Comma separated)"}
                    placeholder="e.g. Option 1, Option 2, Option 3"
                    rows={2}
                    value={newFieldOptions}
                    onChange={(e) => setNewFieldOptions(e.target.value)}
                  />
                )}
                
                {!['heading', 'paragraph', 'payment'].includes(newFieldType) && (
                  <Checkbox 
                    labelText="Required Field" 
                    id="required-checkbox" 
                    checked={newFieldRequired}
                    onChange={(_, {checked}) => setNewFieldRequired(checked)} 
                  />
                )}

                <Button onClick={handleAddField} size="md" disabled={!newFieldLabel.trim()} style={{ marginTop: '0.5rem' }}>
                  Add Element
                </Button>
              </Stack>
            </div>
          </Stack>
        </div>

        {/* Live Form Preview (Right Side) */}
        <div className="w-full lg:flex-[2] lg:min-w-[500px]" style={{ backgroundColor: '#fff', padding: '1.5rem', border: '1px solid #e0e0e0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', borderBottom: '1px solid #e0e0e0', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '1.2rem', color: '#161616' }}>Live Document Preview</h3>
            <Button size="sm" kind="primary" onClick={handleSaveTemplate} disabled={isSaving}>
              {isSaving ? "Saving..." : "Save Template"}
            </Button>
          </div>
          
          <div className="p-4 sm:p-8 lg:p-12" style={{ backgroundColor: '#fff', border: '1px solid #ccc', boxShadow: '0 4px 8px rgba(0,0,0,0.1)' }}>

            {/* Stage & Department Banner */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0.6rem 1rem', backgroundColor: '#edf5ff', border: '1px solid #a6c8ff', borderRadius: '4px', marginBottom: '2rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                <Tag type="blue">Stage {stageOrder}</Tag>
                <span style={{ fontWeight: 600, color: '#0043ce', fontSize: '0.875rem' }}>
                  {department}
                </span>
              </div>
              {stageDescription && (
                <span style={{ fontSize: '0.8rem', color: '#525252', fontStyle: 'italic' }}>
                  {stageDescription}
                </span>
              )}
            </div>

            {/* Form Header matching Government Style */}
            <div style={{ textAlign: 'center', marginBottom: '3rem', fontFamily: 'Arial, sans-serif' }}>
              <div className="flex-wrap" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '0.75rem' }}>
                 <div style={{ width: '80px', height: '80px', flexShrink: 0, border: '1px solid #ccc', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '50%' }}>
                   <span style={{ fontSize: '0.7rem', color: '#999' }}>Logo</span>
                 </div>
                 <div style={{ flex: '1 1 200px', padding: '0 1rem' }}>
                    <h2 style={{ fontSize: '1.8rem', fontWeight: 'bold', margin: '0' }}>{formName || "FORM NO"}</h2>
                    <h3 style={{ fontSize: '1.2rem', margin: '0.5rem 0', textTransform: 'uppercase' }}>{subTitle || "Document Title"}</h3>
                    {lawText && <p style={{ fontSize: '0.9rem', fontStyle: 'italic', margin: 0 }}>{lawText}</p>}
                 </div>
                 <div style={{ width: '100px', height: '80px', flexShrink: 0, border: '1px solid #ccc', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                   <span style={{ fontSize: '0.7rem', color: '#999' }}>Emblem / QR</span>
                 </div>
              </div>
            </div>
            
            {customFields.length === 0 ? (
              <p style={{ color: '#8d8d8d', fontStyle: 'italic', textAlign: 'center', padding: '2rem' }}>
                No elements added yet. Build the form using the controls on the left.
              </p>
            ) : (
              <div style={{ fontFamily: 'Arial, sans-serif', fontSize: '1rem', lineHeight: '1.5', color: '#000' }}>
                {customFields.map((field, index) => (
                  <div key={field.id} style={{ display: 'flex', alignItems: 'flex-start', position: 'relative', width: '100%', padding: '0.5rem 0', borderBottom: '1px solid transparent', transition: 'border-color 0.2s' }}
                    onMouseEnter={(e) => e.currentTarget.style.borderBottom = '1px dashed #ccc'}
                    onMouseLeave={(e) => e.currentTarget.style.borderBottom = '1px solid transparent'}
                  >
                    
                    <div style={{ flex: 1, minWidth: 0 }}>
                      {renderFieldPreview(field)}
                    </div>
                    
                    <div style={{ display: 'flex', flexDirection: 'column', marginLeft: '1rem', flexShrink: 0, opacity: 0.7 }}>
                      <Button kind="ghost" size="sm" hasIconOnly renderIcon={UpToTop} iconDescription="Move Up" onClick={() => moveField(index, 'up')} disabled={index === 0} style={{ minHeight: '32px', width: '32px', padding: 0 }} />
                      <Button kind="ghost" size="sm" hasIconOnly renderIcon={DownToBottom} iconDescription="Move Down" onClick={() => moveField(index, 'down')} disabled={index === customFields.length - 1} style={{ minHeight: '32px', width: '32px', padding: 0 }} />
                      <Button kind="ghost" size="sm" hasIconOnly renderIcon={TrashCan} iconDescription="Remove" onClick={() => handleRemoveField(field.id)} style={{ color: '#da1e28', minHeight: '32px', width: '32px', padding: 0 }} />
                    </div>
                  </div>
                ))}
                
                <div style={{ marginTop: '4rem', display: 'flex', justifyContent: 'space-between', borderTop: '2px solid #000', paddingTop: '1rem' }}>
                  <div style={{ width: '45%' }}>
                    <p style={{ fontWeight: 'bold' }}>Presented by:</p>
                    <div style={{ height: '6rem', border: '1px solid #000', marginTop: '0.5rem' }}></div>
                  </div>
                  <div style={{ width: '45%' }}>
                    <div style={{ display: 'flex', border: '1px solid #000', marginBottom: '0.5rem' }}>
                      <div style={{ width: '30%', padding: '4px', borderRight: '1px solid #000', fontSize: '0.8rem' }}>Email:</div>
                      <div style={{ flex: 1 }}></div>
                    </div>
                    <div style={{ display: 'flex', border: '1px solid #000', marginBottom: '0.5rem' }}>
                      <div style={{ width: '30%', padding: '4px', borderRight: '1px solid #000', fontSize: '0.8rem' }}>Telephone:</div>
                      <div style={{ flex: 1 }}></div>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

      </div>
    </main>
  );
}

