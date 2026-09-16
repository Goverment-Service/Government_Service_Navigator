// Shared "official document" rendering used by both the Template Builder's
// live preview and the read-only "View Details" modal on the Applications
// list, so a saved template always looks the same wherever it's viewed.

export interface PreviewField {
  id?: string;
  label: string;
  type: string;
  options?: string;
  required?: boolean;
}

export function renderFieldPreview(field: PreviewField) {
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
          <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{ color: 'red' }}>*</span>} :</div>
          <div style={{ flex: 1, border: '1px dashed #666', padding: '1rem', textAlign: 'center', backgroundColor: '#fafafa', color: '#666' }}>
            [ Required Document Upload ]
          </div>
        </div>
      );

    case 'textarea':
      return (
        <div style={{ display: 'flex', alignItems: 'flex-start', marginBottom: '1rem' }}>
          <div style={{ fontWeight: 'bold', width: '30%', marginTop: '0.5rem' }}>{field.label} {field.required && <span style={{ color: 'red' }}>*</span>} :</div>
          <div style={{ flex: 1, minHeight: '4rem', border: '1px solid #000', backgroundColor: '#fff' }} />
        </div>
      );

    case 'date':
      return (
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
          <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{ color: 'red' }}>*</span>} :</div>
          <div style={{ flex: 1, borderBottom: '1px solid #000', paddingBottom: '4px', color: '#666' }}>DD / MM / YYYY</div>
        </div>
      );

    case 'select':
    case 'multiselect':
      return (
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
          <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{ color: 'red' }}>*</span>} :</div>
          <div style={{ flex: 1, border: '1px solid #000', padding: '8px', color: '#666', backgroundColor: '#fff' }}>
            [ Select from: {field.options || 'None'} ]
          </div>
        </div>
      );

    default: // text, number
      return (
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1rem' }}>
          <div style={{ fontWeight: 'bold', width: '30%' }}>{field.label} {field.required && <span style={{ color: 'red' }}>*</span>} :</div>
          <div style={{ flex: 1, border: '1px solid #000', padding: '12px', backgroundColor: '#fff' }} />
        </div>
      );
  }
}

interface DocumentPreviewProps {
  formName?: string;
  subTitle?: string;
  lawText?: string;
  fields: PreviewField[];
}

export default function DocumentPreview({ formName, subTitle, lawText, fields }: DocumentPreviewProps) {
  return (
    <div className="p-4 sm:p-8 lg:p-12" style={{ backgroundColor: '#fff', border: '1px solid #ccc', boxShadow: '0 4px 8px rgba(0,0,0,0.1)' }}>
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

      {fields.length === 0 ? (
        <p style={{ color: '#8d8d8d', fontStyle: 'italic', textAlign: 'center', padding: '2rem' }}>
          No elements added to this form.
        </p>
      ) : (
        <div style={{ fontFamily: 'Arial, sans-serif', fontSize: '1rem', lineHeight: '1.5', color: '#000' }}>
          {fields.map((field, index) => (
            <div key={field.id ?? index} style={{ padding: '0.5rem 0' }}>
              {renderFieldPreview(field)}
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
  );
}
