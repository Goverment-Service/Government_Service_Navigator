import { useState } from "react";
import {
  TextInput,
  Select,
  SelectItem,
  Button,
  Stack,
  FormGroup
} from "@carbon/react";
import { TrashCan } from "@carbon/icons-react";

export default function TemplateBuilder() {
  const [formName, setFormName] = useState("Business Registration Form");
  
  const [customFields, setCustomFields] = useState<{id: string, label: string, type: string, options?: string}[]>([
    { id: 'f1', label: 'Proposed Business Name', type: 'text' },
    { id: 'f2', label: 'Type of Business', type: 'select', options: 'Sole Proprietorship, Partnership, Private Limited' }
  ]);
  
  const [newFieldLabel, setNewFieldLabel] = useState("");
  const [newFieldType, setNewFieldType] = useState("text");
  const [newFieldOptions, setNewFieldOptions] = useState("");

  const handleAddField = () => {
    if (!newFieldLabel) return;
    const newField = {
      id: Date.now().toString(),
      label: newFieldLabel,
      type: newFieldType,
      options: (newFieldType === 'select' || newFieldType === 'multiselect') ? newFieldOptions : undefined
    };
    setCustomFields([...customFields, newField]);
    setNewFieldLabel("");
    setNewFieldOptions("");
    setNewFieldType("text");
  };

  const handleRemoveField = (id: string) => {
    setCustomFields(customFields.filter(f => f.id !== id));
  };

  return (
    <main style={{ marginTop: '3rem', padding: '2rem', marginLeft: '16rem', backgroundColor: '#f4f4f4', minHeight: '100vh' }}>
      <div style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 400, color: '#161616' }}>Form Template Builder</h1>
        <p style={{ color: '#525252', marginTop: '0.5rem' }}>Design custom application forms for business registrations and other services.</p>
      </div>

      <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
        
        {/* Builder Controls (Left Side) */}
        <div style={{ flex: '1', minWidth: '350px', maxWidth: '450px', backgroundColor: '#fff', padding: '2rem', border: '1px solid #e0e0e0' }}>
          <h3 style={{ fontSize: '1.2rem', marginBottom: '1.5rem', borderBottom: '1px solid #e0e0e0', paddingBottom: '0.5rem' }}>Form Properties</h3>
          <Stack gap={5}>
            <FormGroup legendText="">
              <TextInput
                id="formName"
                labelText="Template Title"
                value={formName}
                onChange={(e) => setFormName(e.target.value)}
              />
            </FormGroup>

            <div style={{ marginTop: '1rem', padding: '1rem', backgroundColor: '#f4f4f4', borderLeft: '4px solid #0f62fe' }}>
              <h4 style={{ marginBottom: '1rem' }}>Add New Field</h4>
              <Stack gap={5}>
                <TextInput
                  id="fieldLabel"
                  labelText="Field Label (e.g. Applicant Name)"
                  value={newFieldLabel}
                  onChange={(e) => setNewFieldLabel(e.target.value)}
                />
                <Select
                  id="fieldType"
                  labelText="Input Type"
                  value={newFieldType}
                  onChange={(e) => setNewFieldType(e.target.value)}
                >
                  <SelectItem value="text" text="Short Text Input" />
                  <SelectItem value="textarea" text="Long Text Area" />
                  <SelectItem value="number" text="Number Input" />
                  <SelectItem value="select" text="Dropdown (Single Select)" />
                  <SelectItem value="multiselect" text="Dropdown (Multi-Select)" />
                </Select>
                
                {(newFieldType === 'select' || newFieldType === 'multiselect') && (
                  <TextInput
                    id="fieldOptions"
                    labelText="Dropdown Options (Comma separated)"
                    placeholder="e.g. Option 1, Option 2, Option 3"
                    value={newFieldOptions}
                    onChange={(e) => setNewFieldOptions(e.target.value)}
                  />
                )}
                
                <Button onClick={handleAddField} size="md" disabled={!newFieldLabel.trim()} style={{ marginTop: '0.5rem' }}>
                  Add Field to Form
                </Button>
              </Stack>
            </div>
          </Stack>
        </div>

        {/* Live Form Preview (Right Side) */}
        <div style={{ flex: '1.5', minWidth: '400px', backgroundColor: '#fff', padding: '2rem', border: '1px solid #e0e0e0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem', borderBottom: '1px solid #e0e0e0', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '1.2rem', color: '#161616' }}>Live Form Preview</h3>
            <Button size="sm" kind="primary" onClick={() => alert('Template Saved Successfully!')}>Save Template</Button>
          </div>
          
          <div style={{ backgroundColor: '#fff', border: '1px solid #ccc', padding: '3rem 2rem', boxShadow: '0 4px 8px rgba(0,0,0,0.1)' }}>
            <div style={{ textAlign: 'center', marginBottom: '3rem', fontFamily: 'serif' }}>
              <h2 style={{ fontSize: '1.4rem', textTransform: 'uppercase', marginBottom: '0.5rem', fontWeight: 600, letterSpacing: '1px' }}>Government of Sri Lanka</h2>
              <h3 style={{ fontSize: '1.2rem', textDecoration: 'underline', fontWeight: 'normal' }}>{formName || "Untitled Form"}</h3>
            </div>
            
            {customFields.length === 0 ? (
              <p style={{ color: '#8d8d8d', fontStyle: 'italic', textAlign: 'center', padding: '2rem', fontFamily: 'sans-serif' }}>
                No fields added yet. Add a field from the builder on the left to preview the official document here.
              </p>
            ) : (
              <div style={{ fontFamily: 'serif', fontSize: '1.1rem', lineHeight: '1.6' }}>
                {customFields.map((field, index) => (
                  <div key={field.id} style={{ display: 'flex', alignItems: 'flex-start', marginBottom: '2rem', position: 'relative', width: '100%' }}>
                    <div style={{ flex: 1, display: 'flex', alignItems: 'baseline', flexWrap: 'wrap', minWidth: 0 }}>
                      <span style={{ fontWeight: 'bold', marginRight: '1rem', flexShrink: 0, marginBottom: '0.5rem' }}>
                        {index + 1}. {field.label} :
                      </span>
                      
                      {field.type === 'select' || field.type === 'multiselect' ? (
                        <div style={{ flex: 1, color: '#555', fontStyle: 'italic', borderBottom: '1px dotted #999', minWidth: '200px', paddingBottom: '0.2rem' }}>
                          [ Select from: {field.options || 'None'} ]
                        </div>
                      ) : field.type === 'textarea' ? (
                        <div style={{ flex: 1, minWidth: '200px', height: '4rem', borderBottom: '1px dotted #000', borderLeft: '1px dotted #000', borderRight: '1px dotted #000', marginTop: '1.2rem' }} />
                      ) : (
                        <div style={{ flex: 1, minWidth: '200px', borderBottom: '1px dotted #000' }}>
                          &nbsp;
                        </div>
                      )}
                    </div>
                    <div style={{ marginLeft: '1rem', flexShrink: 0 }}>
                      <Button 
                        kind="ghost" 
                        size="sm" 
                        hasIconOnly 
                        renderIcon={TrashCan} 
                        iconDescription="Remove Field"
                        onClick={() => handleRemoveField(field.id)}
                        style={{ color: '#da1e28' }}
                      />
                    </div>
                  </div>
                ))}
                
                <div style={{ marginTop: '5rem', display: 'flex', justifyContent: 'space-between' }}>
                  <div style={{ textAlign: 'center' }}>
                    <p>................................................</p>
                    <p style={{ marginTop: '0.5rem' }}>Date</p>
                  </div>
                  <div style={{ textAlign: 'center' }}>
                    <p>................................................</p>
                    <p style={{ marginTop: '0.5rem' }}>Signature of Applicant</p>
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
