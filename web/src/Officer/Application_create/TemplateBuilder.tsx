import { useState, useEffect } from "react";
import {
  TextInput,
  Select,
  SelectItem,
  Button,
  Stack,
  Checkbox,
  TextArea
} from "@carbon/react";
import { TrashCan, UpToTop, DownToBottom } from "@carbon/icons-react";

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

  useEffect(() => {
    const queryParams = new URLSearchParams(window.location.search);
    const id = queryParams.get("id");
    if (id) {
      setTemplateId(id);
      fetchTemplateData(id);
    }
  }, []);

  const fetchTemplateData = async (id: string) => {
    try {
      const response = await fetch(`http://localhost:5119/api/templates/${id}`);
      if (response.ok) {
        const data = await response.json();
        setFormName(data.formName || "");
        setSubTitle(data.subTitle || "");
        setLawText(data.lawText || "");
        if (data.fields) {
          setCustomFields(data.fields.map((f: any) => ({
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

  const handleSaveTemplate = async () => {
    try {
      setIsSaving(true);
      const token = localStorage.getItem("officerToken");
      
      const payload = {
        formName: formName,
        subTitle: subTitle,
        lawText: lawText,
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

  const renderFieldPreview = (field: FormField) => {
    switch (field.type) {
      case 'heading':
        return <h4 style={{ marginTop: '1.5rem', marginBottom: '0.5rem', fontWeight: 'bold', textTransform: 'uppercase', borderBottom: '2px solid #000', paddingBottom: '4px' }}>{field.label}</h4>;
      
      case 'paragraph':
        return <p style={{ marginBottom: '1rem', fontStyle: 'italic', fontSize: '0.9rem' }}>{field.label}</p>;
      
      case 'table':
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
      
      case 'file':
        return (
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
            <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{color: 'red'}}>*</span>} :</div>
            <div style={{ flex: 1, border: '1px dashed #666', padding: '1rem', textAlign: 'center', backgroundColor: '#fafafa', color: '#666' }}>
              [ Required Document Upload ]
            </div>
          </div>
        );

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

  return (
    <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
      <div style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Advanced Template Builder</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>Design highly customizable application forms matching official government layouts.</p>
      </div>

      <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
        
        {/* Builder Controls (Left Side) */}
        <div style={{ flex: '1', minWidth: '350px', maxWidth: '450px', backgroundColor: '#fff', padding: '2rem', border: '1px solid #e0e0e0', position: 'sticky', top: '5rem' }}>
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
        <div style={{ flex: '2', minWidth: '500px', backgroundColor: '#fff', padding: '2rem', border: '1px solid #e0e0e0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', borderBottom: '1px solid #e0e0e0', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '1.2rem', color: '#161616' }}>Live Document Preview</h3>
            <Button size="sm" kind="primary" onClick={handleSaveTemplate} disabled={isSaving}>
              {isSaving ? "Saving..." : "Save Template"}
            </Button>
          </div>
          
          <div style={{ backgroundColor: '#fff', border: '1px solid #ccc', padding: '3rem', boxShadow: '0 4px 8px rgba(0,0,0,0.1)' }}>
            
            {/* Form Header matching Government Style */}
            <div style={{ textAlign: 'center', marginBottom: '3rem', fontFamily: 'Arial, sans-serif' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                 <div style={{ width: '80px', height: '80px', border: '1px solid #ccc', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '50%' }}>
                   <span style={{ fontSize: '0.7rem', color: '#999' }}>Logo</span>
                 </div>
                 <div style={{ flex: 1, padding: '0 1rem' }}>
                    <h2 style={{ fontSize: '1.8rem', fontWeight: 'bold', margin: '0' }}>{formName || "FORM NO"}</h2>
                    <h3 style={{ fontSize: '1.2rem', margin: '0.5rem 0', textTransform: 'uppercase' }}>{subTitle || "Document Title"}</h3>
                    {lawText && <p style={{ fontSize: '0.9rem', fontStyle: 'italic', margin: 0 }}>{lawText}</p>}
                 </div>
                 <div style={{ width: '100px', height: '80px', border: '1px solid #ccc', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
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
