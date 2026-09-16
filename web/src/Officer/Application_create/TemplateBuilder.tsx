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
import { TrashCan, UpToTop, DownToBottom } from "@carbon/icons-react";
import { getStoredUser } from "../../utils/currentUser";
import { getCategoryForDepartment } from "../../constants/departments";
import { renderFieldPreview } from "./documentPreview";
import { API_BASE } from "../../lib/apiBase";

export type FieldType = 
  | 'text' | 'textarea' | 'number' | 'select' | 'multiselect' 
  | 'date' | 'file' | 'heading' | 'paragraph' | 'table';

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
  
  const [customFields, setCustomFields] = useState<FormField[]>([]);
  
  const [newFieldLabel, setNewFieldLabel] = useState("");
  const [newFieldType, setNewFieldType] = useState<FieldType>("text");
  const [newFieldOptions, setNewFieldOptions] = useState("");
  const [newFieldRequired, setNewFieldRequired] = useState(false);
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
    fetch(`${API_BASE}/services`)
      .then((res) => res.json())
      .then((data) => {
        setServices(data.filter((srv: ServiceOption) => srv.status === "Active"));
      })
      .catch((error) => {
        console.error("Error fetching services:", error);
      });
  }, []);

  useEffect(() => {
    if (!linkedServiceId) {
      setLinkedServiceDetail(null);
      return;
    }
    setIsLoadingServiceDetail(true);
    fetch(`${API_BASE}/services/${linkedServiceId}`)
      .then((res) => res.json())
      .then((data) => setLinkedServiceDetail(data))
      .catch((error) => {
        console.error("Error fetching linked service details:", error);
        setLinkedServiceDetail(null);
      })
      .finally(() => setIsLoadingServiceDetail(false));
  }, [linkedServiceId]);

  const fetchTemplateData = async (id: string) => {
    try {
      const response = await fetch(`${API_BASE}/templates/${id}`);
      if (response.ok) {
        const data = await response.json();
        setFormName(data.formName || "");
        setSubTitle(data.subTitle || "");
        setLawText(data.lawText || "");
        setLinkedServiceId(data.serviceProcedureId ? data.serviceProcedureId.toString() : "");
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
        fields: customFields.map(f => ({
          label: f.label,
          type: f.type,
          options: f.options,
          required: f.required || false
        }))
      };

      const url = templateId 
        ? `${API_BASE}/templates/update/${templateId}` 
        : `${API_BASE}/templates/create`;
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

      alert("Template Saved Successfully!");
      window.location.href = "/officer/applications";
    } catch (error) {
      console.error(error);
      alert("Error saving template. Please check console.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleAddField = () => {
    if (!newFieldLabel) return;
    const newField: FormField = {
      id: Date.now().toString(),
      label: newFieldLabel,
      type: newFieldType,
      required: newFieldRequired,
      options: (['select', 'multiselect', 'table'].includes(newFieldType)) ? newFieldOptions : undefined
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

  // Keep the currently linked service visible even if it falls outside the
  // officer's department (e.g. editing a template someone else created),
  // so the dropdown doesn't silently blank out an existing selection.
  const visibleServices = services.filter(
    (srv) => !scopedCategory || srv.category === scopedCategory || srv.id.toString() === linkedServiceId
  );

  return (
    <main className="gsn-shell-main">
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
                  onChange={(e) => setNewFieldType(e.target.value as FieldType)}
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
                  <optgroup label="Complex">
                    <SelectItem value="table" text="Data Table Grid" />
                    <SelectItem value="file" text="Required Document Upload" />
                  </optgroup>
                </Select>

                <TextArea
                  id="fieldLabel"
                  labelText={['heading', 'paragraph'].includes(newFieldType) ? "Text Content" : "Field Label"}
                  rows={2}
                  value={newFieldLabel}
                  onChange={(e) => setNewFieldLabel(e.target.value)}
                />
                
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
                
                {!['heading', 'paragraph'].includes(newFieldType) && (
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

